class CopyInvoicesController < ApplicationController
  unloadable
  helper InvoicesHelper
  helper PaymentsHelper
  before_filter :find_optional_project, :only => [:show, :index]

  def index  
    if params[:project_id]
      if !(User.current.admin? || 
            User.current.allowed_to?(:list_and_edit_invoice_payments , @project)   
          )
        deny_access
        return
      end
      
      project = Project.find_by_identifier(params[:project_id])
      
      @invoices = project.invoices
      
  end
  end
end           
