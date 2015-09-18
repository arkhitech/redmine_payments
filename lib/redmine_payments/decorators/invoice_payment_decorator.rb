module RedminePayments
  module Decorators
    module InvoicePaymentDecorator
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          has_one :payment_transaction_fee , :dependent => :destroy
          accepts_nested_attributes_for :payment_transaction_fee, reject_if: lambda {|fee| fee[:fee_amount].blank? && fee[:fee_percentage].blank?}
        end
      end

      module InstanceMethods
        def net_payment
          if self.payment_transaction_fee.present?
            
            net_amount = self.amount.to_f - self.transaction_fee
              
          else
            net_amount = nil
          end
          net_amount
        end
        def transaction_fee
          if self.payment_transaction_fee.present?
            fee_amount = (BigDecimal(self.amount) * BigDecimal('%.2f'%self.payment_transaction_fee.fee_percentage) / 100) - 
              BigDecimal(self.payment_transaction_fee.fee_amount)
            fee_amount = BigDecimal('%.2f'%fee_amount)
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
