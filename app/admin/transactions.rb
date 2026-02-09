# frozen_string_literal: true

ActiveAdmin.register Transaction do
  actions :index, :show

  filter :order
  filter :transaction_id
  filter :status
  filter :amount
  filter :currency
  filter :complete_fl
  filter :created_at

  index do
    selectable_column
    id_column
    column :order
    column :transaction_id
    column :status
    column :amount
    column :currency
    column :complete_fl
    column :created_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :order do |t|
        link_to t.order.tracking_number, admin_order_path(t.order)
      end
      row :transaction_id
      row :status
      row :amount
      row :currency
      row :complete_fl
      row :created_at
      row :updated_at
    end

    panel "Order Details" do
      attributes_table_for transaction.order do
        row :tracking_number do |order|
          link_to order.tracking_number, admin_order_path(order)
        end
        row :user
        row :status
        row :total_amount
        row :created_at
      end
    end
  end
end
