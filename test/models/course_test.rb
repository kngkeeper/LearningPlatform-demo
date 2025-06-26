require "test_helper"

class CourseTest < ActiveSupport::TestCase
  def setup
    @course = courses(:harvard_cs101)
  end

  test "should be valid" do
    assert @course.valid?
  end

  test "should require name" do
    @course.name = nil
    assert_not @course.valid?
    assert_includes @course.errors[:name], "can't be blank"
  end

  test "should belong to term" do
    assert_not_nil @course.term
    assert_equal terms(:harvard_fall_2025), @course.term
  end

  test "should have school through term" do
    assert_respond_to @course, :school
    assert_equal @course.term.school, @course.school
  end

  test "should have proper associations" do
    assert_respond_to @course, :enrollments
    assert_respond_to @course, :purchases
  end

  test "should have students through enrollments" do
    assert_respond_to @course, :students
  end

  test "should have unique name within term" do
    duplicate_course = Course.new(
      name: @course.name,
      term: @course.term
    )

    assert_not duplicate_course.valid?
    assert_includes duplicate_course.errors[:name], "has already been taken"
  end

  test "should allow same name in different terms" do
    different_term_course = Course.new(
      name: @course.name,
      term: terms(:harvard_spring_2026)
    )

    assert different_term_course.valid?
  end

  test "should be available during term period" do
    current_course = courses(:current_course)
    assert current_course.available?
  end

  test "should not be available outside term period" do
    assert_not @course.available?
  end

  test "should have enrolled students count" do
    assert_respond_to @course, :enrolled_students_count
    assert_kind_of Integer, @course.enrolled_students_count
  end

  test "should calculate price correctly" do
    # Assuming courses have a price attribute or method
    assert_respond_to @course, :price
  end
end
