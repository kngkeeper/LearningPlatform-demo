class Student < ApplicationRecord
  belongs_to :school
  belongs_to :user
  has_many :enrollments, dependent: :destroy
  has_many :courses, through: :enrollments, source: :enrollable, source_type: "Course"
  has_many :payment_methods, dependent: :destroy
  has_many :purchases, dependent: :destroy

  validates :first_name, presence: true
  validates :last_name, presence: true

  # Delegate email to associated user
  delegate :email, to: :user

  def full_name
    "#{first_name} #{last_name}"
  end

  def has_access_to?(course)
    return false unless course.is_a?(Course)
    return false unless course.school == school

    # Find any active enrollment that grants access to this course
    enrollments.joins(:purchase)
              .where(purchases: { active: true })
              .any? { |enrollment| enrollment.grants_access_to?(course) }
  end
end
