class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions, id: :uuid do |t|
      t.references :order, null: false, foreign_key: { to_table: :orders }, type: :uuid, index: true
      t.string :transaction_id
      t.string :status
      t.decimal :amount
      t.string :currency
      t.boolean :complete_fl, default: false
      t.jsonb :raw_data

      t.timestamps
    end

    add_index :transactions, [:order_id, :transaction_id], unique: true
    add_index :transactions, :complete_fl
    add_index :transactions, :status
  end
end