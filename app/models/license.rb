# Represents pre-paid access codes issued by schools for term enrollment.
#
# License codes provide an alternative payment method that allows schools to
# distribute prepaid access to their students. Each license can be redeemed
# once for a full term subscription.
#
# Lifecycle:
# - active: Available for redemption
# - redeemed: Used by a student, cannot be reused
# - expired: Past the term end date, no longer usable
#
# License codes are automatically generated with school and year prefixes
# for easy identification and administration.
class License < ApplicationRecord
  enum :status, { active: 0, redeemed: 1, expired: 2 }

  belongs_to :school
  belongs_to :term, optional: true
  has_many :payment_methods, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :code, format: { with: /\A[A-Z0-9\-]+\z/, message: "must contain only uppercase letters, numbers, and dashes" }

  before_validation :generate_code, on: :create, if: -> { code.blank? }
  before_update :set_redeemed_at, if: -> { status_changed? && redeemed? }
  after_initialize :set_default_status

  scope :for_school, ->(school) { where(school: school) }

  def active?
    status == "active"
  end

  # Determines if this license can still be used for payments.
  # Both active and redeemed licenses are considered usable for existing payment methods.
  def usable?
    status == "active" || status == "redeemed"
  end

  # Determines if this license can be redeemed for a new purchase.
  # Only active licenses can be redeemed.
  def redeemable?
    status == "active"
  end

  # Generates a unique license code with optional school and year prefixes.
  # When prefixes are provided, format is: SCHOOL-YEAR-XXX
  # Otherwise uses format: XXXX-XXXX-XXXX
  def self.generate_code(school_prefix = nil, year_prefix = nil)
    if school_prefix && year_prefix
      loop do
        code = "#{school_prefix}-#{year_prefix}-#{SecureRandom.alphanumeric(3).upcase}"
        break code unless exists?(code: code)
      end
    else
      loop do
        code = "#{SecureRandom.alphanumeric(4).upcase}-#{SecureRandom.alphanumeric(4).upcase}-#{SecureRandom.alphanumeric(4).upcase}"
        break code unless exists?(code: code)
      end
    end
  end

  # Bulk operation to expire licenses from terms that have ended.
  # Should be run periodically to maintain data integrity.
  def self.expire_old_licenses
    joins(:term).where("terms.end_date < ?", Date.current).update_all(status: :expired)
  end

  private

  def set_default_status
    self.status ||= :active
  end

  def generate_code
    self.code = self.class.generate_code
  end

  def set_redeemed_at
    self.redeemed_at = Time.current if redeemed? && redeemed_at.blank?
  end
end
