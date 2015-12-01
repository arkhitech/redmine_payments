module PaymentsHelper
  def generate_uuid
     SecureRandom.uuid
  end
  def allowed_to_projects(permission)
    if User.current.admin?
      return Project.all
    end
    allowed_projects = []
    projects_by_role = User.current.projects_by_role
    projects_by_role.each_pair do |role, projects|
      if role.allowed_to?(permission)
        allowed_projects = projects
      end
    end
    allowed_projects
  end
  
  
  
end
