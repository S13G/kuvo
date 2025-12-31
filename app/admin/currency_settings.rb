ActiveAdmin.register CurrencySetting do
  permit_params :currency
  actions :all, except: [:new, :create] if CurrencySetting.exists?
  config.filters = false

  index do
    selectable_column
    column :currency
    column :created_at
    column :updated_at
    actions
  end

  show title: :currency do
    attributes_table do
      row :id
      row :currency
      row :created_at
      row :updated_at
    end
  end
end
