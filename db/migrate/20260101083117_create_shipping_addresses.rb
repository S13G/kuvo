class CreateShippingAddresses < ActiveRecord::Migration[8.1]
  def change
    create_table :shipping_addresses, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, index: true
      t.string :address_tag, null: false
      t.string :address
      t.boolean :is_default, default: false
      t.timestamps
    end

    add_index :shipping_addresses, [:user_id, :is_default], unique: true, where: "is_default = true"
    add_index :shipping_addresses, :address_tag, unique: true
    add_foreign_key :shipping_addresses, :users, type: :uuid, name: 'fk_shipping_addresses'
  end
end
