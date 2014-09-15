class PaymentsController < ApplicationController
  unloadable
  
  before_filter :find_project

  def index
    return deny_access unless User.current.allowed_to?(:view_invoices, @project) ||
      User.current.admin?
    @invoices = Invoice.where("project_id IN (?)", @project.self_and_descendants.map(&:id))
  end
  
  private
  
  def find_project
    @project = Project.find(params[:project_id])
  end
end
