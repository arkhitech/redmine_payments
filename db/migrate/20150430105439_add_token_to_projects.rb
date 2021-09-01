class AddTokenToProjects < ActiveRecord::Migration[4.2]
	def change
      add_column :projects, :token, :string
    add_index :projects, :token, unique: true
  end
end
