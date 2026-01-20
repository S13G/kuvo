# frozen_string_literal: true

ActiveAdmin.register ShippingFee do
  permit_params :amount_cents
  actions :all, except: [:new, :create] if ShippingFee.exists?

  index do
    selectable_column
    column :amount_cents
    column :updated_at
    actions
  end
end
