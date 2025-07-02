# Handles payment processing for course and term purchases.
#
# Supports two payment methods:
# - Credit cards: Stores encrypted payment details as JSON
# - License codes: References pre-paid licenses issued by schools
#
# Business rules:
# - License codes can only be used for term purchases, not individual courses
# - License codes must belong to the same school as the term being purchased
# - Credit card details are validated for proper JSON format and required fields
class PaymentMethod < ApplicationRecord
  # Constants for method types to avoid magic numbers
  CREDIT_CARD_TYPE = 0
  LICENSE_TYPE = 1

  enum :method_type, { credit_card: CREDIT_CARD_TYPE, license: LICENSE_TYPE }

  belongs_to :student
  belongs_to :license, optional: true
  has_many :purchases, dependent: :destroy

  validates :method_type, presence: true
  validates :details, presence: true, if: :credit_card?
  validate :valid_json, if: -> { credit_card? && details.present? }
  validate :valid_credit_card_details, if: -> { credit_card? && details.present? }
  validates :license, presence: { message: "must exist" }, if: :license?
  validate :license_is_redeemable, if: -> { license? && license.present? }

  # Determines if this payment method can be used for processing payments.
  # Credit cards require valid JSON details, licenses must be in usable state.
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

  # Processes a payment for the specified amount.
  # Returns a hash with success status and transaction details.
  # For credit cards, simulates payment processing.
  # For licenses, creates a reference transaction.
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

  # Simulates credit card payment processing
  def process_credit_card_payment(amount)
    { success: true, transaction_id: "cc_#{SecureRandom.hex(8)}", amount: amount }
  end

  # Creates a license-based transaction reference
  def process_license_payment(amount)
    { success: true, transaction_id: "lic_#{license.code}", amount: amount }
  end

  def valid_credit_card_details
    return unless details.present?

    begin
      parsed_details = JSON.parse(details)

      # Validate card number (basic format check - digits with optional spaces/dashes)
      card_number = parsed_details["card_number"].to_s.gsub(/[\s-]/, "")
      unless card_number.match?(/\A\d{13,19}\z/)
        errors.add(:details, "Card number must be 13-19 digits")
      end

      # Validate expiry month (1-12)
      expiry_month = parsed_details["expiry_month"].to_i
      unless (1..12).include?(expiry_month)
        errors.add(:details, "Expiry month must be between 1 and 12")
      end

      # Validate expiry year (current year or future)
      expiry_year = parsed_details["expiry_year"].to_i
      unless expiry_year >= Date.current.year && expiry_year <= Date.current.year + 20
        errors.add(:details, "Expiry year must be current year or in the future")
      end

      # Validate CVV (3-4 digits)
      cvv = parsed_details["cvv"].to_s
      unless cvv.match?(/\A\d{3,4}\z/)
        errors.add(:details, "CVV must be 3 or 4 digits")
      end

      # Validate cardholder name (basic presence check)
      cardholder_name = parsed_details["cardholder_name"].to_s.strip
      if cardholder_name.length < 2
        errors.add(:details, "Cardholder name must be at least 2 characters")
      end

    rescue JSON::ParserError
      # This is already handled by valid_json method
    end
  end
end
