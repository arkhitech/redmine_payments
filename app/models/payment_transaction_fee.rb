class PaymentTransactionFee < ActiveRecord::Base
  unloadable
  # attr_accessible :fee_amount, :fee_percentage, :description 
  belongs_to :invoice_payment

  validates :fee_amount, presence: true, if: -> {fee_percentage.blank?}
  validates :description , presence: true
end
