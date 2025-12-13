class ApplicationController < ActionController::API
  before_action :authenticate_request

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

  private

  def authenticate_request
    header = request.headers["Authorization"]
    token = header.split(" ")&.last

    begin
      decoded = JwtService.decode(token)
    rescue JWT::DecodeError
      render_error(message: "Invalid token", status_code: 401)
    end

    @current_user = User.find_by(id: decoded[:user_id])
    if @current_user.nil?
      render_error(message: "User not found", status_code: 401)
    end

    @current_user
  end
end
