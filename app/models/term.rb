# Represents an academic term/semester at a school, containing multiple courses.
#
# Terms define the enrollment periods and can be purchased as subscriptions
# that grant access to all courses within the term. Terms can have their own
# pricing or derive pricing from the sum of their constituent courses.
#
# License codes are typically associated with specific terms, allowing schools
# to distribute prepaid access for entire term subscriptions.
class Term < ApplicationRecord
  belongs_to :school
  has_many :courses, dependent: :destroy
  has_many :licenses, dependent: :destroy
  has_many :purchases, as: :purchaseable, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :school_id }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :price, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
  validate :end_date_after_start_date

  scope :current_and_upcoming, -> { where("end_date >= ?", Date.current) }

  # Determines if this term is currently active (within the start/end date range)
  def active?
    (start_date..end_date).cover?(Date.current)
  end

  # Calculates the total price of all courses in this term.
  # Used as fallback pricing when the term doesn't have its own price set.
  def courses_total_price
    courses.sum { |course| course.price || 0 }
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date

    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
