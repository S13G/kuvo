class CreateProductFavorites < ActiveRecord::Migration[8.1]
  def change
    create_table :product_favorites, id: :uuid do |t|
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.references :product, null: false, type: :uuid, foreign_key: true
      t.timestamps
    end

    add_index :product_favorites,
              [:user_id, :product_id],
              unique: true,
              name: "index_product_favorites_on_user_and_product"
  end
end
