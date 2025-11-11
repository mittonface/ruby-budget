class AddDebtAccountFields < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :credit_limit, :decimal, precision: 10, scale: 2
    add_column :accounts, :apr, :decimal, precision: 5, scale: 3
  end
end
