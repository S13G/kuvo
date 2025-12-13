class CreateUserOtps < ActiveRecord::Migration[8.1]
  def change
    create_table :user_otps do |t|
      t.references :user, null: false, foreign_key: true
      t.string :otp_code
      t.datetime :expires_at
      t.boolean :verified

      t.timestamps
    end
  end
end
