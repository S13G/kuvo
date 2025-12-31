class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, index: true
      t.string :payment_status, default: 'pending'
      t.integer :total_price_cents, default: 0
      t.timestamps
    end

    add_foreign_key :carts, :users, type: :uuid, name: 'fk_carts_users'
  end
end
