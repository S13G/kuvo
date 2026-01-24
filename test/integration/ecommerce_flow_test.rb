require "test_helper"

class EcommerceFlowTest < ActionDispatch::IntegrationTest
  setup do
    @category = Category.find_or_create_by!(name: "Test Category")
    @product = products(:one)
    @product.categories << @category unless @product.categories.include?(@category)
    @variant = ProductVariant.find_or_create_by!(product: @product) do |pv|
      pv.stock = 10
    end
    @shipping_fee = ShippingFee.first || ShippingFee.create!(amount_cents: 500)
  end

  test "full ecommerce flow" do
    # 1. User Registration
    post "/users", params: {
      email: "newuser@example.com",
      username: "newuser",
      password: "Password123!",
      password_confirmation: "Password123!"
    }, as: :json
    assert_response :created
    user = User.find_by(email: "newuser@example.com")
    assert_not_nil user
    assert_equal "newuser", user.username

    # 2. OTP Verification (Simulated)
    otp = user.user_otps.last
    post "/users/verify_user", params: {
      email: user.email,
      otp_code: otp.otp_code
    }, as: :json
    assert_response :success
    token_data = json_response["data"]["token"]
    access_token = token_data["access_token"]
    headers = { "Authorization" => "Bearer #{access_token}", "Accept" => "application/json", "Content-Type" => "application/json" }

    # 3. Product Browsing
    get "/products", headers: headers, as: :json
    assert_response :success
    assert_not_empty json_response["data"]["products"]

    get "/products/#{@product.id}", as: :json
    assert_response :success
    assert_equal @product.name, json_response["data"]["name"]

    # 4. Adding to Cart
    post "/carts/add_to_cart", params: {
      product_id: @product.id,
      product_variant_id: @variant.id,
      quantity: 2
    }, headers: headers, as: :json
    assert_response :success
    # Expected total = price * quantity. Price is 1000, quantity is 2.
    # If it's 3000, maybe something else is already in the cart?
    # Let's check the cart first.
    get "/carts/current", headers: headers, as: :json
    assert_response :success

    assert_equal 2000, json_response["data"]["total_cart_amount_in_cents"]

    # 5. Managing Shipping Addresses
    post "/shipping_addresses", params: {
      address_tag: "Work Office",
      address: "123 Main St",
      is_default: true
    }, headers: headers, as: :json
    assert_response :success
    address_id = json_response["data"]["id"]

    # 6. Checkout and Order Placement
    post "/orders", params: {
      shipping_address_id: address_id
    }, headers: headers, as: :json
    assert_response :success
    order_id = json_response["data"]["id"]
    assert_equal "pending", json_response["data"]["status"]

    # 7. Order Tracking
    get "/orders/#{order_id}/tracking_status", headers: headers, as: :json
    assert_response :success
    assert_equal "pending", json_response["data"]["current_state"]

    # 8. Order Cancellation
    post "/orders/cancel", params: { id: order_id }, headers: headers, as: :json
    assert_response :success

    get "/orders/#{order_id}", headers: headers, as: :json
    assert_response :success
    assert_equal "cancelled", json_response["data"]["status"]
  end

  test "product filtering and favoriting" do
    user = users(:one)
    headers = auth_headers(user)

    # Filtering
    get "/products/filter_type", params: { filter_type: "most_recent" }, as: :json
    assert_response :success

    # Favoriting
    post "/products/#{@product.id}/favorites/add", params: { product_id: @product.id }, headers: headers, as: :json
    assert_response :success

    get "/users/retrieve_favorite_products", headers: headers, as: :json
    assert_response :success
    assert json_response["data"].any? { |p| p["id"] == @product.id }

    # Unfavoriting
    post "/products/#{@product.id}/favorites/remove", params: { product_id: @product.id }, headers: headers, as: :json
    assert_response :success
  end
end
