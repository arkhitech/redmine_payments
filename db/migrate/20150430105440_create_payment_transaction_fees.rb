class CreatePaymentTransactionFees < ActiveRecord::Migration
  def change
    create_table :payment_transaction_fees do |t|
      t.integer :invoice_payment_id , indexed: true
      t.float :fee_percentage
      t.float :fee_amount
      t.string :description
    end
  end
end
