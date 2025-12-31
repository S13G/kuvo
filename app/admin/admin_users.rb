ActiveAdmin.register AdminUser do
  permit_params :email, :password, :password_confirmation, :superadmin

  index do
    selectable_column
    column :email
    column :superadmin
    column :created_at
    column :updated_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :email
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end

  show do
    attributes_table do
      row :id
      row :email
      row :superadmin if current_admin_user&.superadmin?
      row :created_at
      row :updated_at
    end
  end
end
