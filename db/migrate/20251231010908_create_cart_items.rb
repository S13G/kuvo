class CreateCartItems < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_items, id: :uuid do |t|
      t.references :cart, null: false, type: :uuid, index: true
      t.references :product, null: false, type: :uuid, index: true
      t.references :product_variant, null: false, type: :uuid, index: true
      t.integer :quantity, default: 1
      t.integer :price_cents, default: 0
      t.timestamps
    end

    add_foreign_key :cart_items, :carts, name: 'fk_cart_items_carts'
    add_foreign_key :cart_items, :products, name: 'fk_cart_items_products'
    add_foreign_key :cart_items, :product_variants, name: 'fk_cart_items_product_variants'
  end
end
