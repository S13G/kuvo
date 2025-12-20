class EnableUuid < ActiveRecord::Migration[8.1]
  def change
    if extension_enabled?("pgcrypto") == false
      enable_extension "pgcrypto"
    end
  end
end
