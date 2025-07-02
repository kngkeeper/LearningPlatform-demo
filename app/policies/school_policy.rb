class SchoolPolicy < ApplicationPolicy
  def index?
    user&.platform_admin?
  end

  def show?
    return true if user&.platform_admin?
    return false unless user&.student?

    # Students can only view their own school
    user.student.school == record
  end

  def create?
    user&.platform_admin?
  end

  def update?
    return true if user&.platform_admin?

    # School admins can update their own school
    user&.school_admin? && user.managed_school == record
  end

  def destroy?
    user&.platform_admin?
  end

  class Scope < Scope
    def resolve
      if user&.platform_admin?
        scope.all
      elsif user&.student?
        scope.where(id: user.student.school_id)
      elsif user&.school_admin?
        scope.where(id: user.managed_school_id)
      else
        scope.none
      end
    end
  end
end
