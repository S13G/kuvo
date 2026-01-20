# frozen_string_literal: true

class OrdersController < ApplicationController
  def index
    orders = current_user
               .orders
               .active_orders
               .recent
               .with_items_and_products

    render_success(
      message: "Orders retrieved successfully",
      data: orders.as_json
    )
  end

  def cancelled_orders
    orders = current_user
               .orders
               .cancelled_orders
               .recent
               .with_items_and_products

    render_success(
      message: "Cancelled orders retrieved successfully",
      data: orders.as_json
    )
  end

  def completed_orders
    orders = current_user
               .orders
               .completed_orders
               .recent
               .with_items_and_products

    render_success(
      message: "Completed orders retrieved successfully",
      data: orders.as_json
    )
  end

  def show
    order = find_order(params[:id])
    if order.nil?
      return render_error(message: "Order not found")
    end

    render_success(
      message: "Order retrieved successfully",
      data: order.as_json
    )
  end

  def create
    cart = current_user.cart
    if cart.nil? || cart.cart_items.empty?
      return render_error(message: "Cart is empty")
    end

    shipping_address = current_user.shipping_addresses.find_by(id: params[:shipping_address_id])
    if shipping_address.nil?
      return render_error(message: "Shipping address not found")
    end

    order = nil
    ActiveRecord::Base.transaction do
      shipping_fee = ShippingFee.instance.amount_cents
      order = current_user.orders.create!(
        shipping_address: shipping_address,
        shipping_fee_cents: shipping_fee,
        total_amount_cents: cart.total_cart_amount_in_cents,
        status: Order.statuses[:pending]
      )

      cart.cart_items.each do |cart_item|
        variant = cart_item.product_variant
        variant.with_lock do
          if variant.stock < cart_item.quantity
            render_error(message: "Insufficient stock for #{variant.product.name}")
            raise ActiveRecord::Rollback
          end

          order.order_items.create!(
            product: cart_item.product,
            product_variant: variant,
            quantity: cart_item.quantity,
            unit_price_cents: cart_item.item_unit_price_cents
          )

          # Update stock
          variant.update_stock(cart_item.quantity)
        end
      end

      # Clear the cart
      cart.cart_items.destroy_all
    end

    render_success(
      message: "Order created successfully",
      data: order.as_json(include: :order_items)
    )
  rescue ActiveRecord::RecordInvalid => e
    render_error(message: "Error creating order", errors: e.record.errors.full_messages)
  rescue StandardError => e
    render_error(message: "An error occurred", errors: [e.message])
  end

  def cancel
    order = find_order(params[:id])
    if order.nil?
      return render_error(message: "Order not found")
    end

    allowed_statuses = [
      Order.statuses[:pending],
      Order.statuses[:paid],
      Order.statuses[:processing]
    ]

    if allowed_statuses.include?(order.status) == false
      return render_error(message: "Order can only be canceled if it's in pending, paid, or processing status")
    end

    order.cancel!
    render_success(message: "Order canceled successfully")
  end

  def tracking_status
    order = find_order(params[:id])
    if order.nil?
      return render_error(message: "Order not found")
    end

    render_success(
      message: "Order tracking retrieved successfully",
      data: {
        current_state: order.status,
        history: order.status_history
      }
    )
  end

  private

  def find_order(id)
    current_user.orders.find_by(id: id)
  end
end
