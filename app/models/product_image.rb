# frozen_string_literal: true

class ProductImage < ApplicationRecord
  belongs_to :product

  validates :image_url, presence: true

  scope :main, -> { where(is_main: true) }

  before_save :ensure_single_main_image

  private

  def ensure_single_main_image
    if is_main?
      product.product_images
             .where.not(id: id)
             .update_all(is_main: false)
    end
  end
end
