class AddUniqueIndexToOrdersTrackingNumber < ActiveRecord::Migration[8.1]
  def change
    add_index :orders, :tracking_number, unique: true
  end
end
