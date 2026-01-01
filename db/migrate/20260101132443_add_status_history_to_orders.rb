class AddStatusHistoryToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :status_history, :jsonb, default: [], null: false
  end
end
