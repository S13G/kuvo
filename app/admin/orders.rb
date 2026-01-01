# frozen_string_literal: true

ActiveAdmin.register Order do
  permit_params :status, :tracking_number

  index do
    selectable_column
    id_column
    column :user
    column :shipping_address
    column :total_amount_cents
    column :shipping_fee_cents
    column :status
    column :tracking_number
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :user
      row :shipping_address
      row :total_amount_cents
      row :shipping_fee_cents
      row :status
      row :tracking_number
      row :created_at
    end

    panel "Order Items" do
      table_for order.order_items do
        column :product
        column :product_variant
        column :quantity
        column :unit_price_cents
        column :total_price_cents
      end
    end
  end

  form do |f|
    f.inputs do
      f.input :status, as: :select, collection: Order.statuses.keys
      f.input :tracking_number
    end
    f.actions
  end
end
