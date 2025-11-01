class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.decimal :balance, precision: 10, scale: 2, default: 0.0, null: false
      t.decimal :initial_balance, precision: 10, scale: 2, default: 0.0, null: false
      t.datetime :opened_at, null: false

      t.timestamps
    end
  end
end
