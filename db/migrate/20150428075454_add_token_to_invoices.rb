class AddTokenToInvoices < ActiveRecord::Migration[4.2]
	def change
    add_column :invoices, :token, :string
    add_index :invoices, :token, unique: true
  end
end
