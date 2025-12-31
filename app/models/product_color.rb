# frozen_string_literal: true

class ProductColor < ApplicationRecord
  has_many :product_variants
  has_many :products, through: :product_variants

  validates :name, presence: true
  validates :hex_code,
            format: { with: /\A#(?:\h{3}|\h{6})\z/ },
            allow_nil: true

  def display_name
    hex_code.present? ? "#{name} (#{hex_code})" : name
  end

  def swatch(size: 14)
    return name if hex_code.blank?

    "<span style='
      display:inline-block;
      width:#{size}px;
      height:#{size}px;
      background:#{hex_code};
      border-radius:4px;
      border:1px solid #d1d5db;
      margin-right:6px;
      vertical-align:middle;
    '></span>#{name}".html_safe
  end
end
