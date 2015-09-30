module RedminePayments
  module Decorators
    module InvoicePaymentsDecorator
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable
          menu_item :invoice_payments
          
          include PaymentsHelper
          skip_before_filter :authorize, :only => [:show, :index, :new, :create]
          before_filter :authorize_index_show, :only => [:index, :show, :new, :create]
          before_filter :find_invoice_payment_invoice, :only => [:create , :new]
          #          before_filter :find_invoice_payment_invoice, :only => [:create, :new, :index, :show]
          #    accept_api_auth :index, :show, :create, :update, :destroy ,:view ,:edit
          # before_filter :find_invoice_payment, :except => [ :edit, :index, :show, :create]
          
          alias_method_chain :create, :fee
        end
      end
      
      module InstanceMethods
        def authorize_index_show
          find_optional_project
          global = @project.nil?
          authorize(params[:controller], params[:action], global)
        end
        
        def index  
          if params[:project_id]
            if !(User.current.admin? || 
                  User.current.allowed_to?(:list_and_edit_invoice_payments , @project)
                User.current.allowed_to?(:make_payment , @project)
              )
              deny_access
              return
            end
            
            @invoice_payments = InvoicePayment. 
              joins("INNER JOIN #{Invoice.table_name} on #{Invoice.table_name}.id= #{InvoicePayment.table_name}.invoice_id")
            .joins("INNER JOIN #{Project.table_name} on #{Project.table_name}.id= #{Invoice.table_name}.project_id")
            .where("#{Project.table_name}.identifier=?",params[:project_id])
          else
            #show invoices for all projects that user is authorized to see
            allowed_project_ids = allowed_to_projects(:list_and_edit_invoice_payments).map(&:id)
            allowed_project_ids |= allowed_to_projects(:make_payment).map(&:id)
            
            
            @invoice_payments = InvoicePayment.includes(invoice: :project).
              where("#{Invoice.table_name}.project_id" => allowed_project_ids)
            
            #            @invoice_payments = invoice_payments.delete_if do |ip| 
            #              !(User.current.admin? || User.current.allowed_to?(:list_and_edit_invoice_payments , ip.project))
            #            end
          end
          #byebug
          
          @tasks_grid = initialize_grid(@invoice_payments, 
            :order => 'id',
            :name => 'grid',
            :order_direction => 'desc',
            :enable_export_to_csv => true,
            :csv_field_separator => ';',
            :csv_file_name => 'InvoicePayments')
          
          export_grid_if_requested('grid' => 'grid')
        end
        
        def new
          @invoice_payment = InvoicePayment.new(:amount => @invoice.remaining_balance, :payment_date => Date.today)
        end
        
        def create_with_fee
          @invoice_payment = InvoicePayment.new(invoice_payment_params, without_protection: true)
          # @invoice.contacts = [Contact.find(params[:contacts])]
          @invoice_payment.invoice = @invoice
          @invoice_payment.author = User.current
          if @invoice_payment.save
#              byebug
#              paym_trans_fee = @invoice_payment.payment_transaction_fee
#              
#              paym_trans_fee.fee_amount =   BigDecimal(paym_trans_fee.fee_amount) + (BigDecimal(@invoice_payment.amount) * BigDecimal('%.2f'%paym_trans_fee.fee_percentage) / 100)
#              paym_trans_fee.fee_amount = BigDecimal('%.2f'%paym_trans_fee.fee_amount)
#              paym_trans_fee.save!

            attachments = Attachment.attach_files(@invoice_payment, (params[:attachments] || (params[:invoice_payment] && params[:invoice_payment][:uploads])))
            render_attachment_warning_if_needed(@invoice_payment)
            flash[:notice] = l(:notice_successful_create)
            
            respond_to do |format|
              format.html { redirect_to invoice_path(@invoice) }
              format.api  { render :action => 'show', :status => :created, :location => invoice_payment_url(@invoice_payment) }
            end
          else
            respond_to do |format|
              format.html { render :action => 'new' }
              format.api  { render_validation_errors(@invoice_payment) }
            end
          end
        end
        
        def show
          if params[:id]
            @invoice_payments = InvoicePayment.where("id=?",params[:id])
            params[:description]=@invoice_payments.first.description
          end
        end
        
        def edit
          @invoice_payments = InvoicePayment.where("id=?",params[:id])
          s=params[:invoice_payment] 
          @invoice_payments.first.description=s[:description]
          @invoice_payments.first.save!
          attachments = Attachment.attach_files(@invoice_payments.first, (params[:attachments]     ))
          render_attachment_warning_if_needed(@invoice_payments.first)
          
          flash.now[:success]="Record Updated"
          redirect_to action: :index
          
        end
        private
        def invoice_payment_params
          params.require(:invoice_payment).permit(:amount, :payment_date, :description , 
            payment_transaction_fee_attributes: [:fee_amount , :fee_percentage , :description])
        end
        def find_invoice_payment_invoice
          invoice_id = params[:invoice_id] || (params[:invoice_payment] && params[:invoice_payment][:invoice_id])
          @invoice = Invoice.find(invoice_id)
          @project = @invoice.project
          project_id = params[:project_id] || (params[:invoice_payment] && params[:invoice_payment][:project_id])
        rescue ActiveRecord::RecordNotFound
          render_404
        end
        
      end
    end
  end
end
#@invoice_payments = InvoicePayment.   joins("INNER JOIN #{Invoice.table_name} on #{Invoice.table_name}.id= #{InvoicePayment.table_name}.invoice_id")           .joins("INNER JOIN #{Project.table_name} on #{Project.table_name}.id= #{Invoice.table_name}.project_id")            .where("#{Project.table_name}.name=?","project-for-payments")
