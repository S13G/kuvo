require "test_helper"

class ProductReviewsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    @product = products(:one)
    @review = product_reviews(:one)
    @headers = auth_headers(@user)
  end

  test "should get index" do
    get product_reviews_url, headers: @headers, as: :json
    assert_response :success
    assert_not_empty JSON.parse(response.body)["data"]
  end

  test "should create product_review" do
    assert_difference("ProductReview.count") do
      post product_reviews_url,
           params: { product_review: { comment: "Amazing!", product_id: products(:two).id, rating: 5 } },
           headers: @headers, as: :json
    end

    assert_response :created
  end

  test "should update product_review" do
    patch product_review_url(@review),
          params: { product_review: { comment: "Updated comment", rating: 4 } },
          headers: @headers, as: :json
    assert_response :success
    @review.reload
    assert_equal "Updated comment", @review.comment
    assert_equal 4, @review.rating
  end

  test "should not update another user's review" do
    @other_review = product_reviews(:two)
    patch product_review_url(@other_review),
          params: { product_review: { comment: "Hacked!" } },
          headers: @headers, as: :json
    assert_response :not_found
  end
end
