class AddTargetDateToProjections < ActiveRecord::Migration[8.1]
  def change
    add_column :projections, :target_date, :date
  end
end
