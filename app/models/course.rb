# Represents a course offered within a specific academic term at a school.
#
# Courses can be purchased individually or as part of a term subscription.
# Access control is enforced through the enrollment system - students must
# purchase either the specific course or the entire term to gain access.
class Course < ApplicationRecord
  belongs_to :term
  has_many :purchases, as: :purchaseable, dependent: :destroy
  has_many :enrollments, as: :enrollable, dependent: :destroy
  has_many :students, through: :enrollments

  validates :name, presence: true
  validates :name, uniqueness: { scope: :term_id }
  validates :price, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  # Returns courses available for enrollment by students from a specific school.
  # Only includes courses from active/future terms within the school.
  scope :available_for_enrollment, ->(school) {
    joins(:term)
      .where(terms: { school: school })
      .where("terms.end_date >= ?", Date.current)
      .includes(:term)
      .order("terms.start_date ASC, courses.name ASC")
  }

  delegate :school, to: :term

  # Determines if this course is currently available for new enrollments.
  # Courses become unavailable once their term has ended.
  def available?
    term&.end_date >= Date.current
  end

  def enrolled_students_count
    students.count
  end
end
