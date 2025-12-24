class CreateProductColors < ActiveRecord::Migration[8.1]
  def change
    create_table :product_colors, id: :uuid do |t|
      t.string :name, null: false
      t.string :hex_code
      t.timestamps
    end
  end
end
