class AddBadgeRibbonToTickets < ActiveRecord::Migration[5.0]
  def change
    add_column :tickets, :badge_ribbon, :string
  end
end
