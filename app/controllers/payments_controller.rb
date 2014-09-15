class PaymentsController < ApplicationController
  unloadable
  
  before_filter :find_project

  def index
    return deny_access unless User.current.allowed_to?(:view_invoices, @project) ||
      User.current.admin?
    @invoices = Invoice.where("project_id IN (?)", @project.self_and_descendants.map(&:id))
  end
  
  def new    
    invoice = Invoice.where(project_id: @project.id, id: params[:invoice_id]).first
    @payment = Payment.new(amount: invoice.amount.to_f.to_s, customer_name: 'Demo Merchant', 
      invoice: invoice, project: @project)
  end
  
  def create
    @payment = Payment.new(params[:payment])
    if @payment.save
      redirect_to project_payments_path
    else
      render 'new'
    end
  end
  
  private
  
  def find_project
    @project = Project.find(params[:project_id])
  end
end
