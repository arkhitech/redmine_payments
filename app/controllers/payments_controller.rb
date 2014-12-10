class PaymentsController < ApplicationController
  unloadable
  skip_before_filter :verify_authenticity_token, only: :finalize
  
  before_filter :find_project

  def index
    return deny_access unless User.current.allowed_to?(:make_payment, @project) ||
      User.current.admin?
    @invoices = Invoice.where("status_id = ? AND project_id IN (?)", 
      Invoice::SENT_INVOICE, @project.self_and_descendants.map(&:id))
  end
  
  def new    
    return deny_access unless User.current.allowed_to?(:make_payment, @project) ||
      User.current.admin?
    invoice = Invoice.includes(:contact).where(project_id: @project.self_and_descendants.map(&:id), id: params[:invoice_id]).first
    @payment = Payment.new(invoice_amount: invoice.remaining_balance, 
      invoice_currency: invoice.currency,
      payment_currency: Setting.plugin_redmine_payments['payment_currency'],
      invoice: invoice, project_id: invoice.project_id)
    @payment.payment_amount
    @payment.customer_name = invoice.contact.name unless invoice.contact.nil?
  end

  def generate
    return deny_access unless User.current.allowed_to?(:make_payment, @project) ||
      User.current.admin?
    invoice = Invoice.includes(:contact).where(project_id: @project.self_and_descendants.map(&:id), id: params[:invoice_id]).first
    @payment = Payment.new(invoice_amount: invoice.remaining_balance, 
      invoice_currency: invoice.currency,
      payment_currency: Setting.plugin_redmine_payments['payment_currency'],
      invoice: invoice, project_id: invoice.project_id)
    @payment.payment_amount
    @payment.customer_name = invoice.contact.name unless invoice.contact.nil?
    
  end
  
  def create
    return deny_access unless User.current.allowed_to?(:make_payment, @project) ||
      User.current.admin?
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
    if @payment.save
      @payment.return_path = finalize_project_payment_url(@project.id, @payment)
      @payment.transaction_for_registration
      
      render 'register'      
      return
    end      
    render 'generate'
  end
  
  def finalize
    @payment = Payment.where(project_id: @project.self_and_descendants.map(&:id), id: params[:id]).first
    @payment.state = Payment::STATE_FINALIZATION
    @payment.transaction_id = params[:TransactionID]
    if @payment.save
      render text: "<table> <h1> Thank you for the payment! </h1> <tr> <th> Payment amount: </th> <td> #{@payment.
      invoice_currency} #{@payment.invoice_amount} (#{@payment.
      payment_currency} #{@payment.payment_amount}) </td> </tr> <tr> <th> Invoice: </th> <td> #{@payment.
      invoice_id} </td> </tr> <tr> <th> Project: </th> <td> #{@payment.project.name} </td> </tr> <tr> <th> Transaction ID: </th> <td> #{@payment.
      transaction_id} </td> </tr> <tr> <th> Approval Code: </th> <td> #{@payment.approval_code} </td> </tr> <tr> <th> Order Info: </th> <td> #{@payment.order_info} </td> </tr> </table>" 
      return

    end
    #else for all
    render 'payment_errors', layout: false
  end
  
  private
  
  def find_project
    @project = Project.find(params[:project_id])
  end
end
