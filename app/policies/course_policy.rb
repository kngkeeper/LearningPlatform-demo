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
      purchasable: @course
    )

    term_subscription = Purchase.active.exists?(
      student: student,
      purchasable: @course.term
    )

    direct_purchase || term_subscription
  end
end
