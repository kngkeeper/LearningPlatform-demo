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

  def usable?
    status == "active" || status == "redeemed"
  end

  def redeemable?
    status == "active"
  end

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
    self.redeemed_at = Time.current if redeemed_at.blank?
  end
end
