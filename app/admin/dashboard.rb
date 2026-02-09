# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  controller do
    before_action :add_styles

    private

    def add_styles
      @page_styles = <<~CSS
        .dashboard-card {
          background: #fff;
          border-radius: 4px;
          padding: 20px;
          box-shadow: 0 1px 3px rgba(0,0,0,0.1);
          text-align: center;
          margin-bottom: 20px;
        }
        .dashboard-stat {
          font-size: 2.5em;
          font-weight: 300;
          margin: 0;
          color: #333;
        }
        .dashboard-label {
          color: #666;
          margin: 5px 0 0;
          font-size: 0.9em;
        }
        .dashboard-card-actions {
          margin-top: 15px;
        }
        .dashboard-card-actions .button {
          margin: 0 5px;
          font-size: 0.8em;
          padding: 5px 10px;
        }
        .recent-activities {
          list-style: none;
          padding: 0;
          margin: 0;
        }
        .activity-item {
          padding: 10px 0;
          border-bottom: 1px solid #f0f0f0;
          display: flex;
          justify-content: space-between;
        }
        .activity-item:last-child { border-bottom: none; }
        .activity-text { flex-grow: 1; }
        .activity-time { color: #999; font-size: 0.9em; }
        .activity-user { color: #4a90e2; }
        .activity-order { color: #50e3c2; }
        .activity-product { color: #f5a623; }
        .activity-review { color: #b8e986; }
      CSS
    end
  end

  content title: proc { I18n.t("active_admin.dashboard") } do
    style @page_styles if @page_styles.present?

    columns do
      column do
        panel "Products" do
          div class: "dashboard-card" do
            h1 Product.count, class: "dashboard-stat"
            p "Total Products", class: "dashboard-label"
          end
          div class: "dashboard-card-actions" do
            link_to "View All", url_for([:admin, :products]), class: "button"
            link_to "Add New", url_for([:new, :admin, :product]), class: "button primary"
          end
        end
      end

      column do
        panel "Users" do
          div class: "dashboard-card" do
            h1 User.count, class: "dashboard-stat"
            p "Total Users", class: "dashboard-label"
          end
          div class: "dashboard-card-actions" do
            link_to "View All", url_for([:admin, :users]), class: "button"
          end
        end
      end

      # Total Revenue
      column do
        panel "Revenue" do
          total_revenue = Transaction.where(complete_fl: true).sum(:amount)
          div class: "dashboard-card" do
            h1 number_to_currency(total_revenue), class: "dashboard-stat"
            p "Total Revenue", class: "dashboard-label"
          end
          div class: "dashboard-card-actions" do
            link_to "View Transactions", url_for([:admin, :transactions]), class: "button"
          end
        end
      end

      # Recent Orders
      column do
        panel "Recent Orders" do
          recent_orders_count = Order.where("created_at >= ?", 24.hours.ago).count
          div class: "dashboard-card" do
            h1 recent_orders_count.to_s, class: "dashboard-stat"
            p "New Orders (24h)", class: "dashboard-label"
          end
          div class: "dashboard-card-actions" do
            link_to "View Orders", url_for([:admin, :orders]), class: "button"
          end
        end
      end
    end

    columns do
      column do
        panel "Recent Processed Transactions" do
          table_for Transaction.includes(:order).order(created_at: :desc).limit(10) do
            column :transaction_id do |t|
              link_to t.transaction_id, admin_transaction_path(t)
            end
            column :order do |t|
              link_to t.order.tracking_number, admin_order_path(t.order)
            end
            column :amount do |t|
              number_to_currency(t.amount)
            end
            column :status
            column :created_at do |t|
              t.created_at.strftime("%Y-%m-%d %H:%M")
            end
          end
          div style: "margin-top: 10px;" do
            link_to "View All Transactions", admin_transactions_path, class: "button"
          end
        end
      end

      column do
        panel "Recent Activities" do
          activities = []
          activities += User.order(created_at: :desc).limit(3).map do |u|
            { type: "user", text: "New user: #{u.email}", time: u.created_at }
          end
          activities += Order.order(created_at: :desc).limit(3).map do |o|
            { type: "order", text: "Order #{o.tracking_number} placed", time: o.created_at }
          end
          activities += ProductReview.order(created_at: :desc).limit(3).map do |r|
            { type: "review", text: "Review for #{r.product.name}", time: r.created_at }
          end

          activities = activities.sort_by { |a| a[:time] }.reverse.first(10)

          ul class: "recent-activities" do
            activities.each do |activity|
              li class: "activity-item activity-#{activity[:type]}" do
                span class: "activity-text" do
                  activity[:text]
                end
                span class: "activity-time" do
                  time_ago_in_words(activity[:time]) + " ago"
                end
              end
            end
          end
        end
      end
    end

    columns do
      column do
        panel "Low Stock Products" do
          table_for Product.joins(:product_variants)
                           .where("product_variants.stock <= ?", 10)
                           .distinct
                           .limit(5) do
            column :name
            column("Stock") { |p| p.product_variants.sum(:stock) }
            column("Actions") do |product|
              link_to "Manage", url_for([:admin, product])
            end
          end
          div style: "margin-top: 10px;" do
            link_to "View All Low Stock Products", url_for([:admin, :products]), class: "button"
          end
        end
      end

      # Recent Reviews
      column do
        panel "Recent Product Reviews" do
          table_for ProductReview.includes(:user, :product).order(created_at: :desc).limit(5) do
            column :user do |review|
              review.user&.profile&.full_name || "Anonymous"
            end
            column :product
            column :rating
            column :comment do |review|
              truncate(review.comment, length: 30) if review.comment.present?
            end
            column :created_at
          end
          div style: "margin-top: 10px;" do
            link_to "View All Reviews", url_for([:admin, :product_reviews]), class: "button"
          end
        end
      end
    end
  end
end
