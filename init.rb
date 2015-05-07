require 'redmine'
Rails.configuration.to_prepare do
   require_dependency 'project'
  Project.send(:include, RedminePayments::Decorators::ProjectDecorator)
  
  require_dependency 'invoice'
  Invoice.send(:include, RedminePayments::Decorators::InvoiceDecorator)
  
  require_dependency 'invoice_payments_controller'
  InvoicePaymentsController.send(:include, RedminePayments::Decorators::InvoicePaymentsDecorator)

  require_dependency 'invoices_controller'
  InvoicesController.send(:include, RedminePayments::Decorators::InvoicesDecorator)

  require_dependency 'user'
  User.send(:include, RedminePayments::Decorators::UserDecorator)
  
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
  
  menu :top_menu, :invoice_payments, {:controller => 'invoice_payments', :action => 'index', :project_id => nil}, :caption => "Invoice Payments", :if => Proc.new {
    User.current.allowed_to?({:controller => 'invoice_payments', :action => 'index'}, nil, {:global => true}) && Setting.plugin_redmine_payments[:payment_invoices_show_payment_invoices_in_top_menu ]
  }
  menu :application_menu, :invoice_payments,
                          {:controller => 'invoice_payments', :action => 'index'},
                          :caption => "Invoice Payments",
                          :param => :project_id,
                          :if => Proc.new{
                          User.current.allowed_to?({controller: 'invoice_payments', action: 'index'},
                                          nil, {global: true}) && Setting.plugin_redmine_payments[:payment_invoices_show_payment_in_app_menu]}

  
  menu :project_menu, :copy_invoices, 
                          {:controller => 'copy_invoices', :action => 'index'},
                          :caption => "Copy Invoice", :param => :project_id
  menu :project_menu, :invoice_payments, 
                          {:controller => 'invoice_payments', :action => 'index'},
                          :caption => "Invoice Payments", :param => :project_id

  
  project_module :payments do
    permission :make_payment, {payments: [:index, :generate, :finalize, :register],
      invoice_payments: [:index, :show], copy_invoices: [:index, :edit, :show]
    }
    
    permission :list_and_edit_invoice_payments,  {invoice_payments: [:index, :edit, :show], copy_invoices: [:index], invoices: [:copy]}
  end
  
  settings default: {'payment_invoice_currency' => 'USD', '
      payment_gateway_currency' => 'PKR', 'open_exchange_rate_app_id' => '24505f9c95c7405597f5eb5f43f3ed48'}, 
    :partial => 'settings/payment_settings'
end
