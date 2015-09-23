class PaymentTransactionFee < ActiveRecord::Base
  unloadable
  attr_accessible :fee_amount, :fee_percentage, :description , :fee_tax_amount , :fee_tax_percentage
  belongs_to :invoice_payment
  validates :fee_percentage , presence: true
  validates :fee_amount , presence: true
  validates :description , presence: true
  validates :fee_tax_amount, presence: true
  validates :fee_tax_percentage , presence: true
end
