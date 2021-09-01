class CreatePayment < ActiveRecord::Migration[4.2]  
  def self.up
    create_table :payments do |t|
      t.string :customer_name
      t.decimal :invoice_amount, precision: 10, scale: 2
      t.string :invoice_currency, size: 3
      t.decimal :payment_amount, precision: 10, scale: 2
      t.string :payment_currency, size: 3
      t.string :transaction_id
      t.string :response_code
      t.string :response_description
      t.string :approval_code
      
      t.references :invoice
      t.references :project
    end
  end

  def self.down
    drop_table :payments
  end
end
