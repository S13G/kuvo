class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items, id: :uuid do |t|
      t.references :order, null: false, type: :uuid, index: true
      t.references :product, null: false, type: :uuid, index: true
      t.references :product_variant, type: :uuid, index: true
      t.integer :quantity, default: 1, null: false
      t.integer :unit_price_cents, default: 0, null: false

      t.timestamps
    end

    add_foreign_key :order_items, :orders, name: "fk_order_items_orders"
    add_foreign_key :order_items, :products, name: "fk_order_items_products"
    add_foreign_key :order_items, :product_variants, name: "fk_order_items_product_variants"
  end
end
