class CreateShippingFees < ActiveRecord::Migration[8.1]
  def change
    create_table :shipping_fees, id: :uuid do |t|
      t.integer :amount_cents, default: 0, null: false
      t.boolean :singleton_guard, default: true, null: false

      t.timestamps
    end

    add_index :shipping_fees, :singleton_guard, unique: true
  end
end
