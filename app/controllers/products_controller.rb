# frozen_string_literal: true

class ProductsController < ApplicationController
  def categories
    categories = Category.all
    render_success(data: categories.as_json)
  end

  def index
    search = params[:search]
    category_id = params[:category_id]
    per_page = (params[:per_page] || 20).to_i
    page = (params[:page] || 1).to_i

    query = Product.joins(:categories).distinct

    if search.present?
      Suggestion.record_search(search) # record the search term
      query = query.where("products.name ILIKE ?", "%#{search}%")
    end

    if category_id.present?
      query = query.where(categories: { id: category_id })
    end

    if query.empty?
      return render_success(data: [])
    end

    paginated_products = query.includes(:product_reviews, :product_variants, :product_images)
                              .page(page)
                              .per(per_page)

    render_success(
      message: "",
      data: {
        page: page,
        per_page: per_page,
        total_pages: paginated_products.total_pages,
        total_count: paginated_products.total_count,
        products: paginated_products.as_json
      }
    )
  end

  def filter_type
    filter_type = params[:filter_type]
    rating = params[:rating].to_i
    per_page = (params[:per_page] || 20).to_i
    page = (params[:page] || 1).to_i

    products =
      case filter_type
      when "popular"
        Product
          .left_joins(:product_reviews)
          .select("products.*, COALESCE(AVG(product_reviews.rating), 0) AS avg_rating")
          .group("products.id")
          .order("avg_rating DESC")

      when "most_recent"
        Product.order(created_at: :desc)

      when "high_price"
        Product.order(price_cents: :desc)

      when "rating"
        Product
          .joins(:product_reviews)
          .where(product_reviews: { rating: rating })
          .select("products.*, AVG(product_reviews.rating) AS avg_rating")
          .group("products.id")
          .order("avg_rating DESC")

      else
        return render_error(message: "Invalid filter type")
      end

    paginated_products = products.page(page).per(per_page)

    render_success(
      data: {
        page: page,
        per_page: per_page,
        total_pages: paginated_products.total_pages,
        total_count: paginated_products.total_count,
        products: paginated_products.as_json
      }
    )
  end

  def show
    product = Product.find_by(id: params[:id])

    if product.nil?
      return render_error(message: "Product not found")
    end

    render_success(
      message: "Product retrieved successfully",
      data: product.detailed_json
    )
  end

  def add_product_to_favorites
    product = Product.find(params[:product_id])
    current_user.add_to_favorites!(product)

    render_success(message: "Product added to favorites")

  rescue ActiveRecord::RecordNotFound => e
    render_error(message: e.message)

  rescue ActiveRecord::RecordInvalid => e
    render_error(message: e.message)
  end

  def remove_product_from_favorites
    current_user.remove_from_favorites!(product_id: params[:id])

    render_success(message: "Product removed from favorites")

  rescue ActiveRecord::RecordNotFound => e
    render_error(message: e.message)
  end
end
