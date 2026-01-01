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
    # Inject custom styles
    style @page_styles if @page_styles.present?

    # First row - Summary Cards
    columns do
      # Total Products
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

      # Total Users
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

      # Total Revenue (example - implement your own method)
      column do
        panel "Revenue" do
          div class: "dashboard-card" do
            h1 number_to_currency(0), class: "dashboard-stat"
            p "Total Revenue", class: "dashboard-label"
          end
          div class: "dashboard-card-actions" do
            link_to "View Reports", "#", class: "button"
          end
        end
      end

      # Recent Orders (example - implement your own model)
      column do
        panel "Recent Orders" do
          div class: "dashboard-card" do
            h1 "0", class: "dashboard-stat"
            p "New Orders (24h)", class: "dashboard-label"
          end
          div class: "dashboard-card-actions" do
            link_to "View Orders", "#", class: "button"
          end
        end
      end
    end

    # Second row - Charts and Recent Activities
    columns do
      # Sales Chart placeholder
      column do
        panel "Sales Overview (Last 30 Days)" do
          div style: "height: 300px; background: #f5f5f5; display: flex; align-items: center; justify-content: center;" do
            p "Sales chart will be displayed here"
          end
        end
      end

      # Recent Activities
      column do
        panel "Recent Activities" do
          ul class: "recent-activities" do
            [
              { type: "user", text: "New user registered: John Doe", time: "2 minutes ago" },
              { type: "order", text: "New order #1234 placed", time: "15 minutes ago" },
              { type: "product", text: 'Product "Sample Product" was updated', time: "1 hour ago" },
              { type: "review", text: 'New review added for "Sample Product"', time: "3 hours ago" }
            ].each do |activity|
              li class: "activity-item activity-#{activity[:type]}" do
                span class: "activity-text" do
                  activity[:text]
                end
                span class: "activity-time" do
                  activity[:time]
                end
              end
            end
          end
        end
      end
    end

    # Third row - Low Stock Products and Recent Reviews
    columns do
      # Low Stock
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
