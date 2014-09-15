require 'redmine'
Rails.configuration.to_prepare do
  Moneyjs.configure do |config|
    config.only_currencies = ['PKR','USD']
  end    
end

Redmine::Plugin.register :redmine_payments do
  name 'Redmine Payments plugin'
  author 'Arkhitech'
  description 'This is a plugin for Redmine which incorporates payment of invoices through credit cards'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'https://github.com/arkhitech'
  
  menu :project_menu, :redmine_payments, { controller: 'payments', action: 'index' },
    caption: :caption_redmine_payments, param: :project_id
  
  project_module :payments do
    permission :make_payment, payments: [:index]
  end
  
  settings default: {'payment_invoice_currency' => 'USD', '
      payment_gateway_currency' => 'PKR', 'open_exchange_rate_app_id' => '24505f9c95c7405597f5eb5f43f3ed48'}, 
    :partial => 'settings/payment_settings'
end
