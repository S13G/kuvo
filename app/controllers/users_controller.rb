class UsersController < ApplicationController
  def create
    user = create_user
    send_otp_email(user)

    render_success(message: "Account registered successfully,", data: { user: user.as_json }, status_code: 201)
  end

  def request_otp
    send_otp_email(find_user(params[:email]))
    render_success(message: "OTP sent successfully")
  end

  def verify_user
    user = User.find(email: params[:email])
    otp_code = params[:otp_code]
    otp = user.user_otps.last

    if otp && otp.otp_code == otp_code && otp.not_expired?
      otp.update(verified: true)
      user.update(is_verified: true)

      # Give tokens to log user in
      tokens = JwtService.encode(user_id: user.id)
      render_success(message: "User verified successfully", data: { user: user.as_json, tokens: tokens })
    else
      render_error(message: "Invalid or expired OTP")
    end
  end

  def verify_otp
    user = User.find(email: params[:email])
    otp_code = params[:otp_code]
    otp = user.user_otps.last

    if otp && otp.otp_code == otp_code && otp.not_expired?
      otp.update(verified: true)
      render_success(message: "Verified successfully")
    else
      render_error(message: "Invalid or expired OTP")
    end
  end

  def create_new_password
    user = find_user(email)

    if user
      user.password_validation
      user.update(password: params[:password], password_confirmation: params[:password_confirmation])
      render_success(message: "Password updated successfully")
    else
      render_error(message: "User not found", status_code: 404)
    end
  end

  private

  def create_user
    user = User.new(user_params)
    user.password_validation
    user.save
    user
  end

  def send_otp_email(user)
    otp = user.generate_otp
    UserOtp.create_object(user, otp)
    SendOtpEmailJob.perform_later(user.id, otp)
  end

  def find_user(email)
    User.find_by(email: email)
  end

  def user_params
    params.permit(:email, :username, :password, :password_confirmation)
  end
end
