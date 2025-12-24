class CreateProductReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :product_reviews, id: :uuid do |t|
      t.references :product, null: false, type: :uuid, foreign_key: true
      t.references :user, null: false, type: :uuid, foreign_key: true
      t.integer :rating, null: false
      t.text :comment
      t.timestamps
    end
    add_index :product_reviews,
              [:user_id, :product_id],
              unique: true,
              name: "index_product_reviews_on_user_and_product"
  end
end
