require "test_helper"

class EnrollmentTest < ActiveSupport::TestCase
  def setup
    @course_enrollment = enrollments(:john_cs101_enrollment)
    @term_enrollment = enrollments(:john_term_enrollment)
  end

  test "should be valid" do
    assert @course_enrollment.valid?
    assert @term_enrollment.valid?
  end

  test "should belong to student" do
    assert_not_nil @course_enrollment.student
    assert_equal students(:john_harvard), @course_enrollment.student
  end

  test "should belong to purchase" do
    assert_not_nil @course_enrollment.purchase
    assert_equal purchases(:john_course_purchase), @course_enrollment.purchase
  end

  test "should belong to enrollable polymorphically" do
    # Course enrollment
    assert_not_nil @course_enrollment.enrollable
    assert_equal courses(:harvard_cs101), @course_enrollment.enrollable
    assert_equal "Course", @course_enrollment.enrollable_type

    # Term enrollment
    assert_not_nil @term_enrollment.enrollable
    assert_equal terms(:harvard_fall_2025), @term_enrollment.enrollable
    assert_equal "Term", @term_enrollment.enrollable_type
  end

  test "should validate student matches purchase student" do
    different_student = students(:jane_mit)
    @course_enrollment.student = different_student

    assert_not @course_enrollment.valid?
    assert_includes @course_enrollment.errors[:student], "must match the purchase student"
  end

  test "should validate enrollable matches purchase purchaseable for direct enrollments" do
    different_course = courses(:harvard_cs102)
    @course_enrollment.enrollable = different_course

    assert_not @course_enrollment.valid?
    assert_includes @course_enrollment.errors[:enrollable], "must match purchase for direct enrollments"
  end

  test "should allow term enrollment when purchase is for term" do
    # Create a new term purchase that doesn't already have an enrollment
    spring_term = terms(:harvard_spring_2026)
    payment_method = payment_methods(:john_credit_card)

    # Create a purchase for the spring term
    spring_purchase = Purchase.create!(
      student: students(:john_harvard),
      payment_method: payment_method,
      purchaseable: spring_term,
      active: true
    )

    # Now try to create an enrollment for this term purchase
    term_purchase_enrollment = Enrollment.new(
      student: students(:john_harvard),
      purchase: spring_purchase,
      enrollable: spring_term
    )

    assert term_purchase_enrollment.valid?, "Enrollment should be valid but got errors: #{term_purchase_enrollment.errors.full_messages}"
  end

  test "should not allow term enrollment when enrollable doesn't match purchased term" do
    different_term = terms(:harvard_spring_2026)
    term_purchase_enrollment = Enrollment.new(
      student: students(:john_harvard),
      purchase: purchases(:john_term_purchase), # This purchase is for harvard_fall_2025 term
      enrollable: different_term
    )

    assert_not term_purchase_enrollment.valid?
    assert_includes term_purchase_enrollment.errors[:enrollable], "must match the purchased term for term enrollments"
  end

  test "should prevent duplicate enrollments" do
    duplicate_enrollment = Enrollment.new(
      student: @course_enrollment.student,
      purchase: @course_enrollment.purchase,
      enrollable: @course_enrollment.enrollable
    )

    assert_not duplicate_enrollment.valid?
    assert_includes duplicate_enrollment.errors[:student], "is already enrolled in this item through this purchase"
  end

  test "should be active when purchase is active" do
    assert @course_enrollment.active?

    @course_enrollment.purchase.update(active: false)
    assert_not @course_enrollment.active?
  end

  test "should scope active enrollments" do
    active_enrollments = Enrollment.active
    assert_includes active_enrollments, @course_enrollment

    @course_enrollment.purchase.update(active: false)
    active_enrollments = Enrollment.active
    assert_not_includes active_enrollments, @course_enrollment
  end

  test "should scope by school" do
    harvard_enrollments = Enrollment.for_school(schools(:harvard))
    assert_includes harvard_enrollments, @course_enrollment

    mit_enrollments = Enrollment.for_school(schools(:mit))
    assert_not_includes mit_enrollments, @course_enrollment
  end

  test "should scope by payment method type" do
    credit_card_enrollments = Enrollment.by_payment_type(:credit_card)
    assert_includes credit_card_enrollments, @course_enrollment

    license_enrollments = Enrollment.by_payment_type(:license)
    assert_includes license_enrollments, @term_enrollment
  end

  test "should get enrollment date" do
    assert_not_nil @course_enrollment.enrollment_date
    assert_equal @course_enrollment.created_at.to_date, @course_enrollment.enrollment_date
  end

  test "should check if enrollment grants access to specific course" do
    # Direct course enrollment
    assert @course_enrollment.grants_access_to?(courses(:harvard_cs101))
    assert_not @course_enrollment.grants_access_to?(courses(:harvard_cs102))

    # Term enrollment should grant access to all courses in the term
    harvard_cs101 = courses(:harvard_cs101) # In harvard_fall_2025
    assert @term_enrollment.grants_access_to?(harvard_cs101)

    harvard_cs102 = courses(:harvard_cs102) # In harvard_spring_2026
    assert_not @term_enrollment.grants_access_to?(harvard_cs102)
  end
end
