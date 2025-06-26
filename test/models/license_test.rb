require "test_helper"

class LicenseTest < ActiveSupport::TestCase
  def setup
    @license = licenses(:harvard_license_active)
    @redeemed_license = licenses(:harvard_license_redeemed)
  end

  test "should be valid" do
    assert @license.valid?
  end

  test "should require code" do
    @license.code = nil
    assert_not @license.valid?
    assert_includes @license.errors[:code], "can't be blank"
  end

  test "should have unique code" do
    duplicate_license = License.new(
      code: @license.code,
      school: schools(:mit),
      term: terms(:mit_fall_2025)
    )

    assert_not duplicate_license.valid?
    assert_includes duplicate_license.errors[:code], "has already been taken"
  end

  test "should belong to school" do
    assert_not_nil @license.school
    assert_equal schools(:harvard), @license.school
  end

  test "should belong to term" do
    assert_not_nil @license.term
    assert_equal terms(:harvard_fall_2025), @license.term
  end

  test "should have status enum" do
    assert_equal 0, License.statuses[:active]
    assert_equal 1, License.statuses[:redeemed]
    assert_equal 2, License.statuses[:expired]
  end

  test "should default to active status" do
    new_license = License.new(
      code: "TEST-CODE",
      school: schools(:harvard),
      term: terms(:harvard_fall_2025)
    )
    assert new_license.active?
  end

  test "status methods should work correctly" do
    assert @license.active?
    assert_not @license.redeemed?
    assert_not @license.expired?

    assert_not @redeemed_license.active?
    assert @redeemed_license.redeemed?
    assert_not @redeemed_license.expired?
  end

  test "should set redeemed_at when status changes to redeemed" do
    @license.redeemed!
    assert_not_nil @license.redeemed_at
    assert @license.redeemed_at <= Time.current
  end

  test "should generate unique codes" do
    code1 = License.generate_code("HARVARD", "2025")
    code2 = License.generate_code("HARVARD", "2025")

    assert_not_equal code1, code2
    assert code1.include?("HARVARD")
    assert code1.include?("2025")
  end

  test "should validate code format" do
    invalid_codes = [ "", "short", "no-school-info" ]
    invalid_codes.each do |code|
      @license.code = code
      assert_not @license.valid?, "#{code} should be invalid"
    end
  end

  test "should not be redeemable if already redeemed" do
    assert_not @redeemed_license.redeemable?
  end

  test "should not be redeemable if expired" do
    expired_license = License.new(
      code: "EXPIRED-CODE",
      status: :expired,
      school: schools(:harvard),
      term: terms(:harvard_fall_2025)
    )
    assert_not expired_license.redeemable?
  end

  test "should be redeemable if active" do
    assert @license.redeemable?
  end

  test "should expire licenses for past terms" do
    past_term = Term.create!(
      name: "Past Term",
      start_date: 6.months.ago,
      end_date: 3.months.ago,
      school: schools(:harvard)
    )

    old_license = License.create!(
      code: "OLD-LICENSE",
      school: schools(:harvard),
      term: past_term,
      status: :active
    )

    License.expire_old_licenses
    old_license.reload
    assert old_license.expired?
  end
end
