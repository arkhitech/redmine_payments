module RedminePayments
  module Decorators
    module InvoicePaymentDecorator
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
          has_one :payment_transaction_fee , dependent: :destroy
          accepts_nested_attributes_for :payment_transaction_fee , reject_if: lambda {|fee| (fee[:fee_amount].blank? || fee[:fee_amount].to_f == 0.0) && fee[:fee_percentage].blank?}
          attr_accessible :payment_transaction_fee_attributes

          validates :exchange_rate, presence: true

          attr_accessor :transaction_reference
          attr_accessor :bank_reference

          before_create do
            if self.transaction_reference.present?
              self.description = "Transaction reference: #{self.transaction_reference} #{self.description}"
            end
            if self.bank_reference.present?
              self.description = "Bank reference: #{self.bank_reference} #{self.description}"      
            end

            if !self.converted_amount.present?
              if self.exchange_rate.present?
                self.converted_amount = self.amount * self.exchange_rate
              end
            end

          end
          
        end
        
      end

      module InstanceMethods
        def net_payment
          net_amount = self.amount.to_f          
          net_amount -= self.transaction_fee if self.payment_transaction_fee.present?
          
          net_amount
        end
        def transaction_fee
          if self.payment_transaction_fee.present?
            if self.payment_transaction_fee.fee_percentage
              fee_percentage_amount = (BigDecimal(self.amount) * BigDecimal('%.2f'%self.payment_transaction_fee.fee_percentage) / 100)
            else
              fee_percentage_amount = 0
            end
            fee_amount = fee_percentage_amount + BigDecimal(self.payment_transaction_fee.fee_amount || 0)
            fee_amount = BigDecimal('%.2f'%fee_amount)
            
            ############## calculation for tax over transaction fee percentage #################
            
            tax_fee_percentage_amount = 0.00
            fixed_tax_amount_over_percentage_fee = 0.00
            if self.payment_transaction_fee.fee_tax_percentage
              tax_fee_percentage_amount = ((fee_percentage_amount * BigDecimal('%.2f'%self.payment_transaction_fee.fee_tax_percentage)) / 100) 
            end
            if self.payment_transaction_fee.fee_tax_amount
              fixed_tax_amount_over_percentage_fee = BigDecimal(self.payment_transaction_fee.fee_tax_amount)
            end
            total_tax_amount_over_percentage_fee_amount = tax_fee_percentage_amount + fixed_tax_amount_over_percentage_fee
            
            ################ Sum of tax amount over transaction fee percentage and fee ##########
            
            fee_amount = fee_amount + total_tax_amount_over_percentage_fee_amount
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
