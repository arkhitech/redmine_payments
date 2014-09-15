class Payment < ActiveRecord::Base
  attr_accessor :cc_number, :cvv2
  
  composed_of :expiry_date, class_name: "DateTime",
    mapping: %w(Time to_s),
    constructor: Proc.new { |item| item },
    converter: Proc.new { |item| item }
  
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
      
  def fx
    @fx ||= begin
      OpenExchangeRates::Rates.new(app_id: Setting.plugin_redmine_payments['open_exchange_rate_app_id'])
    end
  end

  def invoice_currency
    read_attribute(:invoice_currency) || Setting.plugin_redmine_payments['invoice_currency']    
  end
  
  def payment_currency
    read_attribute(:payment_currency) || Setting.plugin_redmine_payments['payment_currency']    
  end
  
  def payment_amount
    read_attribute(:payment_amount) || write_attribute(:payment_amount, 
      fx.convert(invoice_amount, from: invoice_currency, to: payment_currency))
  end
  
  def order_info
    invoice.description
  end
  
  def order_id
    invoice_id
  end
  def order_name
    invoice.subject
  end
  
  def execute
    require 'rjb'
    Rjb::load
    transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction");

    transaction = transaction_class.new("#{Rails.root}/plugins/redmine_payments/config/SPI.properties");
    transaction.initialize("Authorization","1.0");
    transaction.setProperty("Customer", self.customer_name)
    transaction.setProperty("Amount", self.payment_amount)
    transaction.setProperty("Currency", payment_currency)
    transaction.setProperty("CardNumber", self.cc_number)
    transaction.setProperty("ExpiryDate", "#{expiry_date.year}-#{'%02i'%expiry_date.month}");
    transaction.setProperty("OrderName", order_name)
    transaction.setProperty("OrderInfo", order_info)
    transaction.setProperty("OrderID", "#{order_id}")
		transaction.setProperty("TransactionHint", "CPT:Y")
		transaction.setProperty("VerifyCode", cvv2);
		    
    result = transaction.execute()
    self.response_code = transaction.getResponseCode
    self.response_description = transaction.getResponseDescription
    self.transaction_id = transaction.getProperty('TransactionID')
    self.approval_code = transaction.getProperty("ApprovalCode")
    if self.response_code.to_i > 0
      errors.add(:base, "#{response_code}: #{response_description}")      
    else
      InvoicePayment.create!(amount: self.invoice_amount, payment_date: Date.today,
        invoice_id: self.invoice_id, description: "Payment Amount: #{self.payment_currency} #{self.payment_amount}, Transaction ID #{self.transaction_id}, Approval Code: #{self.approval_code}"
      )
    end
    
    !errors.any?    
  end
  private :execute
end
