# frozen_string_literal: true

class ShippingAddressesController < ApplicationController
  def index
    shipping_addresses = current_user.all_shipping_addresses
    render_success(
      message: "All addresses retrieved successfully",
      data: shipping_addresses.as_json
    )
  end

  def show
    shipping_address = find_address(params[:id])

    if shipping_address.nil?
      return render_error(
        message: "Address not found"
      )
    end

    render_success(
      message: "Address retrieved successfully",
      data: shipping_address.as_json
    )
  end

  def create
    shipping_address = current_user.shipping_addresses.build(shipping_address_params)

    if shipping_address.save
      render_success(
        message: "Address created successfully",
        data: shipping_address.as_json
      )
    else
      render_error(
        message: "Error creating address",
        errors: shipping_address.errors.full_messages
      )
    end
  end

  def update
    shipping_address = find_address(params[:id])

    if shipping_address.nil?
      return render_error(
        message: "Address not found"
      )
    end

    if shipping_address.update(shipping_address_params)
      render_success(
        message: "Address updated successfully",
        data: shipping_address.as_json
      )
    else
      render_error(
        message: "Error updating address",
        errors: shipping_address.errors.full_messages
      )
    end
  end

  def destroy
    shipping_address = find_address(params[:id])
    if shipping_address.nil?
      return render_error(
        message: "Address not found"
      )
    end

    shipping_address.destroy
    render_success(
      message: "Address deleted successfully",
      status_code: 204
    )
  end

  private

  def find_address(id)
    if current_user.nil?
      return nil
    end

    current_user.shipping_addresses.find_by(id: id)
  end

  def shipping_address_params
    params.permit(:address_tag, :address, :is_default)
  end
end
