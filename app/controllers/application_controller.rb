class ApplicationController < ActionController::Base
  skip_forgery_protection
  before_action :authenticate_request, if: :jwt_auth_required?

  helper_method :current_user

  def render_success(message: "", data: nil, status_code: 200)
    render json: {
      status: "success",
      message: message,
      data: data,
      status_code: status_code
    }, status: status_code
  end

  def render_error(message: "", errors: [], status_code: 400)
    render json: {
      status: "error",
      message: message,
      errors: errors,
      status_code: status_code
    }, status: status_code
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    render_error(message: "Record not found", errors: [ e.message ], status_code: 404)
  end

  rescue_from StandardError do |e|
    render_error(message: "Something went wrong", errors: [ e.message ], status_code: 500)
  end

  rescue_from ActiveModel::UnknownAttributeError do |e|
    render_error(message: "Unknown attribute", errors: [ e.message ], status_code: 400)
  end

  rescue_from ActiveRecord::RecordNotUnique do |e|
    render_error(message: "Record already exists", errors: [ e.message ], status_code: 400)
  end

  protected

  def current_user
    @current_user
  end

  def jwt_auth_required?
    Rails.logger.info "jwt_auth_required? called - controller: #{controller_name}, action: #{action_name}, path: #{request.path}, format: #{request.format}, params: #{params.inspect}"

    if devise_controller?
      return false
    end

    if request.path.start_with?("/admin")
      return false
    end

    true
  end

  def authenticate_request
    header = request.headers["Authorization"]
    if header.blank?
      return render_error(message: "Missing authorization token", status_code: 401)
    end

    token = header.split(" ").last
    if token.blank?
      return render_error(message: "Invalid token format", status_code: 401)
    end

    decoded = JwtService.decode(token)
    if decoded.nil?
      return render_error(message: "Invalid or expired token", status_code: 401)
    end

    @current_user = User.find_by(id: decoded[:user_id])
    if @current_user.nil?
      return render_error(message: "User not found", status_code: 401)
    end

    if JwtService.valid_token_for_user?(token, @current_user) == false
      return render_error(message: "Token is invalid or expired", status_code: 401)
    end

    @current_user
  rescue JWT::DecodeError => e
    Rails.logger.error "JWT Decode Error: #{e.message}"
    render_error(message: "Invalid token", status_code: 401)
  end
end
