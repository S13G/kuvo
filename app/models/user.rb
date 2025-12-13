class User < ApplicationRecord
  has_secure_password

  has_one :profile, dependent: :destroy, class_name: "Profile"
  has_many :user_otps, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true

  def generate_otp
    rand(100000..999999)
  end

  def password_validation
    errors.add(:password, "Password must be at least 8 characters long") if password.length < 8
    errors.add(:password, "Password must contain at least one uppercase letter") if password !~ /[A-Z]/
    errors.add(:password, "Password must contain at least one lowercase letter") if password !~ /[a-z]/
    errors.add(:password, "Password must contain at least one digit") if password !~ /[0-9]/
    errors.add(:password, "Password must contain at least one special character") if password !~ /[!@#$%^&*]/
  end

  def as_json(options = nil)
    super(only: %i[id email username created_at updated_at])
  end
end
