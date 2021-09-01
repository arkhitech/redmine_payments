class CreatePaymentTransactionFees < ActiveRecord::Migration[4.2]
	def change
    create_table :payment_transaction_fees do |t|
      t.integer :invoice_payment_id , indexed: true
      t.decimal :fee_percentage, precision: 5, scale: 2
      t.decimal :fee_amount, precision: 10, scale: 2
      t.string :description
    end
  end
end
