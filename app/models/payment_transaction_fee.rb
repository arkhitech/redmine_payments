class PaymentTransactionFee < ActiveRecord::Base
  unloadable
  belongs_to :invoice_payment
  validates :fee_percentage , presence: true
  validates :fee_amount , presence: true
  validates :description , presence: true
end
