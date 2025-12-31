# frozen_string_literal: true

class ProductCategory < ApplicationRecord
  belongs_to :product
  belongs_to :category

  def self.ransackable_attributes(auth_object = nil)
    %w[category_id created_at id product_id updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[product category]
  end

  def to_s
    [product&.name, category&.name].compact.join(" / ")
  end
end
