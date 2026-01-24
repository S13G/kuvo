require "test_helper"

class ComprehensiveEcommerceTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:one)
    UserOtp.where(user_id: @user.id).delete_all
    ProductReview.delete_all
    @user.update!(last_login_at: Time.current)
    @product = products(:one)
    @category = Category.find_or_create_by!(name: "Electronics")
    @product.categories << @category unless @product.categories.include?(@category)
    @variant = ProductVariant.find_or_create_by!(product: @product) do |pv|
      pv.stock = 10
    end
    @headers = auth_headers(@user)
  end

  test "authentication endpoints" do
    # login
    post "/auth/login", params: { login: @user.email, password: "Secret123!" }, as: :json
    assert_response :success
    token_data = json_response["data"]["token"]
    refresh_token = token_data["refresh_token"]
    access_token = token_data["access_token"]

    # Retrieve favorites (authenticated)
    get "/users/retrieve_favorite_products", headers: { "Authorization" => "Bearer #{access_token}" }, as: :json
    assert_response :success

    # refresh
    post "/auth/refresh", params: { refresh_token: refresh_token }, as: :json
    assert_response :success
    assert_not_nil json_response["data"]["access_token"]

    # request_otp
    post "/users/request_otp", params: { email: @user.email }, as: :json
    assert_response :success

    # verify_otp
    otp = UserOtp.where(user: @user).last
    post "/users/verify_otp", params: { email: @user.email, otp_code: otp.otp_code }, as: :json
    assert_response :success

    # register & verify_user
    post "/users", params: {
      email: "newuser@example.com",
      username: "newuser",
      password: "Password123!",
      password_confirmation: "Password123!"
    }, as: :json
    assert_response :created
    new_user = User.find_by(email: "newuser@example.com")
    otp = new_user.user_otps.last
    post "/users/verify_user", params: { email: new_user.email, otp_code: otp.otp_code }, as: :json
    assert_response :success
    assert json_response["data"]["token"]["access_token"]

    # create_new_password
    post "/users/create_new_password", params: {
      email: @user.email,
      password: "NewPassword123!",
      password_confirmation: "NewPassword123!"
    }, as: :json
    assert_response :success
  end

  test "profile endpoints" do
    get "/profile", headers: @headers, as: :json
    assert_response :success
    assert_not_nil json_response["data"]

    patch "/profile", params: { full_name: "Updated Name", gender: "male" }, headers: @headers, as: :json
    assert_response :success
    assert_equal "Updated Name", @user.reload.profile.full_name
  end

  test "product categories and suggestions" do
    get "/products/categories", as: :json
    assert_response :success
    assert_not_empty json_response["data"]

    # Suggestions
    Suggestion.create!(name: "test suggestion", frequency: 1)
    get "/suggestions", params: { query: "test" }, headers: @headers, as: :json
    assert_response :success
    assert_includes json_response["data"], "test suggestion"
  end

  test "product filtering detailed" do
    # Add to favorites
    post "/products/#{@product.id}/favorites/add", headers: @headers, as: :json
    assert_response :success

    # Retrieve favorites
    get "/users/retrieve_favorite_products", headers: @headers, as: :json
    assert_response :success
    assert json_response["data"].any? { |p| p["id"] == @product.id }

    # Remove from favorites
    post "/products/#{@product.id}/favorites/remove", headers: @headers, as: :json
    assert_response :success

    # rating filter
    ProductReview.create!(user: @user, product: @product, rating: 5, comment: "Great")
    get "/products/filter_type", params: { filter_type: "rating", rating: 5 }, as: :json
    assert_response :success
    assert_not_empty json_response["data"]["products"]

    # high_price
    get "/products/filter_type", params: { filter_type: "high_price" }, as: :json
    assert_response :success

    # popular
    get "/products/filter_type", params: { filter_type: "popular" }, as: :json
    assert_response :success
  end

  test "cart management detailed" do
    post "/carts/add_to_cart", params: { product_id: @product.id, product_variant_id: @variant.id, quantity: 5 }, headers: @headers, as: :json
    assert_response :success

    cart = @user.cart
    cart_item = cart.cart_items.first

    # reduce item
    post "/carts/reduce_item", params: { cart_item_id: cart_item.id, quantity: 2 }, headers: @headers, as: :json
    assert_response :success
    assert_equal 3, cart_item.reload.quantity

    # remove item
    post "/carts/remove_item", params: { cart_item_id: cart_item.id }, headers: @headers, as: :json
    assert_response :success
    assert_equal 0, cart.cart_items.count
  end

  test "shipping addresses CRUD" do
    # Create
    post "/shipping_addresses", params: { address_tag: "Home 2", address: "456 Side St" }, headers: @headers, as: :json
    assert_response :success
    address_id = json_response["data"]["id"]

    # Index
    get "/shipping_addresses", headers: @headers, as: :json
    assert_response :success
    assert json_response["data"].any? { |a| a["id"] == address_id }

    # Show
    get "/shipping_addresses/#{address_id}", headers: @headers, as: :json
    assert_response :success
    assert_equal "Home 2", json_response["data"]["address_tag"]

    # Update
    patch "/shipping_addresses/#{address_id}", params: { address: "Updated Address" }, headers: @headers, as: :json
    assert_response :success
    assert_equal "Updated Address", json_response["data"]["address"]

    # Destroy
    delete "/shipping_addresses/#{address_id}", headers: @headers, as: :json
    assert_response :success
    assert_nil ShippingAddress.find_by(id: address_id)
  end

  test "product reviews CRUD" do
    # Create
    post "/product_reviews", params: { product_id: @product.id, rating: 4, comment: "Nice" }, headers: @headers, as: :json
    assert_response :created
    review_id = json_response["data"]["id"]

    # Index
    get "/product_reviews", headers: @headers, as: :json
    assert_response :success
    assert json_response["data"].any? { |r| r["id"] == review_id }

    # Update
    patch "/product_reviews/#{review_id}", params: { rating: 5, comment: "Actually amazing" }, headers: @headers, as: :json
    assert_response :success
    assert_equal 5, json_response["data"]["rating"]
  end

  test "order listing and filters" do
    # Create an order
    addr = @user.shipping_addresses.create!(address_tag: "OrderAddr", address: "Order St")
    @user.create_cart.add_item!(product_id: @product.id, product_variant_id: @variant.id, quantity: 1)

    post "/orders", params: { shipping_address_id: addr.id }, headers: @headers, as: :json
    assert_response :success
    order_id = json_response["data"]["id"]

    # Tracking status
    get "/orders/#{order_id}/tracking_status", headers: @headers, as: :json
    assert_response :success
    assert_equal "pending", json_response["data"]["current_state"]

    # Index
    get "/orders", headers: @headers, as: :json
    assert_response :success
    assert json_response["data"].any? { |o| o["id"] == order_id }

    # Completed orders
    get "/orders/completed", headers: @headers, as: :json
    assert_response :success

    # Cancelled orders
    get "/orders/cancelled", headers: @headers, as: :json
    assert_response :success

    # Cancel the order
    post "/orders/cancel", params: { id: order_id }, headers: @headers, as: :json
    assert_response :success

    get "/orders/cancelled", headers: @headers, as: :json
    assert_response :success
    assert json_response["data"].any? { |o| o["id"] == order_id }
  end
end
