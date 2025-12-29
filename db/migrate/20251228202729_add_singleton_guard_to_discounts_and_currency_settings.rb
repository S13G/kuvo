class AddSingletonGuardToDiscountsAndCurrencySettings < ActiveRecord::Migration[8.1]
  def up
    add_column :discounts, :singleton_guard, :boolean
    add_column :currency_settings, :singleton_guard, :boolean

    Discount.update_all(singleton_guard: true)
    CurrencySetting.update_all(singleton_guard: true)

    # Add the NOT NULL constraint and default for future inserts
    change_column_default :discounts, :singleton_guard, true
    change_column_default :currency_settings, :singleton_guard, true
    change_column_null :discounts, :singleton_guard, false
    change_column_null :currency_settings, :singleton_guard, false

    # Add unique index to enforce singleton
    add_index :discounts, :singleton_guard, unique: true
    add_index :currency_settings, :singleton_guard, unique: true
  end

  def down
    remove_index :discounts, :singleton_guard
    remove_index :currency_settings, :singleton_guard
    remove_column :discounts, :singleton_guard
    remove_column :currency_settings, :singleton_guard
  end
end
