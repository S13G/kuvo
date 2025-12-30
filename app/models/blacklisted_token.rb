# frozen_string_literal: true

class BlacklistedToken < ApplicationRecord
  belongs_to :user

  def self.ransackable_attributes(auth_object = nil)
    %w[jti expires_at user_id id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user]
  end

  def self.blacklist!(jti:, exp:, user:)
    create!(jti: jti, expires_at: Time.at(exp), user: user)
  end

  def self.blacklisted?(jti:)
    exists?(jti: jti)
  end
end

