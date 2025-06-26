class Term < ApplicationRecord
  belongs_to :school
  has_many :courses, dependent: :destroy
  has_many :licenses, dependent: :destroy
  has_many :purchases, as: :purchaseable, dependent: :destroy

  validates :name, presence: true
  validates :name, uniqueness: { scope: :school_id }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  scope :current_and_upcoming, -> { where("end_date >= ?", Date.current) }

  def active?
    (start_date..end_date).cover?(Date.current)
  end

  private

  def end_date_after_start_date
    return unless start_date && end_date

    if end_date <= start_date
      errors.add(:end_date, "must be after start date")
    end
  end
end
