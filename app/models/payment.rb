class Payment < ActiveRecord::Base
  attr_accessor :cc_number, :cvv2
  attr_accessor :state
  attr_accessor :return_path
  attr_accessor :payment_page
  
  STATE_REDIRECT = 'Redirect'  
  STATE_REGISTRATION = 'Registration'  
  STATE_AUTHORIZATION = 'Authorization'
  STATE_FINALIZATION = 'Finalization'
  
  composed_of :expiry_date, class_name: "DateTime",
    mapping: %w(Time to_s),
    constructor: Proc.new { |item| item },
    converter: Proc.new { |item| item }
  
  belongs_to :invoice
  belongs_to :project
  
  #before_create :execute
  
  validate :validate_credit_card
  validates :cc_number, :expiry_date, :cvv2, presence: true, if: 'state == STATE_AUTHORIZATION'
    
  validates :payment_amount, :payment_currency, :project_id, presence: true

  validates :transaction_id, presence: true, if: 'state == STATE_FINALIZATION'
  #validates :return_path, presence: true, if: 'state == STATE_REGISTRATION'
    
  before_save do
#    if self.state == STATE_REGISTRATION
#      transaction_for_registration
    if self.state == STATE_FINALIZATION
      transaction_for_finalization
    elsif self.state == STATE_AUTHORIZATION
      authorize_transaction
    else
      errors.add(:base, 'Unknown state of payment')
      false
    end
  end
  
  def validate_credit_card
    unless state == STATE_AUTHORIZATION
      return
    end
    if cc_number.present? && !CreditCardValidator::Validator.valid?(cc_number)
      errors.add(:cc_number, 'is invalid')
    end    
  end
      
  def fx
    @fx ||= begin
      OpenExchangeRates::Rates.new(app_id: Setting.plugin_redmine_payments['open_exchange_rate_app_id'])
    end
  end

  def invoice_amount_to_s
    "#{invoice_currency} #{'%.02f'%invoice_amount}"    
  end
  def remaining_balance_to_s
    "#{invoice_currency} #{'%.02f'%(invoice && invoice.remaining_balance)||invoice_amount}"    
  end
  
  def payment_amount_to_s
    "#{payment_currency} #{'%.02f'%paymount_amount}"    
  end
  
  def invoice_currency
    read_attribute(:invoice_currency) || Setting.plugin_redmine_payments['invoice_currency']    
  end
  
  def payment_currency
    read_attribute(:payment_currency) || Setting.plugin_redmine_payments['payment_currency']    
  end
  
  def payment_amount
    read_attribute(:payment_amount) || write_attribute(:payment_amount, 
      '%.2f'%fx.convert(invoice_amount, from: invoice_currency, to: payment_currency))
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
  
  def transaction_for_registration
    require 'rjb'
    Rjb::load
    transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction");

    transaction = transaction_class.new("#{Rails.root}/plugins/redmine_payments/config/SPI.properties");
    transaction.initialize(STATE_REGISTRATION,"1.0");
    transaction.setProperty("Customer", self.customer_name.to_s)
    transaction.setProperty("Amount", self.payment_amount.to_s)
    transaction.setProperty("Currency", payment_currency.to_s)

    transaction.setProperty("OrderName", order_name.to_s)
    transaction.setProperty("OrderInfo", order_info.to_s)
    transaction.setProperty("OrderID", "#{order_id.to_s}")
		transaction.setProperty("TransactionHint", "CPT:Y")
    transaction.setProperty("ReturnPath", return_path)
    
    result = transaction.execute()
    self.response_code = transaction.getResponseCode
    self.response_description = transaction.getResponseDescription
    self.transaction_id = transaction.getProperty('TransactionID')
      
    if self.response_code.to_i > 0
      errors.add(:base, "#{response_code}: #{response_description}")      
      errors.add(:base, "For more information, please contact your card issuing bank.")
    else
      self.payment_page = transaction.getProperty('PaymentPage')
    end
    
    !errors.any?    
    
  end
  
  def transaction_for_finalization
    require 'rjb'
    Rjb::load
    transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction");

    finalization = transaction_class.new("#{Rails.root}/plugins/redmine_payments/config/SPI.properties");
    finalization.initialize("Finalization","1.0");
    finalization.setProperty("Customer", self.customer_name.to_s)
    finalization.setProperty("TransactionID", self.transaction_id.to_s)
		    
    result = finalization.execute()
    self.response_code = finalization.getResponseCode
    self.response_description = finalization.getResponseDescription

    self.approval_code = finalization.getProperty("ApprovalCode")    
    self.order_id  = finalization.getProperty("OrderID")    
    self.amount = finalization.getProperty("Amount")    
    self.balance = finalization.getProperty("Balance")    
    self.card_number = finalization.getProperty("CardNumber")    
    self.card_token = finalization.getProperty("CardToken")    
    self.account = finalization.getProperty("Account")    
    
    if self.response_code.to_i > 0
      errors.add(:base, "#{response_code}: #{response_description}")      
      errors.add(:base, "For more information, please contact your card issuing bank.")
    else
      InvoicePayment.create!(amount: self.invoice_amount, payment_date: Date.today,
        invoice_id: self.invoice_id, description: "Payment Amount: #{self.payment_currency} #{self.payment_amount}, Transaction ID #{self.transaction_id}, Approval Code: #{self.approval_code}"
      )
    end
    
    !errors.any?    
    

  end
  
  def authorize_transaction
    require 'rjb'
    Rjb::load
    transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction");

    transaction = transaction_class.new("#{Rails.root}/plugins/redmine_payments/config/SPI.properties");
    transaction.initialize(STATE_AUTHORIZATION,"1.0");
    transaction.setProperty("Customer", self.customer_name.to_s)
    transaction.setProperty("Amount", self.payment_amount.to_s)
    transaction.setProperty("Currency", payment_currency.to_s)
    transaction.setProperty("CardNumber", self.cc_number.to_s)
    transaction.setProperty("ExpiryDate", "#{expiry_date.year.to_s}-#{'%02i'%expiry_date.month.to_s}");
    transaction.setProperty("OrderName", order_name.to_s)
    transaction.setProperty("OrderInfo", order_info.to_s)
    transaction.setProperty("OrderID", "#{order_id.to_s}")
		transaction.setProperty("TransactionHint", "CPT:Y")
		transaction.setProperty("VerifyCode", cvv2.to_s);
		    
    result = transaction.execute()
    self.response_code = transaction.getResponseCode
    self.response_description = transaction.getResponseDescription
    self.transaction_id = transaction.getProperty('TransactionID')
    self.approval_code = transaction.getProperty("ApprovalCode")

    if self.response_code.to_i > 0
      errors.add(:base, "#{response_code}: #{response_description}")      
      errors.add(:base, "For more information, please contact your card issuing bank.")
    else
      InvoicePayment.create!(amount: self.invoice_amount, payment_date: Date.today,
        invoice_id: self.invoice_id, description: "Payment Amount: #{self.payment_currency} #{self.payment_amount}, Transaction ID #{self.transaction_id}, Approval Code: #{self.approval_code}"
      )
    end
    
    !errors.any?    
  end
  
end
