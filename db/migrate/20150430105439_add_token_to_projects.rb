class AddTokenToProjects < ActiveRecord::Migration
  def change
      add_column :projects, :token, :string
    add_index :projects, :token, unique: true
  end
end
