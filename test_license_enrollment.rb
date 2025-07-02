#!/usr/bin/env ruby

# Integration test script for validating the license code enrollment functionality.
#
# This script tests the complete license enrollment workflow including:
# - License payment method creation and validation
# - Term purchase with license codes (allowed)
# - Course purchase with license codes (should be blocked)
# - Business rule enforcement around license usage
#
# Run this script to verify the license enrollment system is working correctly
# after making changes to the purchase/enrollment logic.

require_relative 'config/environment'

puts "=== License Code Enrollment Test ==="
puts ""

# Set up test data
student = Student.first
course = Course.first
term = course&.term
license = License.active.find_by(school: term&.school)

if student && course && term && license
  puts "Found test data:"
  puts "  Student: #{student.full_name}"
  puts "  Course: #{course.name}"
  puts "  Term: #{term.name}"
  puts "  License: #{license.code} (#{license.status})"
  puts ""

  # Test the license enrollment process
  puts "=== Testing License Enrollment Process ==="

  # Create a license payment method (simulating the controller logic)
  payment_method = student.payment_methods.build(
    method_type: "license",
    license: license
  )

  if payment_method.save
    puts "✓ License payment method created successfully"

    # Create purchase for term (this should succeed)
    purchase = student.purchases.build(
      purchaseable: term,
      payment_method: payment_method
    )

    if purchase.valid?
      puts "✓ Purchase validation passed"
      puts "  Purchase for: #{purchase.purchaseable.name}"
      puts "  Payment method: #{purchase.payment_method.method_type}"
      puts "  License code: #{purchase.payment_method.license.code}"
    else
      puts "✗ Purchase validation failed:"
      purchase.errors.full_messages.each do |error|
        puts "    #{error}"
      end
    end

    # Clean up
    payment_method.destroy
  else
    puts "✗ License payment method creation failed:"
    payment_method.errors.full_messages.each do |error|
      puts "    #{error}"
    end
  end

  puts ""

  # Test that course purchases with license fail
  puts "=== Testing Course Purchase Restriction ==="

  payment_method = student.payment_methods.build(
    method_type: "license",
    license: license
  )

  if payment_method.save
    purchase = student.purchases.build(
      purchaseable: course,  # Try to purchase course instead of term
      payment_method: payment_method
    )

    if purchase.valid?
      puts "✗ UNEXPECTED: Course purchase with license was allowed"
    else
      puts "✓ EXPECTED: Course purchase with license was blocked"
      course_error = purchase.errors.full_messages.any? { |msg| msg.include?("Courses cannot be purchased using license codes") }
      if course_error
        puts "  ✓ Correct error message displayed"
      else
        puts "  ✗ Unexpected error messages:"
        purchase.errors.full_messages.each do |error|
          puts "    #{error}"
        end
      end
    end

    payment_method.destroy
  else
    puts "✗ Could not create test license payment method"
  end

else
  puts "Missing test data. Please ensure the database has sample data:"
  puts "  Students: #{Student.count}"
  puts "  Courses: #{Course.count}"
  puts "  Terms: #{Term.count}"
  puts "  Active Licenses: #{License.active.count}"
end

puts ""
puts "=== Test Complete ==="
