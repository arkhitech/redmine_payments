module RedminePayments
  module Decorators
    module InvoicesDecorator
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          unloadable
          menu_item :copy_invoices
          
          before_filter :find_invoice_project, :only => [:create, :new, :copy]
          before_filter :authorize, :except => [:index, :edit, :update, :destroy, :auto_complete, :client_view]
        end
      end

      module InstanceMethods       
        def copy
          @invoice = Invoice.new
          invoice = Invoice.find(params[:id])
          @invoice.number = invoice.number
          @invoice.attributes = invoice.attributes.dup.except("id", "number", "created_at", "updated_at")
          @invoice.lines = invoice.lines.collect{|l| InvoiceLine.new(l.attributes.dup.except("id", "created_at", "updated_at"))}
          
          (render_403; return false) unless @invoice.editable_by?(User.current)
          @invoice_lines = @invoice.lines || []
          render 'new'
        end 
      end
    end
  end
end
#@invoice_payments = InvoicePayment.   joins("INNER JOIN #{Invoice.table_name} on #{Invoice.table_name}.id= #{InvoicePayment.table_name}.invoice_id")           .joins("INNER JOIN #{Project.table_name} on #{Project.table_name}.id= #{Invoice.table_name}.project_id")            .where("#{Project.table_name}.name=?","project-for-payments")
