require "test_helper"

class ShippingAddressTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "should ensure only one default address exists for a user" do
    address1 = ShippingAddress.create!(user: @user, address: "Address 1", is_default: true)
    address2 = ShippingAddress.create!(user: @user, address: "Address 2", is_default: true)

    assert_not address1.reload.is_default, "First address should no longer be default"
    assert address2.reload.is_default, "Second address should be default"
  end

  test "address_tag should not be present" do
    assert_not_respond_to ShippingAddress.new, :address_tag
  end
end
