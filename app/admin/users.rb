ActiveAdmin.register User do
  permit_params :email, :is_verified, :password_digest, :provider, :uid, :username, :last_login_at, :password_changed_at

  index do
    selectable_column
    column :email
    column :provider
    column :username
    column :is_verified
    column :created_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :email
      f.input :provider
      f.input :username
      f.input :is_verified
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end
