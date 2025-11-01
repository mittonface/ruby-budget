class CreateAdjustments < ActiveRecord::Migration[8.1]
  def change
    create_table :adjustments do |t|
      t.references :account, null: false, foreign_key: true
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.text :description
      t.datetime :adjusted_at, null: false

      t.timestamps
    end

    add_index :adjustments, [ :account_id, :adjusted_at ]
  end
end
