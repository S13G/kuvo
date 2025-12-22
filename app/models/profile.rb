class Profile < ApplicationRecord
  belongs_to :user
  has_one_attached :avatar

  enum :gender, {
    male: "male",
    female: "female",
    prefer_not_to_say: "prefer_not_to_say"
  }

  validates :full_name, presence: true
  validates :phone_number, presence: true

  validates :gender, inclusion: { in: Profile.genders.keys }, allow_blank: true
  validates :avatar, content_type: %w[image/png image/jpeg image/webp],
            size: { less_than: 5.megabytes, message: "should be less than 5MB" }

  after_commit :process_avatar

  def avatar_url
    if avatar.attached? == false
      "https://www.vecteezy.com/free-png/default-profile-picture"
    end

    # This will use the processed variant if available, or queue processing if not
    optimized_image = avatar.variant(
      resize_to_limit: [500, 500],
      quality: 85,
      strip: true,
      interlace: "Plane",
    )
    Rails.application.routes.url_helpers.rails_representation_url(
      optimized_image,
      host: Rails.application.config.action_controller.asset_host || "localhost:3000"
    )
  rescue => e
    Rails.logger.error "Error generating avatar URL: #{e.message}"
    "https://www.vecteezy.com/free-png/default-profile-picture"
  end

  def as_json(options = {})
    {
      id: id,
      full_name: full_name,
      email: user.email,
      phone_number: phone_number,
      date_of_birth: date_of_birth,
      gender: gender,
      avatar_url: avatar_url,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  private

  def process_avatar
    if avatar.attached? == false
      return
    end

    ProcessAvatarJob.perform_later(id)
  end
end
