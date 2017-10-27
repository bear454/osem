class AddDocumentFileNameToCfps < ActiveRecord::Migration
  def change
    add_column :cfps, :document_file_name, :string
  end
end
