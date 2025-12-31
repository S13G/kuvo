# frozen_string_literal: true

class Category < ApplicationRecord
  has_many :product_categories
  has_many :products, through: :product_categories

  validates :name, presence: true, uniqueness: { case_sensitive: false }

  def self.ransackable_attributes(auth_object = nil)
    %w[name]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[products product_categories]
  end

  def category_products
    products.includes(:product_reviews, :product_variants, :product_images).as_json
  end

  def as_json(options = nil)
    {
      id: id,
      name: name
    }
  end
end
