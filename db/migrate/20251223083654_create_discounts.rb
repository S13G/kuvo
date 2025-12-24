class CreateDiscounts < ActiveRecord::Migration[8.1]
  def change
    create_table :discounts, id: :uuid do |t|
      t.string :name, null: false
      t.integer :percentage_off, null: false
      t.boolean :active, default: false
      t.text :notes, limit: 500
      t.datetime :starts_at
      t.datetime :ends_at
      t.timestamps
    end
  end
end
