class Payment < ActiveRecord::Base
  attr_accessor :cc_number, :expiry_date, :cvv2, :invoice_id
  
  belongs_to :invoice
  
  def project
    invoice.project
  end
  
  def order_name
    invoice.invoice_number
  end
  
  def order_info
    invoice.invoice_subject
  end
  def order_id
    invoice_id
  end
end
