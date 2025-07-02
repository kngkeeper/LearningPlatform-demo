class PaymentMethod < ApplicationRecord
  enum :method_type, { credit_card: 0, license: 1 }

  belongs_to :student
  belongs_to :license, optional: true
  has_many :purchases, dependent: :destroy

  validates :method_type, presence: true
  validates :details, presence: true, if: :credit_card?
  validate :valid_json, if: -> { credit_card? && details.present? }
  validate :valid_credit_card_details, if: -> { credit_card? && details.present? }
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
