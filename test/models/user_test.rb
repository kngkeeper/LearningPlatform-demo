require "test_helper"

class UserTest < ActiveSupport::TestCase
  def setup
    @user = users(:student_user)
    @admin = users(:admin_user)
    @platform_admin = users(:platform_admin)
  end

  test "should be valid" do
    assert @user.valid?
  end

  test "should require email" do
    @user.email = nil
    assert_not @user.valid?
    assert_includes @user.errors[:email], "can't be blank"
  end

  test "should require unique email" do
    duplicate_user = @user.dup
    duplicate_user.email = @user.email.upcase
    @user.save
    assert_not duplicate_user.valid?
    assert_includes duplicate_user.errors[:email], "has already been taken"
  end

  test "should have valid email format" do
    invalid_emails = %w[user@foo,com user_at_foo.org example.user@foo. foo@bar_baz.com foo@bar+baz.com]
    invalid_emails.each do |invalid_email|
      @user.email = invalid_email
      assert_not @user.valid?, "#{invalid_email.inspect} should be invalid"
      assert_includes @user.errors[:email], "is invalid"
    end
  end

  test "should have role enum" do
    assert_equal 0, User.roles[:student]
    assert_equal 1, User.roles[:school_admin]
    assert_equal 2, User.roles[:platform_admin]
  end

  test "should default to student role" do
    new_user = User.new(email: "test@example.com", password: "password123")
    assert new_user.student?
  end

  test "should have proper associations" do
    # Test student association
    student_user = users(:student_user)
    assert_respond_to student_user, :student
    assert_respond_to student_user, :school

    # Test admin association
    admin_user = users(:admin_user)
    assert_respond_to admin_user, :managed_school
  end

  test "student role methods work correctly" do
    assert @user.student?
    assert_not @user.school_admin?
    assert_not @user.platform_admin?
  end

  test "school_admin role methods work correctly" do
    assert_not @admin.student?
    assert @admin.school_admin?
    assert_not @admin.platform_admin?
  end

  test "platform_admin role methods work correctly" do
    assert_not @platform_admin.student?
    assert_not @platform_admin.school_admin?
    assert @platform_admin.platform_admin?
  end

  test "should destroy dependent student when user is destroyed" do
    user_with_student = users(:student_user)

    assert_difference "Student.count", -1 do
      user_with_student.destroy
    end
  end
end
