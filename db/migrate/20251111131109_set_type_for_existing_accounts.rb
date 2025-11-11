class SetTypeForExistingAccounts < ActiveRecord::Migration[8.1]
  def up
    # Set all existing accounts to SavingsAccount type
    execute "UPDATE accounts SET type = 'SavingsAccount' WHERE type IS NULL"
  end

  def down
    execute "UPDATE accounts SET type = NULL WHERE type = 'SavingsAccount'"
  end
end
