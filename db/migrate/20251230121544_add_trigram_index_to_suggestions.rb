class AddTrigramIndexToSuggestions < ActiveRecord::Migration[8.1]
  def change
    if extension_enabled?("pg_trgm") == false
      enable_extension "pg_trgm"
    end

    add_index :suggestions, :name, using: :gin, opclass: { name: :gin_trgm_ops }
  end
end
