class AddMaterialsToTickets < ActiveRecord::Migration[5.0]
  def change
    add_column :tickets, :materials, :text
    add_column :ticket_scannings, :materials, :text
  end
end
