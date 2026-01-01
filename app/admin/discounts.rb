ActiveAdmin.register Discount do
  permit_params :name, :percentage_off, :active, :notes, :starts_at, :ends_at
  actions :all, except: [:new, :create] if CurrencySetting.exists?
  config.filters = false

  index do
    selectable_column
    column :name
    column :percentage_off
    column :active
    column :starts_at
    column :ends_at
    column :created_at
    column :updated_at
    actions
  end

end
