# verify_reviews.rb
begin
  # Setup: Create User, Product, Variant, Shipping Address, and Order
  user = User.create!(
    email: "reviewer@example.com",
    username: "reviewer",
    password: "Password123!",
    password_confirmation: "Password123!"
  )

  category = Category.create!(name: "Electronics")
  product = Product.create!(name: "Laptop", description: "Powerful laptop", price_cents: 100000)
  product.categories << category

  variant = product.product_variants.create!(stock: 10)

  shipping_address = user.shipping_addresses.create!(
    address_tag: "Home",
    address: "123 Main St",
    is_default: true
  )

  order = user.orders.create!(
    shipping_address: shipping_address,
    total_amount_cents: 100000,
    status: :delivered
  )

  order.order_items.create!(
    product: product,
    product_variant: variant,
    quantity: 1,
    unit_price_cents: 100000
  )

  puts "Setup complete."

  # 1. Test successful review creation
  review_params = {
    product_id: product.id,
    product_variant_id: variant.id,
    rating: 5,
    comment: "Excellent laptop!"
  }

  # Simulate controller logic
  order_item = order.order_items.find_by(
    product_id: review_params[:product_id],
    product_variant_id: review_params[:product_variant_id]
  )

  if order_item
    review = user.product_reviews.create!(
      product_id: review_params[:product_id],
      product_variant_id: review_params[:product_variant_id],
      rating: review_params[:rating],
      comment: review_params[:comment],
      order: order,
      quantity: order_item.quantity
    )
    puts "Review created successfully: #{review.as_json}"
  else
    puts "Failed: Order item not found"
  end

  # 2. Test failure for product not ordered
  other_product = Product.create!(name: "Phone", description: "Smart phone", price_cents: 50000)
  other_variant = other_product.product_variants.create!(stock: 5)

  order_item_fail = order.order_items.find_by(
    product_id: other_product.id,
    product_variant_id: other_variant.id
  )

  if order_item_fail.nil?
    puts "Check passed: Cannot review product not in order."
  else
    puts "Check failed: Found order item for product not in order."
  end

  # 3. Test editing review
  review.update!(comment: "Updated: Still excellent!")
  puts "Review updated: #{review.as_json[:comment]}"

  # 4. Test index
  user_reviews = user.product_reviews.as_json
  puts "User reviews index: #{user_reviews}"

  if user_reviews.any? { |r| r[:product_name] == "Laptop" && r[:quantity] == 1 }
    puts "Success: Index includes correct data."
  else
    puts "Failure: Index missing data."
  end

ensure
  # Cleanup
  user&.destroy
  product&.destroy
  other_product&.destroy
  category&.destroy
end
