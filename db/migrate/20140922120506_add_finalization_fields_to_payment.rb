class AddFinalizationFieldsToPayment < ActiveRecord::Migration
  def change
    add_column :payments, :payment_order_id, :string
    add_column :payments, :payment_balance, :string
    add_column :payments, :payment_card_number, :string
    add_column :payments, :payment_card_token, :string
    add_column :payments, :payment_account, :string
  end
end
