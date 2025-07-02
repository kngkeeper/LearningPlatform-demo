require "test_helper"

class TermTest < ActiveSupport::TestCase
  def setup
    @term = terms(:harvard_fall_2025)
    @current_term = terms(:current_term)
  end

  test "should be valid" do
    assert @term.valid?
  end

  test "should require name" do
    @term.name = nil
    assert_not @term.valid?
    assert_includes @term.errors[:name], "can't be blank"
  end

  test "should require start_date" do
    @term.start_date = nil
    assert_not @term.valid?
    assert_includes @term.errors[:start_date], "can't be blank"
  end

  test "should require end_date" do
    @term.end_date = nil
    assert_not @term.valid?
    assert_includes @term.errors[:end_date], "can't be blank"
  end

  test "should belong to school" do
    assert_not_nil @term.school
    assert_equal schools(:harvard), @term.school
  end

  test "should have proper associations" do
    assert_respond_to @term, :courses
    assert_respond_to @term, :licenses
    assert_respond_to @term, :school
  end

  test "active? should return true for current terms" do
    assert @current_term.active?
  end

  test "active? should return false for future terms" do
    assert_not @term.active?
  end

  test "active? should return false for past terms" do
    past_term = Term.new(
      name: "Past Term",
      start_date: 2.months.ago,
      end_date: 1.month.ago,
      school: schools(:harvard)
    )
    assert_not past_term.active?
  end

  test "end_date should be after start_date" do
    @term.end_date = @term.start_date - 1.day
    assert_not @term.valid?
    assert_includes @term.errors[:end_date], "must be after start date"
  end

  test "should destroy dependent courses when destroyed" do
    term_with_courses = terms(:harvard_fall_2025)

    assert_difference "Course.count", -1 do
      term_with_courses.destroy
    end
  end

  test "should have unique name within school" do
    duplicate_term = Term.new(
      name: @term.name,
      start_date: Date.current + 1.year,
      end_date: Date.current + 1.year + 3.months,
      school: @term.school
    )

    assert_not duplicate_term.valid?
    assert_includes duplicate_term.errors[:name], "has already been taken"
  end

  test "should allow same name in different schools" do
    mit_term = Term.new(
      name: "Fall 2025", # Same as harvard term
      start_date: Date.current + 2.years, # Different dates to avoid conflict with existing mit_fall_2025
      end_date: Date.current + 2.years + 3.months,
      school: schools(:stanford) # Use stanford instead of mit to avoid fixture conflict
    )

    assert mit_term.valid?
  end

  test "should validate price" do
    @term.price = -10
    assert_not @term.valid?
    assert_includes @term.errors[:price], "must be greater than or equal to 0"

    @term.price = 499.99
    assert @term.valid?
  end

  test "should calculate total price of all courses" do
    assert_respond_to @term, :courses_total_price

    # Use integer prices to avoid floating point issues in tests
    @term.courses.create(name: "Test Course 1", price: 100)
    @term.courses.create(name: "Test Course 2", price: 150)

    expected_total = 250
    assert_equal expected_total, @term.courses_total_price
  end
end
