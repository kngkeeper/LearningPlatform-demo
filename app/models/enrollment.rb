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

  def active?
    purchase&.active?
  end

  def enrollment_date
    created_at&.to_date
  end

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

  def enrollable_matches_purchase_for_direct_enrollments
    return unless enrollable && purchase&.purchaseable
    return unless enrollable.is_a?(Course)

    # For direct course purchases, enrollable should match purchaseable
    if purchase.purchaseable.is_a?(Course) && enrollable != purchase.purchaseable
      errors.add(:enrollable, "must match purchase for direct enrollments")
    end

    # For term purchases, enrollable course should be in the purchased term
    if purchase.purchaseable.is_a?(Term) && enrollable.term != purchase.purchaseable
      errors.add(:enrollable, "must be in the purchased term")
    end
  end

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
