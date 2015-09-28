class AddFeeTaxAmountAndFeeTaxPercentageToPaymentTransactionFee < ActiveRecord::Migration
  def change
      add_column :payment_transaction_fees, :fee_tax_amount, :decimal, precision: 10, scale: 2
      add_column :payment_transaction_fees, :fee_tax_percentage, :decimal, precision: 5, scale: 2
  end
end
