class CreateProductVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :product_variants, id: :uuid do |t|
      t.references :product, null: false, type: :uuid, foreign_key: true
      t.references :product_size, null: false, type: :uuid, foreign_key: true
      t.references :product_color, null: false, type: :uuid, foreign_key: true
      t.integer :stock, default: 0
      t.timestamps
    end
  end
end
