class Transaction < ApplicationRecord
  belongs_to :order

  def self.ransackable_attributes(auth_object = nil)
    %w[amount complete_fl created_at currency id order_id status transaction_id updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[order]
  end
end
