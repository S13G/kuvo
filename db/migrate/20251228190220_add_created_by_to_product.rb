class AddCreatedByToProduct < ActiveRecord::Migration[8.1]
  def change
    # First add the column as nullable
    add_column :products, :created_by, :string

    # Find the first superadmin or default admin
    admin_user = AdminUser.find_by(superadmin: true)

    # Set a default admin for existing records
    if admin_user
      Product.where(created_by: nil).update_all(created_by: admin_user.email)
    end

    # Now make the column non-nullable
    change_column_null :products, :created_by, false
  end
end