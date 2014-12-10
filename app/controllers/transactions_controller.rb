class TransactionsController < ApplicationController
  unloadable
  
  def index
    require 'rjb'
    Rjb::load

    transaction_class = Rjb::import("ae.co.comtrust.payment.IPG.SPIj.Transaction");

    transaction = transaction_class.new("#{ENV['JAVA_HOME']}/jre/lib/SPI.properties");
    transaction.initialize("Registration","1.0");
    #transaction.setProperty("Customer", "Arkhitech");
    transaction.setProperty("Amount", "12.23");
    transaction.setProperty("Currency", "PKR");
    transaction.setProperty("CardNumber", "999000000000011");
    transaction.setProperty("ExpiryDate", "2012-12");
    transaction.setProperty("OrderName", "Test Order");
    transaction.setProperty("OrderInfo", "Testing Order Info");
    transaction.setProperty("OrderID","123456");
		transaction.setProperty("TransactionHint", "CPT:Y");
		transaction.setProperty("VerifyCode", "0000");
		    
    @transaction = transaction
    @result = transaction.execute();

    @approval_code = @transaction.getProperty("ApprovalCode")
    @balance = @transaction.getProperty("Balance")
    @transaction_id = @transaction.getProperty("TransactionID")
  end
end
