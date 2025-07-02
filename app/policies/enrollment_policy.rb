class EnrollmentPolicy < ApplicationPolicy
  def create?
    return false unless user&.student

    # Students can only create enrollments for themselves
    user.student == record.student if record.respond_to?(:student)
  end

  def new?
    create?
  end

  def show?
    return false unless user&.student

    # Students can only view their own enrollments
    user.student == record.student
  end

  def index?
    return false unless user&.student
    true # Students can view their own enrollments list
  end

  class Scope < Scope
    def resolve
      if user&.student
        scope.where(student: user.student)
      elsif user&.platform_admin?
        scope.all
      else
        scope.none
      end
    end
  end
end
