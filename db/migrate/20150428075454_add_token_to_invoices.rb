class AddTokenToInvoices < ActiveRecord::Migration
  def change
    add_column :invoices, :token, :string
    add_index :invoices, :token, unique: true
  end
end
