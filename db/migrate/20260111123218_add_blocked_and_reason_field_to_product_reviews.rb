class AddBlockedAndReasonFieldToProductReviews < ActiveRecord::Migration[8.1]
  def change
    add_column :product_reviews, :is_blocked, :boolean, default: false
    add_column :product_reviews, :reason, :string

    add_index :product_reviews, :is_blocked

  end
end
