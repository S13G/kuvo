# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authenticate_request, only: %i[google login refresh]

  def google
    id_token = params[:id_token]
    return render_error(message: "Missing id_token", status_code: 400) if id_token.blank?

    payload = verify_google_id_token(id_token)
    return render_error(message: "Invalid Google token", status_code: 401) if payload.nil?
    puts "payload #{payload}"

    email = payload["email"]
    name = payload["name"]
    sub = payload["sub"] # Google user ID (stable)

    user = User.find_or_initialize_by(email: email)

    if user.new_record?
      username_source = name || email
      user.username = generate_username(username_source)
      user.password = user.generate_secure_password
      user.provider = "google"
      user.uid = sub
    end

    user.last_login_at = Time.current
    user.save!

    access_token, refresh_token = JwtService.generate_tokens(user.id)

    render_success(
      message: "Signed in with Google",
      data: {
        token: {
          access_token: access_token,
          refresh_token: refresh_token
        },
        user: user.as_json
      }
    )
  end

  def login
    email_or_username = params[:login]
    password = params[:password]

    user = User.find_by(email: email_or_username) || User.find_by(username: email_or_username)
    if user.nil?
      return render_error(message: "Invalid email or username", status_code: 404)
    end

    if user && user.authenticate(password)
      user.update!(last_login_at: Time.current)

      access_token, refresh_token = JwtService.generate_tokens(user_id: user.id)
      render_success(
        message: "Signed in successfully",
        data: {
          token: {
            access_token: access_token,
            refresh_token: refresh_token
          },
          user: user.as_json
        }
      )
    else
      render_error(message: "Invalid password")
    end
  end

  def refresh
    refresh_token = params[:refresh_token]
    if refresh_token.blank?
      return render_error(message: "Missing refresh token", status_code: 401)
    end

    begin
      decoded_payload = JwtService.decode(refresh_token)
      if decoded_payload.nil?
        return render_error(message: "Invalid or expired refresh token", status_code: 401)
      end

      if decoded_payload[:type] != "refresh"
        return render_error(message: "Not a refresh token", status_code: 401)
      end

      user_id = nil
      if decoded_payload[:user_id].is_a?(Hash)
        user_id = decoded_payload[:user_id][:user_id]
      else
        user_id = decoded_payload[:user_id]
      end

      user = User.find_by(id: user_id)
      if user.nil?
        return render_error(message: "User not found", status_code: 401)
      end

      # Blacklist the used refresh token
      BlacklistedToken.blacklist!(
        jti: decoded_payload[:jti],
        exp: decoded_payload[:exp],
        user: user
      )

      access_token = JwtService.generate_access_token(user.id)
      new_refresh_token = JwtService.generate_refresh_token(user.id)

      render_success(
        message: "Token refreshed successfully",
        data: {
          access_token: access_token,
          refresh_token: new_refresh_token
        }
      )
    rescue JWT::DecodeError => e
      render_error(message: "Invalid refresh token", status_code: 401)
    end
  end

  private

  def verify_google_id_token(id_token)
    key_source = Google::Auth::IDTokens::JwkHttpKeySource.new(
      "https://www.googleapis.com/oauth2/v3/certs"
    )

    validator = Google::Auth::IDTokens::Verifier.new(
      key_source: key_source
    )

    validator.verify(
      id_token,
      aud: ENV["GOOGLE_CLIENT_ID"],
      iss: ["https://accounts.google.com", "accounts.google.com"]
    )
  rescue Google::Auth::IDTokens::VerificationError => e
    Rails.logger.error("Google ID token verification failed: #{e.message}")
    nil
  end

  def generate_username(name_or_email)
    base = (name_or_email || "user").parameterize
    username = base
    count = 1

    while User.exists?(username: username)
      username = "#{base}_#{count}"
      count += 1
    end

    username
  end
end
