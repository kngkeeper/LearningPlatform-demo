require "test_helper"

class PlatformAdminRedirectTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @platform_admin = users(:platform_admin)
    @student_user = users(:student_user)
  end

  test "platform admin redirected to dashboard from root path" do
    sign_in @platform_admin
    get root_path
    assert_redirected_to dashboard_path
  end

  test "student user can access courses index" do
    sign_in @student_user
    get root_path
    assert_response :success
  end

  test "platform admin redirected to dashboard after sign in" do
    post user_session_path, params: {
      user: {
        email: @platform_admin.email,
        password: "password123"
      }
    }
    assert_redirected_to dashboard_path
  end

  test "student redirected to courses after sign in" do
    post user_session_path, params: {
      user: {
        email: @student_user.email,
        password: "password123"
      }
    }
    assert_redirected_to root_path
  end
end
