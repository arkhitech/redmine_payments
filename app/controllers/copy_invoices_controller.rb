class CopyInvoicesController < ApplicationController
  unloadable
  helper InvoicesHelper
  helper PaymentsHelper
  before_filter :find_invoice_project, :only => [:show]

  def index  
    if params[:project_id]
      if !(User.current.admin? || 
            User.current.allowed_to?(:list_and_edit_invoice_payments , @project)   
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
          
    @invoice_payments
  end
            
end