# frozen_string_literal: true

require "base64"
require "openssl"

class FlutterwaveService
  include HTTParty

  base_uri "https://developersandbox-api.flutterwave.com"

  def initialize
    @client_id = ENV["FLW_CLIENT_ID"]
    @client_secret = ENV["FLW_CLIENT_SECRET"]
    @encryption_key = ENV["FLW_ENCRYPTION_KEY"]
    @headers = {
      "Content-Type" => "application/json"
    }
  end

  def get_access_token
    token_url = "https://idp.flutterwave.com/realms/flutterwave/protocol/openid-connect/token"

    response = HTTParty.post(token_url, {
      headers: { "Content-Type" => "application/x-www-form-urlencoded" },
      body: URI.encode_www_form({
                                  client_id: @client_id,
                                  client_secret: @client_secret,
                                  grant_type: "client_credentials"
                                })
    })

    if response.success?
      token_data = JSON.parse(response.body)
      token_data["access_token"]
    else
      raise "Failed to get access token: #{response.code}"
    end
  end

  def request_headers(trace_id: nil, idempotency_key: nil)
    headers = {
      "Authorization" => "Bearer #{get_access_token}",
      "Content-Type" => "application/json"
    }
    headers["X-Trace-Id"] = trace_id if trace_id.present?
    headers["X-Idempotency-Key"] = idempotency_key if idempotency_key.present?
    headers
  end

  def charge_card(order, card_params)
    nonce = generate_nonce
    encrypted_card_data = encrypt_card_data(card_params, nonce)

    trace_id = SecureRandom.uuid
    idempotency_key = "order-#{order.id}-#{order.tracking_number}"

    currency = CurrencySetting.first&.currency

    first_name, middle_name, last_name = split_name(order.user.profile.full_name)
    phone_country_code, phone_number = split_phone(order.user.profile.phone_number)

    address_line1 = order.shipping_address&.address.to_s

    redirect_url =
      if Rails.env.development?
        "https://example.com/success"
      else
        Rails.application.routes.url_helpers.success_order_url(order, host: ENV["APP_HOST"])
      end

    payload = {
      amount: order.total_amount_with_shipping_cents / 100.0,
      currency: currency,
      reference: order.tracking_number,
      payment_method: {
        type: "card",
        card: {
          nonce: nonce,
          **encrypted_card_data
        }
      },
      redirect_url: redirect_url,
      customer: {
        address: {
          country: "US",
          city: "Gotham",
          state: "Colorado",
          postal_code: "94105",
          line1: address_line1
        },
        phone: {
          country_code: phone_country_code,
          number: phone_number
        },
        name: {
          first: first_name,
          middle: middle_name,
          last: last_name
        },
        email: order.user.email
      }
    }

    response = self.class.post("/orchestration/direct-charges", {
      headers: request_headers(trace_id: trace_id, idempotency_key: idempotency_key),
      body: payload.to_json
    })

    handle_response(response)
  end

  # Verify transaction
  def verify_transaction(transaction_id)
    response = self.class.get("/charges/#{transaction_id}", {
      headers: request_headers(trace_id: SecureRandom.uuid)
    })

    handle_response(response)
  end

  def self.verify_and_process(transaction_id, reference = nil, payload = {})
    service = new
    verification_response = nil
    error_message = nil

    5.times do |i|
      verification_response = service.verify_transaction(transaction_id)
      is_error = verification_response.is_a?(Hash) && (verification_response[:error] == true || verification_response["error"] == true)

      if is_error == false
        error_message = nil
        break
      end

      error_message = verification_response[:message] || verification_response["message"]
      Rails.logger.warn("Flutterwave verification attempt #{i + 1} failed for #{transaction_id}. Retrying...")
      sleep(2) if i < 4
    end

    if error_message
      return { error: true, message: error_message }
    end

    reference ||= verification_response["data"]["reference"] if verification_response.is_a?(Hash) && verification_response["data"].is_a?(Hash)
    order = Order.find_by(tracking_number: reference)

    if order.present?
      transaction = order.transactions.find_or_initialize_by(transaction_id: transaction_id)

      verification_data = (verification_response.is_a?(Hash) && verification_response.dig("data")) || (payload.is_a?(Hash) && payload.dig("data"))
      status = verification_data&.dig("status")
      amount = verification_data&.dig("amount")
      currency = verification_data&.dig("currency")

      complete_fl = status == "succeeded"
      transaction.update!(
        status: status,
        amount: amount,
        currency: currency,
        raw_data: verification_response,
        complete_fl: complete_fl
      )

      if order.status == Order.statuses[:pending] || order.status == Order.statuses[:paid]
        order.update!(status: :processing)
      end

      { error: false, order: order, transaction: transaction, verification_response: verification_response }
    else
      { error: true, message: "Order not found for reference: #{reference}" }
    end
  end

  private

  def generate_nonce
    SecureRandom.alphanumeric(12)
  end

  def encrypt_card_data(card_params, nonce)
    key = Base64.decode64(@encryption_key.to_s)
    if key.empty?
      Rails.logger.error("Missing FLW_ENCRYPTION_KEY")
      raise "Missing FLW_ENCRYPTION_KEY"
    end
    if key.bytesize != 32
      Rails.logger.error("Invalid FLW_ENCRYPTION_KEY length (expected 32 bytes after base64 decode)")
      raise "Invalid FLW_ENCRYPTION_KEY length (expected 32 bytes after base64 decode)"
    end

    iv = nonce.to_s
    if iv.bytesize != 12
      Rails.logger.error("Nonce must be exactly 12 characters long")
      raise "Nonce must be exactly 12 characters long"
    end

    {
      encrypted_card_number: encrypt_aes_gcm(card_params[:card_number], key, iv),
      encrypted_cvv: encrypt_aes_gcm(card_params[:cvv], key, iv),
      encrypted_expiry_month: encrypt_aes_gcm(card_params[:expiry_month], key, iv),
      encrypted_expiry_year: encrypt_aes_gcm(card_params[:expiry_year], key, iv)
    }
  rescue StandardError => e
    Rails.logger.error("Card data encryption failed: #{e.message}")
    raise e
  end

  def encrypt_aes_gcm(value, key, iv)
    cipher = OpenSSL::Cipher.new("aes-256-gcm")
    cipher.encrypt
    cipher.key = key
    cipher.iv = iv
    cipher.auth_data = ""

    plaintext = value.to_s
    ciphertext = cipher.update(plaintext) + cipher.final
    tag = cipher.auth_tag

    # WebCrypto AES-GCM returns ciphertext with tag appended; this mirrors that.
    Base64.strict_encode64(ciphertext + tag)
  end

  def split_name(full_name)
    parts = full_name.to_s.strip.split(/\s+/)
    first = parts.shift.to_s
    last = parts.pop.to_s
    middle = parts.join(" ")
    middle = "NA" if middle.strip.length < 2
    [first, middle, last]
  end

  def split_phone(phone)
    raw = phone.to_s.strip
    digits = raw.gsub(/\D/, "")

    cc = "234"
    num = digits

    if raw.start_with?("+")
      cc = digits[0, 3].to_s.presence || "234"
      num = digits[3..].to_s
    end

    num = num[-10, 10].to_s if num.length > 10
    num = num.gsub(/\D/, "")

    [cc, num]
  end

  def generate_transaction_reference(order)
    "KUVO-ORDER-#{order.id}-#{Time.current.to_i}"
  end

  def handle_response(response)
    case response.code
    when 200..299
      JSON.parse(response.body)
    else
      parsed_body = begin
                      JSON.parse(response.body)
                    rescue JSON::ParserError
                      {}
                    end
      error_message = parsed_body&.dig("message") || "Flutterwave API Error: #{response.code}"

      Rails.logger.error("Flutterwave API Error [#{response.code}]: #{error_message} | Response: #{response.body}")

      {
        error: true,
        message: error_message,
        details: parsed_body,
        status_code: response.code
      }
    end
  rescue JSON::ParserError
    Rails.logger.error("Invalid JSON response from Flutterwave: #{response.body}")
    {
      error: true,
      message: "Invalid response from Flutterwave"
    }
  rescue StandardError => e
    Rails.logger.error("Unexpected error handling Flutterwave response: #{e.message}")
    {
      error: true,
      message: "An unexpected error occurred while communicating with Flutterwave"
    }
  end
end
