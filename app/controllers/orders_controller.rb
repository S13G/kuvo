# frozen_string_literal: true

class OrdersController < ApplicationController
  def index
    per_page = (params[:per_page] || 20).to_i
    page = (params[:page] || 1).to_i

    orders = current_user
               .orders
               .active_orders
               .recent
               .with_items_and_products.page(page).per(per_page)

    render_success(
      message: "Orders retrieved successfully",
      data: {
        page: page,
        per_page: per_page,
        total_pages: orders.total_pages,
        total_count: orders.total_count,
        orders: orders.as_json
      }
    )
  end

  def pay
    order = find_order(params[:id])
    if order.nil?
      return render_error(message: "Order not found")
    end

    if order.status != Order.statuses[:pending]
      return render_error(message: "This order has been paid for")
    end

    required_fields = %i[card_number cvv expiry_month expiry_year]
    missing_fields = required_fields.select { |k| params[k].blank? }
    if missing_fields.any?
      return render_error(message: "Missing card details", errors: missing_fields.map(&:to_s))
    end

    flutterwave = FlutterwaveService.new
    response = flutterwave.charge_card(
      order,
      {
        card_number: params[:card_number].to_s,
        cvv: params[:cvv].to_s,
        expiry_month: params[:expiry_month].to_s,
        expiry_year: params[:expiry_year].to_s
      }
    )

    is_flutterwave_error = response.is_a?(Hash) && (response[:error] == true || response["error"] == true)
    if is_flutterwave_error
      return render_error(message: "Charge failed. Try again", errors: [response[:message] || response["message"]])
    end

    if order.status == Order.statuses[:pending]
      order.update!(status: Order.statuses[:paid])
    end

    # Create a transaction record from the direct charge response if it succeeded
    transaction_data = response.is_a?(Hash) ? (response.dig("data") || response) : {}
    transaction_id = transaction_data.dig("id")
    if transaction_id.present?
      order.transactions.create!(
        transaction_id: transaction_id,
        status: transaction_data.dig("status"),
        amount: transaction_data.dig("amount"),
        currency: transaction_data.dig("currency"),
        raw_data: response
      )
    end

    render_success(message: "Charge initiated", data: response)
  rescue StandardError => e
    render_error(message: "An error occurred", errors: [e.message])
  end

  def cancelled_orders
    per_page = (params[:per_page] || 20).to_i
    page = (params[:page] || 1).to_i

    orders = current_user
               .orders
               .cancelled_orders
               .recent
               .with_items_and_products.page(page).per(per_page)

    render_success(
      message: "Cancelled orders retrieved successfully",
      data: {
        page: page,
        per_page: per_page,
        total_pages: orders.total_pages,
        total_count: orders.total_count,
        orders: orders.as_json
      }
    )
  end

  def completed_orders
    per_page = (params[:per_page] || 20).to_i
    page = (params[:page] || 1).to_i

    orders = current_user
               .orders
               .completed_orders
               .recent
               .with_items_and_products.page(page).per(per_page)

    render_success(
      message: "Completed orders retrieved successfully",
      data: {
        page: page,
        per_page: per_page,
        total_pages: orders.total_pages,
        total_count: orders.total_count,
        orders: orders.as_json
      }
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

    shipping_address_id = params[:shipping_address_id]
    if shipping_address_id.nil?
      return render_error(message: "Shipping address not provided")
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
            raise StandardError, "Insufficient stock for #{variant.product.name}"
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

  def order_success
    order = find_order(params[:id])
    if order.nil?
      return render_error(message: "Order not found")
    end

    render_success(
      message: "Payment successful",
      data: {
        order: order.as_json(include: :order_items),
        message: "Your payment has been processed successfully. Thank you for your order!"
      }
    )
  end

  def verify_payment
    order = find_order(params[:id])
    if order.nil?
      return render_error(message: "Order not found")
    end

    transaction_id = params[:transaction_id]
    if transaction_id.blank?
      transaction = order.transactions.order(created_at: :desc).first
      transaction_id = transaction&.transaction_id
    end

    if transaction_id.blank?
      return render_error(message: "Transaction ID is required for verification")
    end

    result = FlutterwaveService.verify_and_process(transaction_id, order.tracking_number)

    if result[:error]
      render_error(message: result[:message] || "Verification failed")
    else
      render_success(
        message: "Transaction verified successfully",
        data: {
          order: result[:order].as_json,
          transaction: result[:transaction].as_json
        }
      )
    end
  end

  private

  def find_order(order_id)
    current_user.orders.find_by(id: order_id)
  end
end
