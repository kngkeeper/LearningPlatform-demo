# Tracks student access to courses and terms through purchase transactions.
#
# Enrollments are created automatically when purchases are processed and serve
# as the authoritative record of what content a student can access. The enrollment
# system supports two access patterns:
#
# - Direct course enrollment: Student purchased a specific course
# - Term enrollment: Student purchased a term subscription, granting access to all courses in that term
#
# Access is determined by both the enrollment record and the active status of
# the underlying purchase. Deactivated purchases effectively revoke access.
class Enrollment < ApplicationRecord
  belongs_to :student
  belongs_to :purchase
  belongs_to :enrollable, polymorphic: true

  validates :student, presence: true
  validates :purchase, presence: true
  validates :enrollable, presence: true
  validate :student_matches_purchase_student
  validate :enrollable_matches_purchase_for_direct_enrollments
  validate :no_duplicate_enrollments

  scope :active, -> { joins(:purchase).where(purchases: { active: true }) }
  scope :for_school, ->(school) { joins(:student).where(students: { school: school }) }
  scope :by_payment_type, ->(type) { joins(purchase: :payment_method).where(payment_methods: { method_type: type }) }

  # Returns true if this enrollment provides active access.
  # Access is contingent on the underlying purchase being active.
  def active?
    purchase&.active?
  end

  def enrollment_date
    created_at&.to_date
  end

  # Determines if this enrollment grants access to a specific course.
  #
  # For direct course enrollments: only grants access to the enrolled course
  # For term enrollments: grants access to all courses within the enrolled term
  def grants_access_to?(course)
    return false unless course.is_a?(Course)

    case enrollable
    when Course
      enrollable == course
    when Term
      enrollable.courses.include?(course)
    else
      false
    end
  end

  private

  def student_matches_purchase_student
    return unless student && purchase

    unless student == purchase.student
      errors.add(:student, "must match the purchase student")
    end
  end

  # Ensures enrollment type matches the purchase type for data integrity
  def enrollable_matches_purchase_for_direct_enrollments
    return unless enrollable && purchase&.purchaseable

    # For direct course purchases, enrollable should match purchaseable
    if purchase.purchaseable.is_a?(Course) && enrollable != purchase.purchaseable
      errors.add(:enrollable, "must match purchase for direct enrollments")
    end

    # For term purchases, enrollable should be the term itself
    if purchase.purchaseable.is_a?(Term) && enrollable != purchase.purchaseable
      errors.add(:enrollable, "must match the purchased term for term enrollments")
    end
  end

  # Prevents duplicate enrollments for the same purchase and content
  def no_duplicate_enrollments
    return unless student && enrollable && purchase

    # Prevent duplicate enrollments for the same purchase
    existing = Enrollment.where(student: student, enrollable: enrollable, purchase: purchase)
                        .where.not(id: id)

    if existing.exists?
      errors.add(:student, "is already enrolled in this item through this purchase")
    end
  end
end
