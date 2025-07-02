require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @school = schools(:harvard)
  end

  test "should create user and student" do
    assert_difference([ "User.count", "Student.count" ], 1) do
      post user_registration_url, params: { user: { email: "test@example.com", password: "password", password_confirmation: "password", first_name: "Test", last_name: "User", school_id: @school.id } }
    end
    assert_redirected_to root_url
  end

  test "should not create user without school" do
    assert_no_difference([ "User.count", "Student.count" ]) do
      post user_registration_url, params: { user: { email: "test@example.com", password: "password", password_confirmation: "password", first_name: "Test", last_name: "User", school_id: nil } }
    end
    assert_response :unprocessable_entity
  end
end
