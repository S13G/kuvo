class JwtService
  SECRET_KEY = ENV["JWT_SECRET_KEY_BASE"]
  ACCESS_TOKEN_EXPIRY = 24.hours
  REFRESH_TOKEN_EXPIRY = 7.days

  def self.generate_tokens(user_id)
    access_token = generate_access_token(user_id)
    refresh_token = generate_refresh_token(user_id)
    [access_token, refresh_token]
  end

  def self.generate_access_token(user_id)
    payload = {
      user_id: user_id,
      iat: Time.current.to_i,
      exp: ACCESS_TOKEN_EXPIRY.from_now.to_i,
      type: "access"
    }
    JWT.encode(payload, SECRET_KEY)
  end

  def self.generate_refresh_token(user_id)
    payload = {
      user_id: user_id,
      iat: Time.current.to_i,
      exp: REFRESH_TOKEN_EXPIRY.from_now.to_i,
      jti: SecureRandom.uuid,
      type: "refresh"
    }
    JWT.encode(payload, SECRET_KEY)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, algorithm: "HS256")[0]
    payload = HashWithIndifferentAccess.new(decoded)

    if payload[:jti] && BlacklistedToken.blacklisted?(jti: payload[:jti])
      Rails.logger.warn "Attempted to use blacklisted token: #{payload[:jti]}"
      return nil
    end

    payload
  rescue JWT::ExpiredSignature, JWT::DecodeError => e
    Rails.logger.error "JWT Error: #{e.message}"
    nil
  end

  def self.valid_token_for_user?(token, user)
    payload = decode(token)
    return false if payload.nil?

    # Check iat
    issued_at = payload[:iat]
    last_login = user.last_login_at.to_i
    password_changed = user.password_changed_at&.to_i || 0
    return false if issued_at < [last_login, password_changed].max

    # Check token type
    return false if payload[:type] != "access"

    true
  end
end
