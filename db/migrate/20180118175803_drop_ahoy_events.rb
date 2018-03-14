class DropAhoyEvents < ActiveRecord::Migration[5.0]
  def up
    drop_table :ahoy_events
  end
  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
