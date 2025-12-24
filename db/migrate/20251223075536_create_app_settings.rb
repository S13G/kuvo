class CreateAppSettings < ActiveRecord::Migration[8.1]
  def change
    create_table :app_settings, id: :uuid do |t|
      t.string :currency, null: false, default: "USD"
      t.timestamps
    end
  end
end
