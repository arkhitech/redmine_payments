class PaymentMailer < ActionMailer::Base
  layout 'mailer'
  default from: Setting.mail_from
  def self.default_url_options
    Mailer.default_url_options
  end  
  def notify_payment(user,payment)
    @invoice=Invoice.find_by_id(payment.invoice_id)
    @payment=payment
    project=Project.find_by_id(payment.project_id)
    mail(to: user.mail, subject: "Payment has been made for #{project.name} ")
  end
 
end