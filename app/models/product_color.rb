# frozen_string_literal: true

class ProductColor < ApplicationRecord
  has_many :product_variant
  has_many :products, through: :product_variant

  validates :name, presence: true
  validates :hex_code,
            format: { with: /\A#(?:\h{3}|\h{6})\z/ },
            allow_nil: true

  def display_name
    hex_code.present? ? "#{name} (#{hex_code})" : name
  end
end
