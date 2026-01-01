ActiveAdmin.register ProductColor do
  permit_params :name, :hex_code
  config.filters = false

  index do
    selectable_column
    column :name
    column :hex_code
    actions
  end
end
