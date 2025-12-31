# frozen_string_literal: true

class ProcessAvatarJob < ApplicationJob
  queue_as :default

  retry_on StandardError, wait: 5.seconds, attempts: 3

  discard_on ActiveRecord::RecordNotFound

  def perform(profile_id)
    profile = Profile.find_by(id: profile_id)
    return if profile.nil?

    if profile.avatar.attached? == false
      return
    end

    profile.avatar.variant(
      resize_to_limit: [500, 500],
      quality: 85,
      strip: true,
      interlace: "Plane",
    ).processed
  end
end
