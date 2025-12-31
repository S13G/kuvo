class AdminUser < ApplicationRecord
  devise :database_authenticatable,
         :recoverable, :rememberable, :validatable

  def superadmin?
    superadmin
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at email id updated_at superadmin reset_password_token]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
