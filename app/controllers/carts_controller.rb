# frozen_string_literal: true

class CartsController < ApplicationController
  def show
    cart = current_user.cart || current_user.create_cart

    render_success(
      message: "Cart retrieved successfully",
      data: cart.as_json
    )
  end

  def add_to_cart
    product_id = params[:product_id]
    product_variant_id = params[:product_variant_id]
    quantity = params[:quantity]

    if quantity <= 0
      return render_error(message: "Invalid quantity")
    end

    cart = current_user.cart || current_user.create_cart

    cart.add_item!(
      product_id: product_id,
      product_variant_id: product_variant_id,
      quantity: quantity
    )

    render_success(
      message: "Item added to cart",
      data: { cart_total: cart.total_cart_amount }
    )
  rescue Cart::CartError => e
    render_error(message: e.message, status_code: 404)
  end

  def change_item_quantity
    current_user.cart.change_item_quantity!(
      cart_item_id: params[:cart_item_id],
      quantity: params[:quantity]
    )

    render_success(
      message: "Cart updated",
      data: { cart_total: current_user.cart.total_cart_amount }
    )
  rescue Cart::CartError => e
    render_error(message: e.message, status_code: 404)
  end

  def remove_item
    current_user.cart.remove_item!(cart_item_id: params[:cart_item_id])
    render_success(message: "Item removed", data: { cart_total: current_user.cart.total_cart_amount })
  rescue Cart::CartError => e
    render_error(message: e.message, status_code: 404)
  end
end
