ActiveAdmin.register ProductReview do
  permit_params :product_id, :user_id, :rating, :comment, :is_blocked, :reason

  index do
    selectable_column
    column :user
    column :product
    column :rating
    column :comment
    column :is_blocked
    column :reason
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :user
      row :product
      row :rating
      row :comment
      row :is_blocked
      row :reason
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.inputs "Product Review Details" do
      f.input :user, as: :select, collection: User.all, include_blank: false
      f.input :product, as: :select, collection: Product.all, include_blank: false
      f.input :rating, as: :select, collection: 1..5, include_blank: false
      f.input :comment
      f.input :is_blocked
      f.input :reason
    end
    f.actions
  end

  filter :user
  filter :product
  filter :rating
  filter :comment
  filter :is_blocked
  filter :reason
  filter :created_at
  filter :updated_at
end
