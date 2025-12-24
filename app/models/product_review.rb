# frozen_string_literal: true

class ProductReview < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :rating, inclusion: { in: 1..5 }

  after_commit :touch_product

  private

  # When a ProductReview is created or updated, update the `updated_at`
  # timestamp of the associated Product. This ensures that the Product's
  # timestamp is updated when a review is added or modified, which can
  # affect the Product's ordering and sorting.
  def touch_product
    product.touch
  end
end
