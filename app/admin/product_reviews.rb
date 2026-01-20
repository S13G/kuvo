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
    actions
  end
end
