# frozen_string_literal: true

class FlutterwaveWebhooksController < ApplicationController
  skip_before_action :authenticate_request

  def receive
    secret_hash = ENV["FLW_SECRET_HASH"]&.gsub("\"", "")
    signature = request.headers["HTTP_FLUTTERWAVE_SIGNATURE"]

    if signature.blank? || (secret_hash.present? && signature != secret_hash)
      Rails.logger.warn("Flutterwave webhook signature issue. Expected: #{secret_hash}, Got: #{signature}")
      Rails.logger.info("Incoming Webhook Relevant Headers: #{request.headers.to_h.select { |k, _| k.downcase.include?('verif') || k.downcase.include?('signature') || k.start_with?('HTTP_') }.inspect}")
    end

    if secret_hash.present? && signature != secret_hash
      return render_success(status_code: 200)
    end

    payload = request.request_parameters.presence || JSON.parse(request.raw_post.presence || "{}")
    Rails.logger.info("Flutterwave webhook received: #{payload.inspect}")

    transaction_id = payload.dig("data", "id") || payload["id"]
    reference = payload.dig("data", "reference") || payload["reference"]

    if transaction_id.present?
      verify_and_process_transaction(transaction_id, reference, payload)
    elsif reference.present?
      process_by_reference(reference)
    end

    render_success(status_code: 200)
  rescue JSON::ParserError => e
    Rails.logger.info("Flutterwave webhook invalid JSON: #{e.message}")
    render_success(status_code: 200)
  rescue StandardError => e
    Rails.logger.error("Flutterwave webhook error: #{e.message}\n#{e.backtrace&.join("\n")}")
    render_success(status_code: 200)
  end

  private

  def verify_and_process_transaction(transaction_id, reference, payload)
    verification_response = FlutterwaveService.verify_and_process(transaction_id, reference, payload)

    if verification_response[:error]
      Rails.logger.error("Flutterwave verification failed for #{transaction_id}: #{verification_response[:message]}")
    end
  end

  def process_by_reference(reference)
    order = Order.find_by(tracking_number: reference)
    if order.present? && order.status == Order.statuses[:pending]
      order.update!(status: Order.statuses[:processing])
    end
  end
end
