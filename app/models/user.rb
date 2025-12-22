class User < ApplicationRecord
  has_secure_password

  has_one :profile, dependent: :destroy, class_name: "Profile"
  has_many :user_otps, dependent: :destroy
  has_many :blacklisted_tokens, dependent: :destroy

  validates :email, presence: true, uniqueness: true
  validates :username, presence: true, uniqueness: true

  validates :password, length: { minimum: 8 }, allow_nil: true
  validate :password_complexity

  after_create :create_profile, :send_otp_email

  def generate_secure_password(length = 12)
    chars = [
      ("A".."Z").to_a.sample,
      ("a".."z").to_a.sample,
      ("0".."9").to_a.sample,
      %w[! @ # $ % ^ & *].sample
    ]

    # Fill the rest with random characters from all types
    all_chars = [("A".."Z"), ("a".."z"), ("0".."9"), %w[! @ # $ % ^ & *]].map(&:to_a).flatten
    chars += Array.new(length - chars.size) { all_chars.sample }

    chars.shuffle.join
  end

  def as_json(options = {})
    {
      id: id,
      email: email,
      username: username,
      created_at: created_at,
      updated_at: updated_at,
      profile_exist: profile.present?
    }
  end

  def send_otp_email
    otp = generate_otp
    UserOtp.create_object(self, otp)
    SendOtpEmailJob.perform_later(id, otp)
  end

  private

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

  def create_profile
    # initialize profile so user.profile never returns nil
    build_profile.save(validate: false)
  end
end
