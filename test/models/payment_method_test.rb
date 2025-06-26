require "test_helper"

class PaymentMethodTest < ActiveSupport::TestCase
  def setup
    @credit_card_payment = payment_methods(:john_credit_card)
    @license_payment = payment_methods(:john_license_payment)
  end

  test "should be valid" do
    assert @credit_card_payment.valid?
    assert @license_payment.valid?
  end

  test "should belong to student" do
    assert_not_nil @credit_card_payment.student
    assert_equal students(:john_harvard), @credit_card_payment.student
  end

  test "should have method_type enum" do
    assert_equal 0, PaymentMethod.method_types[:credit_card]
    assert_equal 1, PaymentMethod.method_types[:license]
  end

  test "credit card payment should have details" do
    assert @credit_card_payment.credit_card?
    assert_not_nil @credit_card_payment.details
    assert_kind_of Hash, JSON.parse(@credit_card_payment.details)
  end

  test "license payment should belong to license" do
    assert @license_payment.license?
    assert_not_nil @license_payment.license
    assert_equal licenses(:harvard_license_redeemed), @license_payment.license
  end

  test "license payment should require license" do
    license_payment = PaymentMethod.new(
      method_type: :license,
      student: students(:john_harvard)
    )

    assert_not license_payment.valid?
    assert_includes license_payment.errors[:license], "must exist"
  end

  test "credit card payment should not require license" do
    credit_payment = PaymentMethod.new(
      method_type: :credit_card,
      student: students(:john_harvard),
      details: '{"card_number": "****9999", "expiry": "12/28"}'
    )

    assert credit_payment.valid?
  end

  test "should validate details format for credit card" do
    @credit_card_payment.details = "invalid json"
    assert_not @credit_card_payment.valid?
    assert_includes @credit_card_payment.errors[:details], "must be valid JSON"
  end

  test "should require details for credit card payments" do
    @credit_card_payment.details = nil
    assert_not @credit_card_payment.valid?
    assert_includes @credit_card_payment.errors[:details], "can't be blank"
  end

  test "should mask sensitive credit card data" do
    details = JSON.parse(@credit_card_payment.details)
    assert details["card_number"].include?("****")
  end

  test "should validate license is redeemable when creating license payment" do
    expired_license = License.create!(
      code: "EXPIRED-TEST",
      status: :expired,
      school: schools(:harvard),
      term: terms(:harvard_fall_2025)
    )

    payment = PaymentMethod.new(
      method_type: :license,
      student: students(:john_harvard),
      license: expired_license
    )

    assert_not payment.valid?
    assert_includes payment.errors[:license], "must be redeemable"
  end

  test "should process credit card payment" do
    assert @credit_card_payment.processable?
    result = @credit_card_payment.process_payment(100.00)
    assert result[:success]
  end

  test "should process license payment" do
    assert @license_payment.processable?
    result = @license_payment.process_payment(0) # License payments are typically free
    assert result[:success]
  end
end
