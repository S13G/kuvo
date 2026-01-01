# frozen_string_literal: true

class CartsController < ApplicationController
  def show
    cart = current_user.cart.includes(cart_items: :product) || current_user.create_cart

    render_success(
      message: "Cart retrieved successfully",
      data: cart.as_json
    )
  end

  def add_to_cart
    cart = current_user.cart || current_user.create_cart

    cart.add_item!(
      product_id: params[:product_id],
      product_variant_id: params[:product_variant_id],
      quantity: params[:quantity]
    )

    render_success(
      message: "Item added to cart",
      data: { cart_total: cart.total_cart_amount_in_cents }
    )
  rescue Cart::CartError => e
    render_error(message: e.message)
  end

  def reduce_item
    current_user.cart.reduce_item!(
      cart_item_id: params[:cart_item_id],
      quantity: params[:quantity]
    )

    render_success(
      message: "Cart updated",
      data: { cart_total: current_user.cart.total_cart_amount_in_cents }
    )
  rescue Cart::CartError => e
    render_error(message: e.message)
  end

  def remove_item
    current_user.cart.remove_item!(cart_item_id: params[:cart_item_id])
    render_success(message: "Item removed", data: { cart_total: current_user.cart.total_cart_amount_in_cents })
  rescue Cart::CartError => e
    render_error(message: e.message)
  end
end
