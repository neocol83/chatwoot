class AddFilePathToCannedResponses < ActiveRecord::Migration[7.0] # o la versión de Rails que estés usando
    def change
      add_column :canned_responses, :file_path, :string
    end
  end