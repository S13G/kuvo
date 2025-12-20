class CreateProfiles < ActiveRecord::Migration[8.1]
  def change
    create_table :profiles, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid, index: { unique: true }
      t.string :full_name
      t.string :phone_number
      t.date :date_of_birth
      t.string :gender

      t.timestamps
    end
  end
end
