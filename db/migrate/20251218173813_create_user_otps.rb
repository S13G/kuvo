class CreateUserOtps < ActiveRecord::Migration[8.1]
  def change
    create_table :user_otps, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :otp_code
      t.datetime :expires_at
      t.boolean :verified

      t.timestamps
    end
  end
end
