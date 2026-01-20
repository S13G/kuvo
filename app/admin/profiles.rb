ActiveAdmin.register Profile do
  permit_params :date_of_birth, :full_name, :gender, :phone_number, :user_id, :avatar
  filter :full_name
  filter :gender
  filter :phone_number
  filter :created_at

  index do
    selectable_column
    column :user
    column :full_name
    column :gender
    column :phone_number
    column :date_of_birth
    column :avatar do |profile|
      if profile.avatar.attached?
        image_tag url_for(profile.avatar.variant(resize_to_limit: [50, 50]))
      else
        "No avatar"
      end
    end
    actions
  end

  show do
    attributes_table do
      row :user
      row :full_name
      row :gender
      row :date_of_birth
      row :phone_number
      row :avatar do |profile|
        if profile.avatar.attached?
          image_tag url_for(profile.avatar.variant(resize_to_limit: [200, 200]))
        else
          "No avatar uploaded"
        end
      end
      row :created_at
      row :updated_at
    end
  end
end
