class Profile < ApplicationRecord
  belongs_to :user
  has_one_attached :avatar

  enum :gender, {
    male: "male",
    female: "female",
    prefer_not_to_say: "prefer_not_to_say"
  }, prefix: true

  validates :full_name, presence: true
  validates :phone_number, presence: true
  validates :date_of_birth, presence: true
  validates :gender, presence: true, inclusion: { in: Profile.genders.keys }

  def avatar_url
    if avatar.attached?
      Rails.application.routes.url_helpers.url_for(avatar)
    else
      "https://www.vecteezy.com/free-png/default-profile-picture"
    end
  end

  def as_json(options = nil)
    super(
      only: %i[id full_name phone_number date_of_birth gender created_at updated_at],
      methods: [:avatar_url]
    )
  end
end
