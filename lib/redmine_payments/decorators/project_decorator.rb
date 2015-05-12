module RedminePayments
  module Decorators
    module ProjectDecorator
      def self.included(base)
        base.send(:include, InstanceMethods)
        
        base.class_eval do
        end
      end

      module InstanceMethods
        def generate_token
          begin
            self.token = SecureRandom.uuid
          end while self.class.exists?(token: token)
          self.save!
          self.token
        end
         def to_option
          [self.name, self.id]
        end         
      end
    end
  end
end
