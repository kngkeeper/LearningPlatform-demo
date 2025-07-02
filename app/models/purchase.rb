# Represents a completed purchase transaction that grants access to courses or terms.
#
# Purchases are polymorphic and can be for:
# - Individual courses: Direct access to a specific course
# - Terms: Access to all courses within an academic term
#
# Business rules enforced:
# - Payment method must belong to the same student making the purchase
# - Purchaseable items must be available (not from expired terms)
# - License codes cannot be used for individual course purchases
# - License codes must be from the same school as the term being purchased
#
# The purchase process creates corresponding enrollment records that track
# student access permissions.
class Purchase < ApplicationRecord
  belongs_to :student
  belongs_to :payment_method
  belongs_to :purchaseable, polymorphic: true
  has_many :enrollments, dependent: :destroy

  validates :active, inclusion: { in: [ true, false ] }
  validates :purchaseable, presence: true
  validate :payment_method_belongs_to_same_student
  validate :purchaseable_is_available
  validate :license_from_same_school_for_term_purchases
  validate :courses_not_purchasable_with_license

  after_initialize :set_default_active

  scope :active, -> { where(active: true) }

  # Calculates the total price for this purchase.
  # For courses: uses the course price
  # For terms: uses term price if set, otherwise sums all course prices in the term
  def total_price
    case purchaseable
    when Course
      purchaseable.price || 0
    when Term
      # Use term price if set, otherwise fall back to sum of course prices
      purchaseable.price || purchaseable.courses_total_price
    else
      0
    end
  end

  # Processes the purchase by charging the payment method and creating enrollments.
  # Returns true if successful, false otherwise.
  # On success, creates enrollment records that grant access to the purchased content.
  def process!
    return false unless payment_method.processable?

    # Save the purchase first
    save! unless persisted?

    result = payment_method.process_payment(total_price)

    if result[:success]
      create_enrollments!
      true
    else
      false
    end
  end

  # Deactivates this purchase, effectively revoking access to the purchased content.
  # Enrollments remain but become inactive due to the purchase status.
  def deactivate!
    update_columns(active: false)
    # Note: Enrollments don't have an active column - their active status
    # is determined by the purchase's active status
  end

  private

  def set_default_active
    self.active = true if active.nil?
  end

  def payment_method_belongs_to_same_student
    return unless payment_method && student

    unless payment_method.student == student
      errors.add(:payment_method, "must belong to the same student")
    end
  end

  # Validates that the item being purchased is still available.
  # Items become unavailable once their associated term has ended.
  def purchaseable_is_available
    return unless purchaseable

    case purchaseable
    when Course
      # Courses are not available if their term has ended
      if purchaseable.term.end_date < Date.current
        errors.add(:purchaseable, "is not available for purchase")
      end
    when Term
      # Terms are not available if they have ended
      if purchaseable.end_date < Date.current
        errors.add(:purchaseable, "is not available for purchase")
      end
    end
  end

  # Enforces business rule: license codes must be from the same school as the term
  def license_from_same_school_for_term_purchases
    return unless purchaseable.is_a?(Term) && payment_method&.license?

    license = payment_method.license
    return unless license

    unless license.school == purchaseable.school
      errors.add(:base, "License must be from the same school as the term")
    end
  end

  # Enforces business rule: license codes cannot be used for individual course purchases
  def courses_not_purchasable_with_license
    return unless purchaseable.is_a?(Course) && payment_method&.license?

    errors.add(:base, "Courses cannot be purchased using license codes. Please purchase the term instead.")
  end

  # Creates enrollment records based on the type of purchase.
  # Course purchases create a single enrollment for that course.
  # Term purchases create an enrollment for the term, granting access to all courses within it.
  def create_enrollments!
    case purchaseable
    when Course
      # Direct course purchase - create enrollment for the specific course
      enrollments.find_or_create_by!(
        student: student,
        enrollable: purchaseable
      )
    when Term
      # Term purchase - create a single enrollment for the term
      # This gives access to all courses in the term via the grants_access_to? logic
      enrollments.find_or_create_by!(
        student: student,
        enrollable: purchaseable
      )
    end
  end
end
