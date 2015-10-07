class PaymentsController < ApplicationController
  unloadable
  menu_item :redmine_payments
  before_filter :find_optional_project, :only => [:show, :index]
  #skip_before_filter :authenticate_user, only: [:shared_invoice,:shared_project]
  skip_before_filter :check_if_login_required, only: [:shared_invoice,:shared_project,:generate,:register, :finalize]
  skip_before_filter :verify_authenticity_token, only: [:finalize,:shared_invoice,:shared_project]
  before_filter :find_project, except: [:shared_invoice, :shared_project, :generate_invoice_payment_token]
  
  def index
    return deny_access unless User.current.allowed_to?(:make_payment, @project) ||
      User.current.admin?
    if @project
      @invoices = Invoice.where(status_id: Invoice::SENT_INVOICE,
        project_id: @project.self_and_descendants.map(&:id))
      @project_token = @project.token || @project.generate_token
    else
      @invoices = Invoice.where(status_id: Invoice::SENT_INVOICE)
    end
      @tasks_grid = initialize_grid(@invoices,
      :name => 'grid',
      :order_direction => 'desc',
      :enable_export_to_csv => true,
      :csv_field_separator => ';',
      :csv_file_name => 'PendingInvoices')
    
    export_grid_if_requested('grid' => 'grid') do
     render 'index'
    end
    
    #render 'index'
  end
  def shared_project
    @project = Project.find_by_token!(params[:token])
    @invoices = Invoice.where("status_id = ? AND project_id IN (?)", 
     Invoice::SENT_INVOICE, @project.self_and_descendants.map(&:id))
   @project_token = @project.token || @project.generate_token
   @tasks_grid = initialize_grid(@invoices,
   :name => 'grid',
   :order_direction => 'desc',
   :enable_export_to_csv => true,
   :csv_field_separator => ';',
   :csv_file_name => 'PendingInvoices')
 
    export_grid_if_requested('grid' => 'grid') do
     render 'index'
    end
    
    #generate_project_invoice(project)
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
    @invoice = Invoice.includes(:contact).where(project_id: @project.self_and_descendants.map(&:id), id: params[:invoice_id]).first
    generate_invoice_payment(@invoice)
    render 'generate'
  end
  
  def shared_invoice
    @invoice = Invoice.find_by_token!(params[:token])
    @project = @invoice.project
    generate_invoice_payment(@invoice)    
    render 'generate'
  end
  
  def generate_project_invoice_token
    @project_token = @project.generate_token
  end
  
  def generate_invoice_payment_token
    @invoice = find_invoice
    @token =  @invoice.generate_token
  end
  
  def generate_project_invoice(project)
    @project_token = project.token || project.generate_token
    render ''
  end
  private :generate_project_invoice
  
  def generate_invoice_payment(invoice)
    @payment = Payment.new(invoice_amount: invoice.remaining_balance, 
      invoice_currency: invoice.currency,
      payment_currency: Setting.plugin_redmine_payments['payment_currency'],
      invoice: invoice, project_id: invoice.project_id)
    @payment.payment_amount
    @payment.customer_name = invoice.contact.name unless invoice.contact.nil?
  end
  private :generate_invoice_payment
  
  
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
#    @payment = Payment.new(params[:payment])
    @payment = Payment.new(payments_params)
    @payment.customer_name ||= @payment.invoice.contact.name unless @payment.invoice.contact.nil?   
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
  def find_invoice
    @invoice = Invoice.find(params[:project_id])
  end
  
  def payments_params
    params.require(:payment).permit(:project_id, :invoice_id, :invoice_amount, :payment_amount)
  end
end
