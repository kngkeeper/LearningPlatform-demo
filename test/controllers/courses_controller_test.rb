require "test_helper"

class CoursesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @school = schools(:harvard)
    @term = terms(:harvard_fall_2025)
    @course = courses(:harvard_cs101)
    @student_user = users(:student_user)
    @student = students(:john_harvard)
    @student_user.student = @student
  end

  test "should get index when logged in as a student" do
    sign_in @student_user
    get courses_url
    assert_response :success
  end

  test "should not get index when not logged in" do
    get courses_url
    assert_redirected_to new_user_session_url
  end

  test "should get show when student has access" do
    sign_in @student_user
    payment_method = @student.payment_methods.create!(method_type: :credit_card, details: { card_number: "4242424242424242", expiry_month: "12", expiry_year: "2028", cvv: "123", cardholder_name: "Test User" }.to_json)
    purchase = @student.purchases.create!(payment_method: payment_method, purchaseable: @course)
    purchase.process!
    get course_url(@course)
    assert_response :success
  end

  test "should redirect when student does not have access" do
    sign_in @student_user
    get course_url(courses(:mit_physics)) # A course the student doesn't have
    assert_redirected_to courses_path
  end
end
