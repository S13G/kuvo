# frozen_string_literal: true

class ProfilesController < ApplicationController
  def update
    user_profile = @current_user.profile

    if params[:avatar].present?
      user_profile.avatar.attach(params[:avatar])
    end

    if user_profile.update(profile_params)
      render_success(
        message: "Profile updated successfully",
        data: user_profile.as_json
      )
    else
      render_error(
        message: "Error updating profile information",
        errors: user_profile.errors.full_messages
      )
    end
  rescue StandardError => e
    Rails.logger.error "Error updating profile: #{e.message}"
    render_error(message: "Error updating profile information", errors: [e.message])
  end

  private

  def profile_params
    params.permit(:full_name, :phone_number, :date_of_birth, :gender)
  end
end
