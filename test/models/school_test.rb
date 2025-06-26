require "test_helper"

class SchoolTest < ActiveSupport::TestCase
  def setup
    @school = schools(:harvard)
  end

  test "should be valid" do
    assert @school.valid?
  end

  test "should require name" do
    @school.name = nil
    assert_not @school.valid?
    assert_includes @school.errors[:name], "can't be blank"
  end

  test "should have unique name" do
    duplicate_school = School.new(name: @school.name)
    @school.save
    assert_not duplicate_school.valid?
    assert_includes duplicate_school.errors[:name], "has already been taken"
  end

  test "should have proper associations" do
    assert_respond_to @school, :students
    assert_respond_to @school, :terms
    assert_respond_to @school, :licenses
    assert_respond_to @school, :admin
  end

  test "should destroy dependent records when destroyed" do
    school = schools(:harvard)

    # Harvard has 3 terms and 1 student in the fixtures
    assert_difference "Term.count", -3 do
      assert_difference "Student.count", -1 do
        school.destroy
      end
    end
  end

  test "should have courses through terms" do
    assert_respond_to @school, :courses
  end

  test "admin association should work" do
    school_with_admin = schools(:harvard)
    if school_with_admin.admin_id
      assert_not_nil school_with_admin.admin
      assert school_with_admin.admin.school_admin?
    end
  end
end
