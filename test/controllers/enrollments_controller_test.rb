require "test_helper"

class EnrollmentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @school = schools(:harvard)
    @term = terms(:harvard_fall_2025)
    @course = courses(:harvard_cs101)
    @student_user = users(:student_user)
    @student = students(:john_harvard)
    @student_user.student = @student
  end

  test "should get new when enrollment is allowed" do
    sign_in @student_user
    get new_course_enrollment_url(courses(:harvard_cs102)) # A course the student is not enrolled in
    assert_response :success
  end

  test "should redirect to course page if already enrolled" do
    sign_in @student_user
    payment_method = @student.payment_methods.create!(method_type: :credit_card, details: { card_number: "4242424242424242", expiry_month: "12", expiry_year: "2028", cvv: "123", cardholder_name: "Test User" }.to_json)
    purchase = @student.purchases.create!(payment_method: payment_method, purchaseable: @course)
    purchase.process!
    get new_course_enrollment_url(@course)
    assert_redirected_to @course
  end

  test "should create enrollment for a course" do
    sign_in @student_user
    assert_difference("Enrollment.count") do
      post course_enrollments_url(courses(:harvard_cs102)), params: {
        enrollment_type: "course",
        card_number: "4242424242424242",
        expiry_month: "12",
        expiry_year: "2028",
        cvv: "123",
        cardholder_name: "Test Student"
      }
    end
    assert_redirected_to course_url(courses(:harvard_cs102))
  end

  test "should create enrollment for a term" do
    sign_in @student_user
    term_courses_count = terms(:harvard_spring_2026).courses.count
    assert_difference("Enrollment.count", term_courses_count) do
      post course_enrollments_url(courses(:harvard_cs102)), params: {
        enrollment_type: "term",
        card_number: "4242424242424242",
        expiry_month: "12",
        expiry_year: "2028",
        cvv: "123",
        cardholder_name: "Test Student"
      }
    end
    assert_redirected_to course_url(courses(:harvard_cs102))
  end

  test "should create enrollment with valid license code" do
    sign_in @student_user
    license = licenses(:harvard_license_active)

    assert_difference("Enrollment.count", 1) do
      post course_enrollments_url(@course), params: {
        enrollment_type: "license",
        license_code: license.code
      }
    end

    # Verify license was marked as redeemed
    license.reload
    assert_equal "redeemed", license.status

    assert_redirected_to course_url(@course)
  end

  test "should reject invalid license code" do
    sign_in @student_user

    assert_no_difference("Enrollment.count") do
      post course_enrollments_url(@course), params: {
        enrollment_type: "license",
        license_code: "INVALID-CODE"
      }
    end

    assert_response :unprocessable_entity
  end

  test "should reject license code from different school" do
    sign_in @student_user
    mit_license = licenses(:mit_license)

    assert_no_difference("Enrollment.count") do
      post course_enrollments_url(@course), params: {
        enrollment_type: "license",
        license_code: mit_license.code
      }
    end

    assert_response :unprocessable_entity
  end

  test "should reject already redeemed license code" do
    sign_in @student_user
    license = licenses(:harvard_license_redeemed)

    assert_no_difference("Enrollment.count") do
      post course_enrollments_url(@course), params: {
        enrollment_type: "license",
        license_code: license.code
      }
    end

    assert_response :unprocessable_entity
  end
end
