class CreateBlacklistedTokens < ActiveRecord::Migration[8.1]
  def change
    create_table :blacklisted_tokens, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: true
      t.string :jti, null: false, index: { unique: true }
      t.datetime :expires_at, null: false
      t.timestamps
    end
  end
end
