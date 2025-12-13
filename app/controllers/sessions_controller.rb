# frozen_string_literal: true

class SessionsController < ApplicationController
  skip_before_action :authenticate_request, only: %i[google login]

  def google
    auth = request.env["omniauth.auth"]

    user = User.find_or_initialize_by(email: auth.info.email)
    if user.new_record?
      user.email = auth.info.email
      user.username = generate_username(auth.info.name)
      user.password = SecureRandom.hex(15)
      user.save!
    end

    token = JwtService.encode(user_id: user.id)
    render_success(message: "Signed in with Google", data: { token: token, user: user })
  end

  def login
    email = params[:email]
    password = params[:password]

    user = User.find_by(email: email)
    if user && user.authenticate(password)
      token = JwtService.encode(user_id: user.id)
      render_success(message: "Signed in successfully", data: { token: token, user: user.as_json })
    else
      render_error(message: "Invalid email or password")
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
