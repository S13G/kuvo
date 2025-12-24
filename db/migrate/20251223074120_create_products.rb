class CreateProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :products, id: :uuid do |t|
      t.string :name, null: false
      t.string :description
      t.integer :price_cents, null: false
      t.boolean :is_active
      t.timestamps
    end
  end
end
