class PaymentMailer < ActionMailer::Base
  layout 'mailer'
  default from: Setting.mail_from
  def self.default_url_options
    Mailer.default_url_options
  end  
  def notify_absentee(user)
    
    mail(to: user.mail, subject: "payment email")
  end
end