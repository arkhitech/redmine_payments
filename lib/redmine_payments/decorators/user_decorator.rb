module RedminePayments
  module Decorators
    module UserDecorator
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
        end
      end

      module InstanceMethods
        def to_option
          [self.name, self.id]
        end       
      end
    end
  end
end
#@invoice_payments = InvoicePayment.   joins("INNER JOIN #{Invoice.table_name} on #{Invoice.table_name}.id= #{InvoicePayment.table_name}.invoice_id")           .joins("INNER JOIN #{Project.table_name} on #{Project.table_name}.id= #{Invoice.table_name}.project_id")            .where("#{Project.table_name}.name=?","project-for-payments")
