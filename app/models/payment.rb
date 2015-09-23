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
  validates :cc_number, :expiry_date, :cvv2, presence: true, if: "state == 'STATE_AUTHORIZATION'"
    
  validates :payment_amount, :payment_currency, :project_id, presence: true

  validates :transaction_id, presence: true, if: "state == 'STATE_FINALIZATION'"
  #validates :return_path, presence: true, if: 'state == STATE_REGISTRATION'

  before_save do
    if self.state == STATE_REGISTRATION
#      transaction_for_registration
    elsif self.state == STATE_FINALIZATION
      transaction_for_finalization
    elsif self.state == STATE_AUTHORIZATION
      authorize_transaction
    else
      errors.add(:base, 'Unknown state of payment')
      false
    end
  end
  
   def notify_payment_completed
    group_ids = Setting.plugin_redmine_payments['eligible_for_email_notification']
      @eligible_users= User.active.joins(:groups).
        where("#{User.table_name_prefix}groups_users#{User.table_name_suffix}.id" => 
          group_ids).group("#{User.table_name}.id")
      @eligible_users.sort_by{|e| e[:firstname]}
      @eligible_users.each do |user|
       PaymentMailer.notify_payment(user,self).deliver
     end
  end
  private :notify_payment_completed
  
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
#    read_attribute(:payment_amount) || write_attribute(:payment_amount, 
#      '%.2f'%fx.convert(invoice_amount||0, from: invoice_currency, to: payment_currency))
    read_attribute(:payment_amount) || write_attribute(:payment_amount, 
      '%.2f'%fx.convert(invoice_amount.to_f||0, from: invoice_currency, to: payment_currency))
  end
  
  def order_info
    invoice.description[0..255].gsub(/\r|\n|\t/," ").strip.encode("ISO-8859-1", invalid: :replace, undef: :replace, replace: "?")
  end
  
  def order_id
    "#{invoice_id}-#{id}"[0..15]
  end

  def order_name
    if invoice.subject =~ /^\d+/
      #order name is expected to start with alphabets
      "invoice-#{invoice.subject}".to_s[0..24]
    else
      invoice.subject.to_s[0..24]
    end
  end
  
  def transaction_for_registration
    require 'rjb'
    Rjb::load
    transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction");

    transaction = transaction_class.new("#{Rails.root}/plugins/redmine_payments/config/SPI.properties");
    transaction.initialize(STATE_REGISTRATION,"1.0");

    transaction.setProperty("Channel", 'Web')
    transaction.setProperty("Amount", self.payment_amount.to_s)
    transaction.setProperty("Currency", payment_currency.to_s)

    transaction.setProperty("OrderName", order_name.to_s)
    transaction.setProperty("OrderInfo", order_info.to_s)
    transaction.setProperty("OrderID", "#{order_id}")
    transaction.setProperty("TransactionHint", "CPT:Y;VCC:Y")
    transaction.setProperty("ReturnPath", return_path)

    logger.error("Customer: #{transaction.getProperty('Customer')}")
    #logger.error("Store: #{transaction.getProperty('Store')}")
    #logger.error("Terminal: #{transaction.getProperty('Terminal')}")
    logger.error("Channel: #{transaction.getProperty('Channel')}")
    logger.error("Amount: #{transaction.getProperty('Amount')}")
    logger.error("Currency: #{transaction.getProperty('Currency')}")
    logger.error("OrderName: #{transaction.getProperty('OrderName')}")
    logger.error("OrderInfo: #{transaction.getProperty('OrderInfo')}")
    logger.error("OrderID: #{transaction.getProperty('OrderID')}")
    logger.error("TransactionHint: #{transaction.getProperty('TransactionHint')}")
    logger.error("ReturnPath: #{return_path}")

    result = transaction.execute()
    self.response_code = transaction.getResponseCode
    self.response_description = transaction.getResponseDescription
      
    if self.response_code.to_i > 0
      errors.add(:base, "#{response_code}: #{response_description}")      
      errors.add(:base, "For more information, please contact your card issuing bank.")
    else
      self.transaction_id = transaction.getProperty('TransactionID')      
      self.payment_page = transaction.getProperty('PaymentPage')
    end
    
    !errors.any?    
    
  end
  
  def transaction_for_finalization
    require 'rjb'
    Rjb::load
    transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction");

    finalization = transaction_class.new("#{Rails.root}/plugins/redmine_payments/config/SPI.properties");
    finalization.initialize(STATE_FINALIZATION,"1.0");

    finalization.setProperty("TransactionID", self.transaction_id.to_s)
		    
    result = finalization.execute()
    self.response_code = finalization.getResponseCode
    self.response_description = finalization.getResponseDescription

    self.approval_code = finalization.getProperty("ApprovalCode")    
    self.payment_order_id  = finalization.getProperty("OrderID")    
    self.payment_amount = finalization.getProperty("Amount")    
    self.payment_balance = finalization.getProperty("Balance")    
    self.payment_card_number = finalization.getProperty("CardNumber")    
    self.payment_card_token = finalization.getProperty("CardToken")    
    self.payment_account = finalization.getProperty("Account")    
    
    if self.response_code.to_i > 0
      errors.add(:base, "#{response_code}: #{response_description}")      
      errors.add(:base, "For more information, please contact your card issuing bank.")
    else
      @invoice_payment = InvoicePayment.create!(amount: self.invoice_amount, payment_date: Date.today,
        invoice_id: self.invoice_id, description: "Payment Amount: #{self.payment_currency} #{self.payment_amount}, Transaction ID #{self.transaction_id}, Approval Code: #{self.approval_code}"
      )
      self.record_transaction_fee(@invoice_payment)
      #send email to group
      notify_payment_completed      
    end
    
    !errors.any?    
    

  end
  
  def authorize_transaction
    require 'rjb'
    Rjb::load
    transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction");

    transaction = transaction_class.new("#{Rails.root}/plugins/redmine_payments/config/SPI.properties");
    transaction.initialize(STATE_AUTHORIZATION,"1.0");
    #logger.error("Customer is: #{transaction.getProperty('Customer')}")
    #transaction.setProperty("Customer", self.customer_name.to_s)
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
      invoice_payment = InvoicePayment.create!(amount: self.invoice_amount, payment_date: Date.today,
        invoice_id: self.invoice_id, description: "Payment Amount: #{self.payment_currency} #{self.payment_amount}, Transaction ID #{self.transaction_id}, Approval Code: #{self.approval_code}"
      )
      self.record_transaction_fee(invoice_payment)
    end
    
    !errors.any?    
  end
  def record_transaction_fee invoice_payment
    fixed_fee = 0.00
    fee_percentage = 0.00
    fixed_tax_amount_on_fee_percentage = 0.00 
    tax_percentage_on_fee_percentage = 0.00
    if Setting.plugin_redmine_payments['card_fixed_fee'].present?
      fixed_fee = BigDecimal(Setting.plugin_redmine_payments['card_fixed_fee'])     
    end
    if Setting.plugin_redmine_payments['card_fee_percentage'].present?
      fee_percentage = BigDecimal(Setting.plugin_redmine_payments['card_fee_percentage'])      
    end
    if Setting.plugin_redmine_payments['fee_transaction_tax_amount'].present?
      fixed_tax_amount_on_fee_percentage = BigDecimal(Setting.plugin_redmine_payments['fee_transaction_tax_amount'])      
    end                          
    if Setting.plugin_redmine_payments['fee_transaction_tax_percentage'].present?
      tax_percentage_on_fee_percentage = BigDecimal(Setting.plugin_redmine_payments['fee_transaction_tax_percentage'])      
    end
    
    if fixed_fee > 0 || fee_percentage > 0
      transaction_fee = invoice_payment.build_payment_transaction_fee
      transaction_fee.fee_amount = fixed_fee
      transaction_fee.fee_percentage = fee_percentage
      transaction_fee.fee_tax_amount = fixed_tax_amount_on_fee_percentage
      transaction_fee.fee_tax_percentage = tax_percentage_on_fee_percentage
      transaction_fee.description = "Transaction via credit card: Fee percentage: #{fee_percentage}%(Tax Percentage Over Transaction Fee Percentage: #{tax_percentage_on_fee_percentage},Fixed Tax Amount  Over Transaction Fee Percentage: #{fixed_tax_amount_on_fee_percentage}) Fixed fee: #{fixed_fee}. Total fee: #{invoice_payment.transaction_fee}"
      transaction_fee.save!
    end
  end
end
