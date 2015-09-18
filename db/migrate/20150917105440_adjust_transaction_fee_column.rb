class AdjustTransactionFeeColumn < ActiveRecord::Migration
  def change
    change_column :payment_transaction_fees, :fee_amount, :decimal, precision: 10, scale: 2
  end
end
