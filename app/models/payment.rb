class Payment < ActiveRecord::Base
  attr_accessor :cc_number, :expiry_date, :cvv2, :invoice_id
  
  belongs_to :invoice
  belongs_to :project
  
  before_create :execute
  
  validate :validate_credit_card
  validates :cc_number, :expiry_date, :cvv2, presence: true
  
  
  def validate_credit_card
    return;
    if cc_number.present? && !CreditCardValidator::Validator.valid?(cc_number)
      errors.add(:cc_number, 'is invalid')
    end    
  end
    
  def order_name
    invoice.number
  end
  
  def order_info
    invoice.subject
  end
  def order_id
    invoice_id
  end
  
  def execute
    require 'rjb'
    Rjb::load
    transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction");

    transaction = transaction_class.new("#{ENV['JAVA_HOME']}/jre/lib/SPI.properties");
    transaction.initialize("Authorization","1.0");
    transaction.setProperty("Customer", self.customer_name);
    transaction.setProperty("Amount", self.amount);
    transaction.setProperty("Currency", "PKR");
    transaction.setProperty("CardNumber", self.cc_number);
#    transaction.setProperty("ExpiryDate", @payment.expiry_date);
#    transaction.setProperty("OrderName", @payment.order_name);
#    transaction.setProperty("OrderInfo", @payment.order_info);
    transaction.setProperty("OrderName", "Test Order");
    transaction.setProperty("OrderInfo", "Testing Order Info");
    transaction.setProperty("OrderID","123456");
    transaction.setProperty("OrderID", self.order_id);
		transaction.setProperty("TransactionHint", "CPT:Y");
		transaction.setProperty("VerifyCode", self.cvv2);
		    
    transaction = transaction
    result = transaction.execute();

    balance = @transaction.getProperty("Balance")

    self.response_code = @transaction.getResponseCode
    self.response_description = @transaction.getResponseDescription
    self.transaction_id = @transaction.getProperty('TransactionID')
    self.approval_code = @transaction.getProperty("ApprovalCode")
    
  end
  private :execute
end
