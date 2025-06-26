class PaymentMethod < ApplicationRecord
  enum :method_type, { credit_card: 0, license: 1 }

  belongs_to :student
  belongs_to :license, optional: true
  has_many :purchases, dependent: :destroy

  validates :method_type, presence: true
  validates :details, presence: true, if: :credit_card?
  validate :valid_json, if: -> { credit_card? && details.present? }
  validates :license, presence: { message: "must exist" }, if: :license?
  validate :license_is_redeemable, if: -> { license? && license.present? }

  def processable?
    case method_type
    when "credit_card"
      details.present? && valid_json_format?
    when "license"
      license&.usable?
    else
      false
    end
  end

  def process_payment(amount)
    return { success: false, error: "Not processable" } unless processable?

    case method_type
    when "credit_card"
      process_credit_card_payment(amount)
    when "license"
      process_license_payment(amount)
    end
  end

  private

  def valid_json
    return unless details.present?

    begin
      JSON.parse(details)
    rescue JSON::ParserError
      errors.add(:details, "must be valid JSON")
    end
  end

  def valid_json_format?
    return false unless details.present?

    begin
      JSON.parse(details)
      true
    rescue JSON::ParserError
      false
    end
  end

  def license_is_redeemable
    unless license.usable?
      errors.add(:license, "must be redeemable")
    end
  end

  def process_credit_card_payment(amount)
    # Simulate credit card processing
    { success: true, transaction_id: "cc_#{SecureRandom.hex(8)}", amount: amount }
  end

  def process_license_payment(amount)
    # License payments are typically processed differently
    { success: true, transaction_id: "lic_#{license.code}", amount: amount }
  end
end
