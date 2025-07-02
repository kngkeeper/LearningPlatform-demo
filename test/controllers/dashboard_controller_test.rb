require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @platform_admin = users(:platform_admin)
    @student_user = users(:student_user)
    @school = schools(:harvard)
  end

  test "should redirect non-platform-admin users from dashboard index" do
    sign_in @student_user
    get dashboard_path
    assert_redirected_to root_path
    assert_equal "Access denied.", flash[:alert]
  end

  test "should allow platform admin to access dashboard index" do
    sign_in @platform_admin
    get dashboard_path
    assert_response :success
    assert_select "h1", text: "Platform Dashboard"
  end

  test "should redirect non-platform-admin users from school dashboard" do
    sign_in @student_user
    get dashboard_school_path(@school)
    assert_redirected_to root_path
    assert_equal "Access denied.", flash[:alert]
  end

  test "should allow platform admin to access school dashboard" do
    sign_in @platform_admin
    get dashboard_school_path(@school)
    assert_response :success
    assert_select "h1", text: "#{@school.name} Dashboard"
  end

  test "should redirect unauthenticated users" do
    get dashboard_path
    assert_redirected_to new_user_session_path
  end

  test "dashboard index should display platform overview data" do
    sign_in @platform_admin
    get dashboard_path

    assert_response :success
    assert_select ".stats-grid"
    assert_select ".stat-card", count: 4
    assert_select ".payment-stats"
    assert_select ".schools-section"
  end

  test "school dashboard should display school-specific data" do
    sign_in @platform_admin
    get dashboard_school_path(@school)

    assert_response :success
    assert_select ".payment-overview"
    assert_select ".terms-section"
    assert_select ".courses-section"
  end
end
