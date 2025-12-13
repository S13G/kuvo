class Profile < ApplicationRecord
  belongs_to :user

  enum :gender, {
    male: "male",
    female: "female",
    prefer_not_to_say: "prefer_not_to_say"
  }, prefix: true

  validates :full_name, presence: true
  validates :phone_number, presence: true
  validates :date_of_birth, presence: true
  validates :gender, presence: true, inclusion: { in: gender.keys }, allow_nil: true
end
