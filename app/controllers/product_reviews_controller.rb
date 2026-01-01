class ProductReviewsController < ApplicationController
  def index
    reviews = current_user.product_reviews.includes(:product)
    render_success(
      message: "Reviews retrieved successfully",
      data: reviews.as_json(include: :product)
    )
  end

  def create
    review = current_user.product_reviews.build(review_params)

    if review.save
      render_success(
        message: "Review created successfully",
        data: review.as_json(include: :product),
        status_code: 201
      )
    else
      render_error(
        message: "Failed to create review",
        errors: review.errors.full_messages
      )
    end
  end

  def update
    review = current_user.product_reviews.find_by(id: params[:id])

    if review.nil?
      return render_error(message: "Review not found", status_code: 404)
    end

    if review.update(review_params)
      render_success(
        message: "Review updated successfully",
        data: review.as_json(include: :product)
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
