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
  
  def create
    @payment = Payment.new(params[:payment])
    if @payment.save
      redirect_to project_payments_path, notice: "Payment of #{@payment.
      invoice_currency} #{@payment.invoice_amount} (#{@payment.
      payment_currency} #{@payment.payment_amount}) applied for Invoice: #{@payment.
      invoice_id} Project: #{@payment.project.name}"
    else
      render 'new'
    end
  end
  
  private
  
  def find_project
    @project = Project.find(params[:project_id])
  end
end
