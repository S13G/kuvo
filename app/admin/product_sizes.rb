ActiveAdmin.register ProductSize do
  permit_params :name, :code
  config.filters = false

  index do
    selectable_column
    column :name
    column :code
    actions
  end
end
