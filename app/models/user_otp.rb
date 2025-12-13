class UserOtp < ApplicationRecord
  belongs_to :user

  def create_object(user, otp_code)
    self.user = user
    self.otp_code = otp_code
    self.expires_at = 10.minutes.from_now
    self.verified = false
    save
  end

  def not_expired?
    expires_at > Time.current
  end
end
