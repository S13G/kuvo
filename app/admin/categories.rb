ActiveAdmin.register Category do
  permit_params :name, :description
  config.filters = false

  index do
    selectable_column
    column :name
    column :description
    column :number_of_products_with_category do |category|
      category.products.count
    end
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :name
      row :description
      row :number_of_products_with_category do |category|
        category.products.count
      end
      row :created_at
      row :updated_at
    end
  end
end
