class RemovePaymentStatusFromCarts < ActiveRecord::Migration[8.1]
  def change
    remove_column :carts, :payment_status
  end
end
