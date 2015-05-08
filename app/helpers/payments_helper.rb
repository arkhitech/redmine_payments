module PaymentsHelper
  def generate_uuid
     SecureRandom.uuid
  end
def eligible_for_email_users
    group_ids = Setting.plugin_redmine_leaves['eligible_for_email_notification']
    if group_ids.blank?
      @eligible_users=User.active.all
#     @eligible_users.order('users.name ASC').all.map{ |c| [c.name, c.id] }
      @eligible_users.sort_by{|e| e[:firstname]}
    else
      @eligible_users= User.active.joins(:groups).
        where("#{User.table_name_prefix}groups_users#{User.table_name_suffix}.id" => 
          group_ids).group("#{User.table_name}.id")
      @eligible_users.sort_by{|e| e[:firstname]}
      
      end
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
