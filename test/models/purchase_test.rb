require "test_helper"

class PurchaseTest < ActiveSupport::TestCase
  def setup
    @course_purchase = purchases(:john_course_purchase)
    @term_purchase = purchases(:john_term_purchase)
  end

  test "should be valid" do
    assert @course_purchase.valid?
    assert @term_purchase.valid?
  end

  test "should belong to student" do
    assert_not_nil @course_purchase.student
    assert_equal students(:john_harvard), @course_purchase.student
  end

  test "should belong to payment_method" do
    assert_not_nil @course_purchase.payment_method
    assert_equal payment_methods(:john_credit_card), @course_purchase.payment_method
  end

  test "should belong to purchaseable polymorphically" do
    assert_not_nil @course_purchase.purchaseable
    assert_equal courses(:harvard_cs101), @course_purchase.purchaseable
    assert_equal "Course", @course_purchase.purchaseable_type

    assert_not_nil @term_purchase.purchaseable
    assert_equal terms(:harvard_fall_2025), @term_purchase.purchaseable
    assert_equal "Term", @term_purchase.purchaseable_type
  end

  test "should default to active" do
    new_purchase = Purchase.new(
      student: students(:john_harvard),
      payment_method: payment_methods(:john_credit_card),
      purchaseable: courses(:harvard_cs102)
    )
    assert new_purchase.active
  end

  test "should validate payment method belongs to same student" do
    different_student_payment = payment_methods(:jane_credit_card)
    @course_purchase.payment_method = different_student_payment

    assert_not @course_purchase.valid?
    assert_includes @course_purchase.errors[:payment_method], "must belong to the same student"
  end

  test "should validate purchaseable is available" do
    unavailable_course = Course.create!(
      name: "Unavailable Course",
      term: Term.create!(
        name: "Past Term",
        start_date: 1.year.ago,
        end_date: 6.months.ago,
        school: schools(:harvard)
      )
    )

    purchase = Purchase.new(
      student: students(:john_harvard),
      payment_method: payment_methods(:john_credit_card),
      purchaseable: unavailable_course
    )

    assert_not purchase.valid?
    assert_includes purchase.errors[:purchaseable], "is not available for purchase"
  end

  test "should process purchase successfully" do
    new_purchase = Purchase.new(
      student: students(:john_harvard),
      payment_method: payment_methods(:john_credit_card),
      purchaseable: courses(:harvard_cs102)
    )

    assert new_purchase.process!
    assert new_purchase.persisted?
    assert new_purchase.active?
  end

  test "should create enrollment after successful purchase" do
    new_purchase = Purchase.new(
      student: students(:john_harvard),
      payment_method: payment_methods(:john_credit_card),
      purchaseable: courses(:harvard_cs102)
    )

    assert_difference "Enrollment.count", 1 do
      new_purchase.process!
    end

    enrollment = Enrollment.last
    assert_equal new_purchase.student, enrollment.student
    assert_equal new_purchase, enrollment.purchase
    assert_equal new_purchase.purchaseable, enrollment.enrollable
  end

  test "should calculate total price" do
    assert_respond_to @course_purchase, :total_price
    assert_kind_of Numeric, @course_purchase.total_price
  end

  test "should validate license is from same school for term purchases" do
    mit_license = licenses(:mit_license)
    mit_payment = PaymentMethod.create!(
      method_type: :license,
      student: students(:john_harvard), # Harvard student
      license: mit_license
    )

    purchase = Purchase.new(
      student: students(:john_harvard),
      payment_method: mit_payment,
      purchaseable: terms(:harvard_fall_2025) # Harvard term
    )

    assert_not purchase.valid?
    assert_includes purchase.errors[:base], "License must be from the same school as the term"
  end

  test "should prevent course purchases with license codes" do
    license_payment = payment_methods(:john_license_payment)

    purchase = Purchase.new(
      student: students(:john_harvard),
      payment_method: license_payment,
      purchaseable: courses(:harvard_cs101) # Course purchase
    )

    assert_not purchase.valid?
    assert_includes purchase.errors[:base], "Courses cannot be purchased using license codes. Please purchase the term instead."
  end

  test "should allow term purchases with license codes" do
    license_payment = payment_methods(:john_license_payment)

    purchase = Purchase.new(
      student: students(:john_harvard),
      payment_method: license_payment,
      purchaseable: terms(:harvard_fall_2025) # Term purchase
    )

    # This should be valid (assuming other validations pass)
    # Note: The license validation may fail if license is not redeemable,
    # but the course restriction should not be triggered
    purchase.valid?
    assert_not_includes purchase.errors[:base], "Courses cannot be purchased using license codes. Please purchase the term instead."
  end

  test "should deactivate purchase" do
    @course_purchase.deactivate!
    assert_not @course_purchase.active?
  end

  test "should scope active purchases" do
    active_purchases = Purchase.active
    assert_includes active_purchases, @course_purchase

    @course_purchase.update(active: false)
    active_purchases = Purchase.active
    assert_not_includes active_purchases, @course_purchase
  end

  test "should have proper associations" do
    assert_respond_to @course_purchase, :enrollments
  end
end
