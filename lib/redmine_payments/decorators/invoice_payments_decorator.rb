module RedminePayments
  module Decorators
    module InvoicePaymentsDecorator
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable
          menu_item :invoice_payments
          
          include PaymentsHelper
          skip_before_filter :authorize, :only => [:show,:index]
          before_filter :authorize_index_show, :only => [:index, :show]
          #          before_filter :find_invoice_payment_invoice, :only => [:create, :new, :index, :show]
          #    accept_api_auth :index, :show, :create, :update, :destroy ,:view ,:edit
          # before_filter :find_invoice_payment, :except => [ :edit, :index, :show, :create]
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
          
          @tasks_grid = initialize_grid(@invoice_payments, include: :invoice,:order => 'id',:order_direction => 'desc')
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
       
      end
    end
  end
end
#@invoice_payments = InvoicePayment.   joins("INNER JOIN #{Invoice.table_name} on #{Invoice.table_name}.id= #{InvoicePayment.table_name}.invoice_id")           .joins("INNER JOIN #{Project.table_name} on #{Project.table_name}.id= #{Invoice.table_name}.project_id")            .where("#{Project.table_name}.name=?","project-for-payments")
