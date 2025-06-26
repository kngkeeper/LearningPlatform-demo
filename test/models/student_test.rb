require "test_helper"

class StudentTest < ActiveSupport::TestCase
  def setup
    @student = students(:john_harvard)
  end

  test "should be valid" do
    assert @student.valid?
  end

  test "should require first_name" do
    @student.first_name = nil
    assert_not @student.valid?
    assert_includes @student.errors[:first_name], "can't be blank"
  end

  test "should require last_name" do
    @student.last_name = nil
    assert_not @student.valid?
    assert_includes @student.errors[:last_name], "can't be blank"
  end

  test "should belong to school" do
    assert_not_nil @student.school
    assert_equal schools(:harvard), @student.school
  end

  test "should belong to user" do
    assert_not_nil @student.user
    assert_equal users(:student_user), @student.user
  end

  test "should delegate email to user" do
    assert_equal @student.user.email, @student.email
  end

  test "should have proper associations" do
    assert_respond_to @student, :enrollments
    assert_respond_to @student, :payment_methods
    assert_respond_to @student, :purchases
  end

  test "should have courses through enrollments" do
    assert_respond_to @student, :courses
  end

  test "full_name method should return concatenated name" do
    expected_name = "#{@student.first_name} #{@student.last_name}"
    assert_equal expected_name, @student.full_name
  end

  test "should have access to course through direct purchase" do
    course = courses(:harvard_cs101)
    assert @student.has_access_to?(course)
  end

  test "should have access to course through term purchase" do
    # This will require implementing the access control logic
    course = courses(:harvard_cs101) # This course belongs to harvard_fall_2025

    # Student should have access to all courses in a term they purchased
    assert @student.has_access_to?(course)
  end

  test "should not have access to courses from other schools" do
    mit_course = courses(:mit_physics)
    assert_not @student.has_access_to?(mit_course)
  end

  test "should only access active purchases" do
    # Test that when all relevant purchases are inactive, student loses access
    course = courses(:harvard_cs102) # This course is only in spring 2026, not in the purchased fall 2025 term

    # Create a direct purchase for this course
    payment_method = payment_methods(:john_credit_card)
    purchase = Purchase.create!(
      active: true,
      student: @student,
      payment_method: payment_method,
      purchaseable: course
    )

    # Process the purchase to create enrollment
    purchase.process!

    # Verify student has access
    assert @student.has_access_to?(course)

    # Deactivate the purchase
    purchase.update(active: false)

    # Now student should not have access since this was the only way to access this course
    assert_not @student.has_access_to?(course)
  end
end
