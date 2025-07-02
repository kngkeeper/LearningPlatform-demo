class DashboardPolicy < ApplicationPolicy
  def index?
    user&.platform_admin?
  end

  def school?
    user&.platform_admin?
  end

  class Scope < Scope
    def resolve
      if user&.platform_admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
