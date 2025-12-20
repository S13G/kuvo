class UserOtp < ApplicationRecord
  belongs_to :user

  def self.create_object(user, otp_code)
    create(
      user: user,
      otp_code: otp_code,
      expires_at: 10.minutes.from_now,
      verified: false
    )
  end

  def not_expired?
    expires_at > Time.current
  end
end
