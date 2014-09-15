class PaymentsController < ApplicationController
  unloadable
  
  before_filter :find_project

  def index
    return deny_access unless User.current.allowed_to?(:view_invoices, @project) ||
      User.current.admin?
    @invoices = Invoice.where("project_id IN (?)", @project.self_and_descendants.map(&:id))
  end
  
  def new    
    invoice = Invoice.where(project_id: @project.id, id: params[:invoice_id]).first
    @payment = Payment.new(amount: invoice.amount.to_f.to_s, customer_name: 'Demo Merchant', 
      invoice: invoice)
  end
  
  def create
    require 'rjb'
    Rjb::load
    @payment = Payment.new(params[:payment])
    transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction");

    transaction = transaction_class.new("#{ENV['JAVA_HOME']}/jre/lib/SPI.properties");
    transaction.initialize("Authorization","1.0");
    transaction.setProperty("Customer", @payment.customer_name);
    transaction.setProperty("Amount", @payment.amount);
    transaction.setProperty("Currency", "PKR");
    transaction.setProperty("CardNumber", @payment.cc_number);
    transaction.setProperty("ExpiryDate", @payment.expiry_date);
    transaction.setProperty("OrderName", @payment.order_name);
    transaction.setProperty("OrderInfo", @payment.order_info);
    transaction.setProperty("OrderID", @payment.order_id);
		transaction.setProperty("TransactionHint", "CPT:Y");
		transaction.setProperty("VerifyCode", @payment.cvv2);
		    
    @transaction = transaction
    @result = transaction.execute();

    @balance = @transaction.getProperty("Balance")

    @payment.response_code = @transaction.getResponseCode
    @payment.response_description = @transaction.getResponseDescription
    @payment.transaction_id = @trasaction.getProperty('TransactionID')
    @payment.approval_code = @transaction.getProperty("ApprovalCode")
    @payment.save
  end
  
  private
  
  def find_project
    @project = Project.find(params[:project_id])
  end
end
