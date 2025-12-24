class CreateProductImages < ActiveRecord::Migration[8.1]
  def change
    create_table :product_images, id: :uuid do |t|
      t.references :product, null: false, type: :uuid, foreign_key: true
      t.string :image_url, null: false
      t.boolean :is_main, default: false
      t.timestamps
    end
  end
end
