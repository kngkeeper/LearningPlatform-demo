class Course < ApplicationRecord
  belongs_to :term
  has_many :purchases, as: :purchaseable, dependent: :destroy
  has_many :enrollments, as: :enrollable, dependent: :destroy
  has_many :students, through: :enrollments

  validates :name, presence: true
  validates :name, uniqueness: { scope: :term_id }
  validates :price, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  scope :available_for_enrollment, ->(school) {
    joins(:term)
      .where(terms: { school: school })
      .where("terms.end_date >= ?", Date.current)
      .includes(:term)
      .order("terms.start_date ASC, courses.name ASC")
  }

  delegate :school, to: :term

  def available?
    term&.end_date >= Date.current
  end

  def enrolled_students_count
    students.count
  end
end
