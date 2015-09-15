module RedminePayments
  module Decorators
    module InvoicePaymentDecorator
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          has_one :payment_transaction_fee , :dependent => :destroy
        end
      end

      module InstanceMethods
        def net_payment
          if self.payment_transaction_fee.present?
            net_amount = self.amount.to_f - self.payment_transaction_fee.fee_amount
          else
            net_amount = nil
          end
          net_amount
        end
        def transaction_fee
          if self.payment_transaction_fee.present?
            fee_amount = self.payment_transaction_fee.fee_amount
          else
            fee_amount = nil
          end
          fee_amount
        end  
         def fee_description
          if self.payment_transaction_fee.present?
            fee_desc = self.payment_transaction_fee.description
          else
            fee_desc = nil
          end
          fee_desc
        end 
      end
    end
  end
end
