class AddMortgageFieldsToAccounts < ActiveRecord::Migration[8.1]
  def change
    add_column :accounts, :type, :string
    add_column :accounts, :principal, :decimal, precision: 10, scale: 2
    add_column :accounts, :interest_rate, :decimal, precision: 5, scale: 3
    add_column :accounts, :term_years, :integer
    add_column :accounts, :loan_start_date, :date

    add_index :accounts, :type
  end
end
