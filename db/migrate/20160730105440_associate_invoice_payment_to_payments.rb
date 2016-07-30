class AssociateInvoicePaymentToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :invoice_payment_id, :integer
    add_index :payments, :invoice_payment_id
  end
end
