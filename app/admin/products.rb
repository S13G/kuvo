ActiveAdmin.register Product do
  permit_params :name, :description, :price_cents, :is_active, category_ids: [],
                product_variants_attributes: [
                  :id, :product_size_id, :product_color_id,
                  :size_name, :size_code,
                  :color_name, :color_hex,
                  :stock, :_destroy
                ],
                product_images_attributes: [:id, :image_file, :is_main, :_destroy]

  before_create { |record| record.created_by = current_admin_user.email }

  index do
    discount = Discount.first

    selectable_column
    column :main_image do |product|
      main_image = product.product_images.find_by(is_main: true)&.image_file
      if main_image&.attached?
        image_tag(main_image.variant(resize_to_limit: [100, 100]))
      end
    end
    column :name
    column :description
    column :categories do |product|
      product.product_categories.map(&:category).map(&:name).join(", ").html_safe
    end
    column :price_cents
    column :product_price
    column :discounted_price_cents if discount.present? && discount.active
    column :product_discounted_price if discount.present? && discount.active
    column :discount_percentage do
      discount.percentage_off
    end if discount.present? && discount.active
    column :is_active
    column :average_rating
    column :total_stock
    column :created_by
    column :created_at
    column :updated_at
    actions
  end

  show do
    discount = Discount.first

    attributes_table do
      row :id
      row :name
      row :description
      row :price_cents
      row :product_price
      row :discounted_price_cents if discount.present? && discount.active
      row :product_discounted_price if discount.present? && discount.active
      row :discount_percentage do
        discount.percentage_off
      end if discount.present? && discount.active
      row :is_active
      row :average_rating
      row :total_stock
      row :categories do |product|
        product.product_categories.map(&:category).map(&:name).join(", ").html_safe
      end
      row :created_by
      row :created_at
      row :updated_at
    end

    panel "Images" do
      table_for product.product_images do
        column :image do |img|
          if img.image_file.attached?
            image_tag(img.image_file.variant(resize_to_limit: [150, 150]))
          end
        end
        column :is_main
      end
    end

    panel "Variants" do
      table_for product.product_variants do
        column :product_size do |variant|
          variant.product_size&.label || "-"
        end
        column :product_color do |variant|
          variant.product_color&.swatch || "—"
        end
        column :stock
      end
    end
  end

  form do |f|
    f.inputs "Product Details" do
      f.input :name
      f.input :description
      f.input :price_cents
      f.input :is_active
      f.input :categories,
              as: :check_boxes,
              collection: Category.all
    end

    f.has_many :product_variants, allow_destroy: true, new_record: "Add Variant" do |v|
      v.inputs "Variant" do
        v.input :product_size,
                as: :select,
                collection: ProductSize.all.map { |ps| [ps.label, ps.id] },
                include_blank: "Select existing size"

        v.input :size_name,
                hint: "Only add a new size name if it doesn't exist in the dropdown above"
        v.input :size_code,
                hint: "Only add a new size code if it doesn't exist in the dropdown above"

        v.input :product_color,
                as: :select,
                collection: ProductColor.all.map { |pc| [pc.display_name, pc.id] },
                include_blank: "Select existing color"

        v.input :color_name,
                hint: "Only add a new color name if it doesn't exist in the dropdown above"
        v.input :color_hex,
                hint: "Only add a new color hex code if it doesn't exist in the dropdown above"

        v.input :stock
      end
    end

    f.has_many :product_images, allow_destroy: true, heading: "Images", new_record: "Add Image" do |i|
      i.input :image_file, as: :file, label: "Upload Image",
              hint: i.object.image_file.attached? ? image_tag(i.object.image_file.variant(resize_to_limit: [100, 100])) : content_tag(:span, "No image uploaded yet")
      i.input :is_main, label: "Main Image"
    end

    f.actions
  end

end