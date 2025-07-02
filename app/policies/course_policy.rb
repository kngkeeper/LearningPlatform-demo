class CoursePolicy < ApplicationPolicy
  attr_reader :user, :course

  def initialize(user, course)
    @user = user
    @course = course
  end

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
end
