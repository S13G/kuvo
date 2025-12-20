# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authenticate_request, only: %i[google login refresh]

  def google
    auth = request.env["omniauth.auth"]

    user = User.find_or_initialize_by(email: auth.info.email)
    if user.new_record?
      user.email = auth.info.email
      user.username = generate_username(auth.info.name)
      user.password = SecureRandom.hex(15)
      user.provider = auth.provider
      user.uid = auth.uid
      user.save!
    end

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
      puts "useis #{user}"
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

  def generate_username(name)
    base = name.parameterize
    username = base
    count = 1

    while User.exists?(username: username)
      username = "#{base}_#{count}"
      count += 1
    end

    username
  end
end
