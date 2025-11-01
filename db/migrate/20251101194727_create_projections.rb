class CreateProjections < ActiveRecord::Migration[8.1]
  def change
    create_table :projections do |t|
      t.references :account, null: false, foreign_key: true, index: { unique: true }
      t.decimal :monthly_contribution, precision: 10, scale: 2, null: false, default: 0
      t.decimal :annual_return_rate, precision: 5, scale: 2, null: false

      t.timestamps
    end
  end
end
