class PaymentsController < ApplicationController
  unloadable
  
  before_filter :find_project

  def index
    return deny_access unless User.current.allowed_to?(:make_payment, @project) ||
      User.current.admin?
    @invoices = Invoice.where("status_id = ? AND project_id IN (?)", 
      Invoice::SENT_INVOICE, @project.self_and_descendants.map(&:id))
  end
  
  def new    
    invoice = Invoice.includes(:contact).where(project_id: @project.id, id: params[:invoice_id]).first
    @payment = Payment.new(invoice_amount: invoice.remaining_balance, 
      invoice_currency: invoice.currency,
      payment_currency: Setting.plugin_redmine_payments['payment_currency'],
      invoice: invoice, project: @project)
    @payment.payment_amount
    @payment.customer_name = invoice.contact.name unless invoice.contact.nil?
  end

  def partial_payment
    invoice = Invoice.includes(:contact).where(project_id: @project.id, id: params[:invoice_id]).first
    puts invoice
    @payment = Payment.new(invoice_amount: invoice.remaining_balance, 
      invoice_currency: invoice.currency,
      payment_currency: Setting.plugin_redmine_payments['payment_currency'],
      invoice: invoice, project: @project)
    @payment.payment_amount
    @payment.customer_name = invoice.contact.name unless invoice.contact.nil?
    
  end
  
  def create
    @payment = Payment.new(params[:payment])
    @payment.state = Payment::STATE_REGISTRATION
    
    if @payment.save
      redirect_to register_project_payments_path(payment: @payment.id), notice: "Payment of #{@payment.
      invoice_currency} #{@payment.invoice_amount} (#{@payment.
      payment_currency} #{@payment.payment_amount}) applied for Invoice: #{@payment.
      invoice_id} Project: #{@payment.project.name} - Transaction ID: #{@payment.
      transaction_id}, Approval Code: #{@payment.approval_code}, Order Info: #{@payment.order_info}"
    else
      render 'partial_payment'
    end
  end
  
  def register
    @payment = Payment.find(params[:payment])
    @payment.state = Payment::STATE_REGISTRATION
#    if @payment.validate
      transaction = @payment.transaction_for_registration#(@project, 
#          invoice_id: @payment.invoice_id, customer_name: @payment.customer_name)
 #     redirect_to transaction.getProperty('PaymentPage')      
 #   end
  end
  
  def finalize
    @payment = Payment.find(params[:payment])    
    @payment.state = Payment::STATE_FINALIZATION
#    @payment = Payment.new(project_id: @project.id, 
 #     invoice_id: params[:invoice_id], customer_name: params[:customer_name])
    if @payment.transaction_for_finalization(customer_name: params[:customer_name], transaction_id: params[:transaction_id])
      
    end
  end
  
  private
  
  def find_project
    @project = Project.find(params[:project_id])
  end
end
