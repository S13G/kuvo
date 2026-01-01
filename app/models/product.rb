# frozen_string_literal: true

class Product < ApplicationRecord
  has_many :product_categories, dependent: :destroy
  has_many :categories, through: :product_categories

  has_many :product_variants, dependent: :destroy
  has_many :product_sizes, through: :product_variants
  has_many :product_colors, through: :product_variants

  has_many :product_reviews, dependent: :destroy
  has_many :product_images, dependent: :destroy

  has_many :product_favorites, dependent: :destroy
  has_many :favorited_by_users, through: :product_favorites, source: :user

  accepts_nested_attributes_for :product_variants, allow_destroy: true
  accepts_nested_attributes_for :product_images, allow_destroy: true

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_by created_at description id is_active name price_cents updated_at]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[
      favorited_by_users
      product_categories
      categories
      product_colors
      product_favorites
      product_images
      product_reviews
      product_sizes
      product_variants
    ]
  end

  def total_stock
    @total_stock ||= product_variants.sum(:stock)
  end

  def update_activity_status!
    @total_stock = nil
    update!(is_active: total_stock.positive?)
  end

  def average_rating
    @average_rating ||= product_reviews.average(:rating)&.round(1) || 0
  end

  def total_reviews
    @total_reviews ||= product_reviews.count
  end

  def main_image
    product_images.find_by(is_main: true)&.image_file
  end

  def discounted_price_cents
    discount = Discount.active.first

    if discount
      price_cents - (price_cents * discount.percentage_off / 100)
    end

    price_cents
  end

  def formatted_price
    Money.new(price_cents, CurrencySetting.currency).format
  end

  def formatted_discounted_price
    if discounted_price_cents
      Money.new(discounted_price_cents, CurrencySetting.currency).format
    end

    formatted_price
  end

  def favorited_count
    product_favorites.count
  end

  def as_json(_options = nil)
    {
      id: id,
      name: name,
      description: description,
      main_image: main_image,
      price: formatted_price,
      discounted_price: formatted_discounted_price,
      average_rating: average_rating,
      total_product_review: total_reviews,
      total_stock: total_stock
    }
  end

  def detailed_json
    {
      id: id,
      name: name,
      description: description,
      price: formatted_price,
      discounted_price: formatted_discounted_price,
      main_image: main_image,
      average_rating: average_rating,
      total_reviews: total_reviews,
      total_stock: total_stock,
      images: product_images.where(is_main: false).map { |img| { image_file: img.image_file } },
      variants: product_variants.map(&:as_json),
      reviews: product_reviews.map(&:as_json)
    }
  end
end
