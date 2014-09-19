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

  def generate
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
    @payment.state = Payment::STATE_AUTHORIZATION
    
    if @payment.save
      redirect_to project_payments_path, notice: "Payment of #{@payment.
      invoice_currency} #{@payment.invoice_amount} (#{@payment.
      payment_currency} #{@payment.payment_amount}) applied for Invoice: #{@payment.
      invoice_id} Project: #{@payment.project.name} - Transaction ID: #{@payment.
      transaction_id}, Approval Code: #{@payment.approval_code}, Order Info: #{@payment.order_info}"
    else
      render 'new'
    end
  end
  
  def register
    @payment = Payment.new(params[:payment])
    @payment.state = Payment::STATE_REGISTRATION
    @payment.return_path = finalize_project_payments_url(@project, @payment)
    if @payment.save
      render 'register'
      return
    end
    render 'generate'
  end
  
  def finalize
    @payment = Payment.find_by_project_id_and_payment_id(@project.id, params[:id])    
    @payment.state = Payment::STATE_FINALIZATION
    @payment.transaction_id = params[:transaction_id]
    if @payment.save
      redirect_to project_payments_path, notice: "Payment of #{@payment.
      invoice_currency} #{@payment.invoice_amount} (#{@payment.
      payment_currency} #{@payment.payment_amount}) applied for Invoice: #{@payment.
      invoice_id} Project: #{@payment.project.name} - Transaction ID: #{@payment.
      transaction_id}, Approval Code: #{@payment.approval_code}, Order Info: #{@payment.order_info}"
    end
    #else for all
    render 'generate'    
  end
  
  private
  
  def find_project
    @project = Project.find(params[:project_id])
  end
end