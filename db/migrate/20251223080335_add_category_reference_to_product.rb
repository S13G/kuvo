class AddCategoryReferenceToProduct < ActiveRecord::Migration[8.1]
  def change
    create_table :product_categories, id: :uuid do |t|
      t.references :product, null: false, type: :uuid, foreign_key: true
      t.references :category, null: false, type: :uuid, foreign_key: true

      t.timestamps
    end

    add_index :product_categories,
              [:product_id, :category_id],
              unique: true,
              name: "index_product_categories_on_product_and_category"
  end
end