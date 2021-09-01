class AddExchangeRateToInvoicePayments < ActiveRecord::Migration[4.2]
	def change
    add_column :invoice_payments, :exchange_rate, :decimal, precision: 5, scale: 2
    add_column :invoice_payments, :converted_amount, :decimal, precision: 10, scale: 2
    add_column :invoice_payments, :converted_currency, :string, size: 3
  end
end
