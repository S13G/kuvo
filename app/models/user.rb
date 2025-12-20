class User < ApplicationRecord
  has_secure_password

  has_one :profile, dependent: :destroy, class_name: "Profile"
  has_many :user_otps, dependent: :destroy
  has_many :blacklisted_tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true

  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :password_complexity

  def generate_otp
    rand(100000..999999)
  end

  def password_complexity
    return if password.blank?

    errors.add(:password, "must be at least 8 characters long") if password.length < 8
    errors.add(:password, "must contain at least one uppercase letter") if password.match?(/[A-Z]/) == false
    errors.add(:password, "must contain at least one lowercase letter") if password.match?(/[a-z]/) == false
    errors.add(:password, "must contain at least one digit") if password.match?(/[0-9]/) == false
    errors.add(:password, "must contain at least one special character (!@#$%^&*)") if password.match?(/[!@#$%^&*]/) == false
  end

  def as_json(options = nil)
    super(only: %i[id email username created_at updated_at])
  end
end
