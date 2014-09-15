class PaymentsController < ApplicationController
  unloadable
  
  before_filter :find_project

  def index
    return deny_access unless User.current.allowed_to?(:view_invoices, @project) ||
      User.current.admin?
    @invoices = Invoice.where("project_id IN (?)", @project.self_and_descendants.map(&:id))
  end
  
  def make_payment
    
  end
  
  def show_payment
    require 'rjb'
    Rjb::load

    transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction");

    transaction = transaction_class.new("#{ENV['JAVA_HOME']}/jre/lib/SPI.properties");
    transaction.initialize("Authorization","1.0");
    transaction.setProperty("Customer", params[:name]);
    transaction.setProperty("Amount", params[:amount]);
    transaction.setProperty("Currency", "PKR");
    transaction.setProperty("CardNumber", params[:number]);
    transaction.setProperty("ExpiryDate", params[:date]);
    transaction.setProperty("OrderName", "Test Order");
    transaction.setProperty("OrderInfo", "Testing Order Info");
    transaction.setProperty("OrderID","123456");
		transaction.setProperty("TransactionHint", "CPT:Y");
		transaction.setProperty("VerifyCode", params[:code]);
		    
    @transaction = transaction
    @result = transaction.execute();

    @approval_code = @transaction.getProperty("ApprovalCode")
    @balance = @transaction.getProperty("Balance")
    @transaction_id = @transaction.getProperty("TransactionID")
  end
  
  private
  
  def find_project
    @project = Project.find(params[:id])
  end
end
