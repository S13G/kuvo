class MakeProductSizeAndColorIdNullableInProductVariants < ActiveRecord::Migration[8.1]
  def change
    change_column_null :product_variants, :product_size_id, true
    change_column_null :product_variants, :product_color_id, true
  end
end
