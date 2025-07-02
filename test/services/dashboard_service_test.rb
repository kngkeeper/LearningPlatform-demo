require "test_helper"

class DashboardServiceTest < ActiveSupport::TestCase
  setup do
    @service = DashboardService.new
    @school = schools(:harvard)
  end

  test "platform_analytics returns expected structure" do
    result = @service.platform_analytics

    assert result.key?(:schools)
    assert result.key?(:overview)
    assert result[:schools].is_a?(Array)
    assert result[:overview].is_a?(Hash)
  end

  test "platform_analytics overview contains required metrics" do
    result = @service.platform_analytics
    overview = result[:overview]

    assert overview.key?(:total_schools)
    assert overview.key?(:total_students)
    assert overview.key?(:total_courses)
    assert overview.key?(:total_enrollments)
    assert overview.key?(:credit_card_enrollments)
    assert overview.key?(:license_enrollments)
  end

  test "school_analytics returns expected structure" do
    result = @service.school_analytics(@school)

    assert result.key?(:school)
    assert result.key?(:terms)
    assert result.key?(:courses)
    assert result.key?(:payment_methods)
    assert_equal @school, result[:school]
    assert result[:terms].is_a?(Array)
    assert result[:courses].is_a?(Array)
    assert result[:payment_methods].is_a?(Hash)
  end

  test "school_analytics payment_methods contains required keys" do
    result = @service.school_analytics(@school)
    payment_methods = result[:payment_methods]

    assert payment_methods.key?(:credit_card)
    assert payment_methods.key?(:license)
    assert payment_methods.key?(:total)
  end

  test "term statistics include enrollment counts" do
    result = @service.school_analytics(@school)

    result[:terms].each do |term_data|
      assert term_data.key?(:term)
      assert term_data.key?(:courses_count)
      assert term_data.key?(:students_enrolled)
      assert term_data.key?(:credit_card_enrollments)
      assert term_data.key?(:license_enrollments)
    end
  end

  test "course statistics include enrollment breakdowns" do
    result = @service.school_analytics(@school)

    result[:courses].each do |course_data|
      assert course_data.key?(:course)
      assert course_data.key?(:students_enrolled)
      assert course_data.key?(:direct_enrollments)
      assert course_data.key?(:term_enrollments)
      assert course_data.key?(:credit_card_enrollments)
      assert course_data.key?(:license_enrollments)
    end
  end
end
