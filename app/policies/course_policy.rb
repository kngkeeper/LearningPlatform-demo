# Enforces authorization rules for course access and enrollment permissions.
#
# This policy implements the business rules around who can view and enroll in courses:
# - Students can only access courses from their own school
# - Platform admins have unrestricted access
# - Enrollment is only allowed for available courses where the student doesn't already have access
# - Access is determined by active purchase records (direct course or term subscription)
class CoursePolicy < ApplicationPolicy
  attr_reader :user, :course

  def initialize(user, course)
    @user = user
    @course = course
  end

  def index?
    user&.student?
  end

  def show?
    return false unless user&.student?

    # Platform admins can view any course
    return true if user.platform_admin?

    # Students can only view courses from their school
    user.student.school == @course.school
  end

  # Determines if the user has access to course content (can view lessons, materials, etc.)
  # Access is granted through either direct course purchase or term subscription
  def access?
    return false unless user.student
    student = user.student

    direct_purchase = Purchase.active.exists?(
      student: student,
      purchaseable: @course
    )

    term_subscription = Purchase.active.exists?(
      student: student,
      purchaseable: @course.term
    )

    direct_purchase || term_subscription
  end

  # Determines if the user can enroll in this course
  # Enrollment is blocked if: already has access, wrong school, or course unavailable
  def enroll?
    return false unless user.student
    student = user.student

    # Can't enroll if already has access
    return false if access?

    # Can only enroll in courses from the same school
    return false unless @course.school == student.school

    # Can only enroll in available courses
    @course.available?
  end

  class Scope < Scope
    # Returns courses visible to the current user based on their role and school affiliation
    def resolve
      if user&.platform_admin?
        scope.all
      elsif user&.student?
        scope.joins(:term).where(terms: { school: user.student.school })
      else
        scope.none
      end
    end
  end
end
