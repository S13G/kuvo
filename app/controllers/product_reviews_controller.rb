class ProductReviewsController < ApplicationController
  def index
    per_page = (params[:per_page] || 20).to_i
    page = (params[:page] || 1).to_i

    reviews = current_user
                .product_reviews
                .not_blocked
                .eager_load(:product)
                .where(products: { is_active: true })

    paginated_reviews = reviews.page(page).per(per_page)

    render_success(
      message: "Reviews retrieved successfully",
      data: {
        page: page,
        per_page: per_page,
        total_pages: paginated_reviews.total_pages,
        total_count: paginated_reviews.total_count,
        paginated_reviews: paginated_reviews.map(&:as_index_json)
      }
    )
  end

  def create
    review = current_user.product_reviews.build(review_params)

    if review.save
      render_success(
        message: "Review created successfully",
        data: review.as_index_json,
        status_code: 201
      )
    else
      render_error(
        message: "Failed to create review",
        errors: review.errors.full_messages
      )
    end

  rescue ActiveRecord::RecordNotUnique => e
    render_error(
      message: "You already made a review for this product",
      status_code: 409
    )
  end

  def update
    review = current_user.product_reviews.find_by(id: params[:id])

    if review.nil?
      return render_error(message: "Review not found", status_code: 404)
    end

    if review.update(params.permit(:rating, :comment))
      render_success(
        message: "Review updated successfully",
        data: review.as_index_json
      )
    else
      render_error(
        message: "Failed to update review",
        errors: review.errors.full_messages
      )
    end
  end

  private

  def review_params
    params.permit(:product_id, :rating, :comment)
  end
end
