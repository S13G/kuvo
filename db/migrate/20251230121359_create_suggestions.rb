class CreateSuggestions < ActiveRecord::Migration[8.1]
  def change
    create_table :suggestions, id: :uuid do |t|
      t.string :name
      t.integer :frequency

      t.timestamps
    end
  end
end
