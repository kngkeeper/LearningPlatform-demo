require "test_helper"

class DashboardControllerBasicTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @platform_admin = users(:platform_admin)
    @student_user = users(:student_user)
    @school = schools(:harvard)
  end

  test "platform admin can access dashboard index" do
    sign_in @platform_admin
    get dashboard_path
    assert_response :success
  end

  test "student user cannot access dashboard index" do
    sign_in @student_user
    get dashboard_path
    assert_redirected_to root_path
  end

  test "unauthenticated user redirected to sign in" do
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test "platform admin can access school dashboard" do
    sign_in @platform_admin
    get dashboard_school_path(@school)
    assert_response :success
  end

  test "student cannot access school dashboard" do
    sign_in @student_user
    get dashboard_school_path(@school)
    assert_redirected_to root_path
  end
end
