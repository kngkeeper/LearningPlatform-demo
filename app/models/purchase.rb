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

  def license_from_same_school_for_term_purchases
    return unless purchaseable.is_a?(Term) && payment_method&.license?

    license = payment_method.license
    return unless license

    unless license.school == purchaseable.school
      errors.add(:base, "License must be from the same school as the term")
    end
  end

  def courses_not_purchasable_with_license
    return unless purchaseable.is_a?(Course) && payment_method&.license?

    errors.add(:base, "Courses cannot be purchased using license codes. Please purchase the term instead.")
  end

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
