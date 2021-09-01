class AdjustPaymentColumns < ActiveRecord::Migration[4.2]
	def change
    change_column :payments, :invoice_amount, :decimal, precision: 10, scale: 2
    change_column :payments, :payment_amount, :decimal, precision: 10, scale: 2
    change_column :payment_transaction_fees, :fee_percentage, :decimal, precision: 5, scale: 2
#    change_column :payment_transaction_fees, :fee_tax_amount, :decimal, precision: 10, scale: 2
    change_column :payment_transaction_fees, :fee_tax_percentage, :decimal, precision: 5, scale: 2
  end
end
