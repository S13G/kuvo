# frozen_string_literal: true

ActiveAdmin.register ShippingFee do
  permit_params :amount_cents

  actions :index, :show, :edit, :update

  index do
    selectable_column
    id_column
    column :amount_cents
    column :updated_at
    actions
  end

  form do |f|
    f.inputs do
      f.input :amount_cents
    end
    f.actions
  end

  controller do
    def index
      if ShippingFee.count == 0
        ShippingFee.instance
      end
      super
    end
  end
end
