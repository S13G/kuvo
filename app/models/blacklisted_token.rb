# frozen_string_literal: true

class BlacklistedToken < ApplicationRecord
  belongs_to :user

  def self.blacklist!(jti:, exp:, user:)
    create!(jti: jti, expires_at: Time.at(exp), user: user)
  end

  def self.blacklisted?(jti:)
    exists?(jti: jti)
  end
end

