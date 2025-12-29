# frozen_string_literal: true

class ProductFavorite < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :user_id, uniqueness: { scope: :product_id }

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at user_id product_id id]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user product]
  end
end
