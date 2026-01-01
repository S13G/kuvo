class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, index: true
      t.references :shipping_address, null: false, type: :uuid, index: true
      t.integer :total_amount_cents, default: 0, null: false
      t.integer :shipping_fee_cents, default: 0, null: false
      t.string :status, default: "pending", null: false
      t.string :tracking_number

      t.timestamps
    end

    add_foreign_key :orders, :users, name: "fk_orders_users"
    add_foreign_key :orders, :shipping_addresses, name: "fk_orders_shipping_address"
  end
end
