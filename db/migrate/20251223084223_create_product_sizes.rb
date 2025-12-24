class CreateProductSizes < ActiveRecord::Migration[8.1]
  def change
    create_table :product_sizes, id: :uuid do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.timestamps
    end
  end
end
