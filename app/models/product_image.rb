# frozen_string_literal: true

class ProductImage < ApplicationRecord
  belongs_to :product

  has_one_attached :image_file

  validates :image_file, presence: true

  before_save :ensure_single_main_image

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at id is_main product_id updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[product]
  end

  def to_s
    product.name if image_file.attached?
  end

  private

  def ensure_single_main_image
    if is_main?
      product.product_images
             .where.not(id: id)
             .update_all(is_main: false)
    end
  end
end
