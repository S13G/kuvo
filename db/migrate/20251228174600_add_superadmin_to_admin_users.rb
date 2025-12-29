class AddSuperadminToAdminUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :admin_users, :superadmin, :boolean, default: false, null: false
    add_index :admin_users, :superadmin
  end
end
