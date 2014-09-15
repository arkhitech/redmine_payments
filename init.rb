require 'redmine'
Redmine::Plugin.register :redmine_payments do
  name 'Redmine Payments plugin'
  author 'Arkhitech'
  description 'This is a plugin for Redmine which incorporates payment of invoices through credit cards'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'https://github.com/arkhitech'
  
  menu :project_menu, :redmine_payments, { controller: 'payments', action: 'index' },
    caption: :caption_redmine_payments, :param => :project_id
  
  project_module :payments do
    permission :make_payment, payments: [:index]
  end
  
  settings :default => {'empty' => true}, :partial => 'settings/payment_settings'
end
