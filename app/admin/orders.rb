# frozen_string_literal: true

ActiveAdmin.register Order do
  permit_params :user_id, :shipping_address_id, :total_amount_cents, :shipping_fee_cents, :status, :tracking_number

  index do
    selectable_column
    id_column
    column :user
    column :total_amount
    column :shipping_fee
    column :status
    column :tracking_number
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :user do |order|
        link_to order.user.email, admin_user_path(order.user)
      end
      row :total_amount
      row :shipping_fee
      row :status
      row :tracking_number
      row :created_at
      row :updated_at
    end

    panel "Customer Details" do
      attributes_table_for order.user do
        row :email
        row :username
        row :full_name do |user|
          user.profile&.full_name
        end
        row :phone_number do |user|
          user.profile&.phone_number
        end
      end
    end

    panel "Status History" do
      table_for order.status_history.reverse do
        column :from_status do |history|
          history["from_status"] || "N/A"
        end
        column :to_status do |history|
          history["to_status"]
        end
        column :changed_at do |history|
          Time.parse(history["changed_at"]).strftime("%Y-%m-%d %H:%M:%S") if history["changed_at"]
        end
      end
    end

    panel "Shipping Address" do
      attributes_table_for order.shipping_address do
        row :address_tag
        row :address
      end
    end

    panel "Order Items" do
      table_for order.order_items do
        column :product
        column :product_variant do |order_item|
          order_item.product_variant&.product_size&.name || "No variant"
        end
        column :color do |order_item|
          order_item.product_variant&.product_color&.name || "No variant"
        end
        column :quantity
        column :unit_price do |order_item|
          number_to_currency(order_item.unit_price_cents / 100.0)
        end
        column :total_price do |order_item|
          number_to_currency((order_item.unit_price_cents * order_item.quantity) / 100.0)
        end
      end
    end

    panel "Transactions" do
      table_for order.transactions do
        column :transaction_id do |t|
          link_to t.transaction_id, admin_transaction_path(t)
        end
        column :status
        column :amount
        column :currency
        column :complete_fl
        column :created_at
      end
    end
  end

  form do |f|
    f.inputs "Order Details" do
      f.input :user, as: :select, collection: User.all, include_blank: false
      f.input :shipping_address_id, as: :select, collection: ShippingAddress.all.map { |sa| ["#{sa.user.email} - #{sa.address}", sa.id] }, include_blank: false
      f.input :shipping_fee_cents
      f.input :status, as: :select, collection: Order.statuses.keys, include_blank: false
    end
    f.actions
  end
end
