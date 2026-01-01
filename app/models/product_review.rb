# frozen_string_literal: true

class ProductReview < ApplicationRecord
  belongs_to :user
  belongs_to :product

  validates :rating, inclusion: { in: 1..5 }

  after_commit :touch_product

  def self.all_reviews(product_id)
    where(product_id: product_id)
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[created_at updated_at user_id product_id rating id comment]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user product]
  end

  def to_s
    "#{user.profile.full_name} - #{product.name}"
  end

  def as_json(options = {})
    {
      id: id,
      user: {
        id: user.id,
        email: user.email,
        username: user.username,
        full_name: user.profile.full_name,
        profile_picture: user.profile.avatar_url
      },
      product: product.as_json,
      product_variant: product.product_variants.map(&:as_json),
      rating: rating,
      comment: comment,
      created_at: created_at,
      updated_at: updated_at
    }
  end

  private

  def touch_product
    product.touch # Updates product updated_at timestamp fields when a review is made
  end
end
