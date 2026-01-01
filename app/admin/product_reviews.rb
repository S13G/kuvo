ActiveAdmin.register ProductReview do
  permit_params :product_id, :user_id, :rating, :comment

  index do
    selectable_column
    column :user
    column :product
    column :rating
    column :comment
    actions
  end
end
