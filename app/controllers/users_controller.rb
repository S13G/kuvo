class UsersController < ApplicationController
  skip_before_action :authenticate_request, only: %i[create request_otp verify_user verify_otp create_new_password]

  def create
    user = User.new(user_params)

    if user.save
      render_success(
        message: "Account registered successfully. Please check your email for OTP.",
        data: { user: user.as_json },
        status_code: 201
      )
    elsif User.exists?(username: user_params[:username])
      render_error(
        message: "Account with this username already exists",
        status_code: 409
      )
    elsif User.exists?(email: user_params[:email])
      render_error(
        message: "Account with this email already exists",
        status_code: 409
      )
    else
      render_error(
        message: "Failed to create account",
        errors: user.errors.full_messages,
      )
    end
  end

  def request_otp
    user = find_user(params[:email])
    if user.nil?
      return render_error(message: "User not found", status_code: 404)
    end

    user.send_otp_email
    render_success(message: "OTP sent successfully")
  end

  def verify_user
    email = params[:email]
    otp_code = params[:otp_code].to_s
    user = User.find_by(email: email)
    if user.nil?
      return render_error(message: "User not found", status_code: 404)
    end

    if user.is_verified
      return render_success(message: "User already verified")
    end

    otp = user.user_otps.where(verified: false).last

    if otp && otp.otp_code == otp_code && otp.not_expired?
      otp.update(verified: true)
      user.update(is_verified: true, last_login_at: Time.current)

      # Give tokens to log user in
      access_token, refresh_token = JwtService.generate_tokens(user.id)
      render_success(
        message: "User verified successfully",
        data: {
          user: user.as_json,
          token: {
            access_token: access_token,
            refresh_token: refresh_token
          }
        }
      )
    else
      render_error(message: "Invalid or expired OTP")
    end
  end

  def verify_otp
    email = params[:email]
    otp_code = params[:otp_code].to_s
    user = User.find_by(email: email)
    if user.nil?
      return render_error(message: "User not found", status_code: 404)
    end

    otp = user.user_otps.where(verified: false).last

    if otp && otp.otp_code == otp_code && otp.not_expired?
      otp.update(verified: true)
      render_success(message: "Verified successfully")
    else
      render_error(message: "Invalid or expired OTP")
    end
  end

  def create_new_password
    user = find_user(params[:email])
    new_password = params[:password]
    new_password_confirmation = params[:password_confirmation]

    if new_password != new_password_confirmation
      return render_error(message: "Passwords do not match")
    end

    if user.nil?
      return render_error(message: "User not found", status_code: 404)
    end

    if user.update(password: params[:password], password_confirmation: params[:password_confirmation], password_changed_at: Time.current)
      render_success(message: "Password updated successfully")
    else
      render_error(message: "Unable to update password", errors: user.errors.full_messages, status_code: 404)
    end
  end

  def retrieve_favorite_products
    per_page = (params[:per_page] || 20).to_i
    page = (params[:page] || 1).to_i

    paginated_list = current_user.favorited_products.page(page).per(per_page)
    render_success(
      message: "Favorite products retrieved successfully",
      data: {
        page: page,
        per_page: per_page,
        total_pages: paginated_list.total_pages,
        total_count: paginated_list.total_count,
        paginated_list: paginated_list
      }
    )
  end

  private

  def find_user(email)
    User.find_by(email: email)
  end

  def user_params
    params.permit(:email, :username, :password, :password_confirmation)
  end
end
