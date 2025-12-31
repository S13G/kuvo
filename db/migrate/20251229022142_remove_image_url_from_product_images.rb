class RemoveImageUrlFromProductImages < ActiveRecord::Migration[8.1]
  def change
    remove_column :product_images, :image_url, :string
  end
end
