class RenameAppSettingsToCurrencySettings < ActiveRecord::Migration[8.1]
  def change
    rename_table :app_settings, :currency_settings
  end
end
