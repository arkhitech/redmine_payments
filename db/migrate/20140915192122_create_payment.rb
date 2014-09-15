class CreatePayment < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.string :customer_name
      t.string :amount
      t.string :transaction_id
      t.string :response_code
      t.string :response_description
      t.string :approval_code
      
      t.references :invoice
    end
  end

  def self.down
    drop_table :payments
  end
end
