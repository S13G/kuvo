class UserOtp < ApplicationRecord
  belongs_to :user, dependent: :destroy

  def self.ransackable_attributes(auth_object = nil)
    %w[user_id otp_code expires_at verified id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user]
  end

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
