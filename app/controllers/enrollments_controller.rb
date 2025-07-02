# Handles the course enrollment process, supporting multiple payment methods and enrollment types.
#
# This controller orchestrates the complex enrollment workflow which includes:
# - Authorization checks to ensure enrollment eligibility
# - Support for three enrollment types: individual course, term subscription, license redemption
# - Payment processing for credit cards and license validation
# - Creation of purchase and enrollment records upon successful payment
#
# The enrollment process enforces business rules around payment methods and ensures
# data integrity across the purchase-enrollment relationship.
class EnrollmentsController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_student
  before_action :set_course

  def new
    # Use policy to check if enrollment is allowed
    authorize @course, :enroll?

    @enrollment_options = build_enrollment_options
  rescue Pundit::NotAuthorizedError
    if current_user.student.has_access_to?(@course)
      redirect_to @course, notice: "You already have access to this course."
    elsif @course.school != current_user.student.school
      redirect_to courses_path, alert: "You can only enroll in courses from your school."
    elsif !@course.available?
      redirect_to @course, alert: "This course is not available for enrollment."
    else
      redirect_to @course, alert: "You cannot enroll in this course at this time."
    end
  end

  # Processes enrollment based on the selected enrollment type and payment method
  def create
    @enrollment_options = build_enrollment_options

    # Access enrollment_type directly from params (not through strong parameters)
    enrollment_type = params[:enrollment_type]

    case enrollment_type
    when "course"
      result = enroll_in_course
    when "term"
      result = enroll_in_term
    when "license"
      result = enroll_with_license
    else
      result = { success: false, error: "Invalid enrollment type" }
    end

    if result[:success]
      redirect_to @course, notice: "Successfully enrolled! You now have access to the course."
    else
      flash.now[:alert] = result[:error] || "Enrollment failed. Please try again."
      render :new, status: :unprocessable_entity
    end
  end

  private

  def payment_params
    params.permit(:card_number, :expiry_month, :expiry_year, :cvv, :cardholder_name, :license_code)
  end

  def set_course
    @course = Course.find(params[:course_id])
  end

  def ensure_student
    redirect_to new_user_session_path unless current_user&.student?
  end

  # Builds the enrollment options data structure for the frontend
  def build_enrollment_options
    {
      course: {
        name: @course.name,
        price: @course.price || 0,
        available: true
      },
      term: {
        name: @course.term.name,
        price: @course.term.price || @course.term.courses_total_price,
        available: true,
        courses_count: @course.term.courses.count
      }
    }
  end

  def enroll_in_course
    process_enrollment(@course, payment_params)
  end

  def enroll_in_term
    process_enrollment(@course.term, payment_params)
  end

  def enroll_with_license
    process_license_enrollment(@course.term, params[:license_code])
  end

  # Processes credit card enrollment for courses or terms
  def process_enrollment(purchaseable, payment_params)
    student = current_user.student

    # Create payment method
    payment_method = student.payment_methods.build(
      method_type: "credit_card",
      details: {
        card_number: payment_params[:card_number],
        expiry_month: payment_params[:expiry_month],
        expiry_year: payment_params[:expiry_year],
        cvv: payment_params[:cvv],
        cardholder_name: payment_params[:cardholder_name]
      }.to_json
    )

    unless payment_method.save
      error_messages = payment_method.errors.full_messages.join(", ")
      return { success: false, error: "Payment information error: #{error_messages}" }
    end

    # Create purchase
    purchase = student.purchases.build(
      purchaseable: purchaseable,
      payment_method: payment_method
    )

    if purchase.process!
      { success: true }
    else
      error_messages = purchase.errors.full_messages.join(", ")
      { success: false, error: "Payment processing failed: #{error_messages}" }
    end
  rescue StandardError => e
    Rails.logger.error "Enrollment error: #{e.message}"
    { success: false, error: "An error occurred during enrollment. Please try again." }
  end

  # Processes license code enrollment specifically for term subscriptions
  def process_license_enrollment(term, license_code)
    return { success: false, error: "License code is required" } if license_code.blank?

    student = current_user.student

    # Find the license
    license = License.find_by(code: license_code.strip.upcase)
    unless license
      return { success: false, error: "Invalid license code" }
    end

    # Validate license is redeemable (active)
    unless license.redeemable?
      status_message = case license.status
      when "expired"
        "expired"
      when "redeemed"
        "already used"
      else
        "not valid"
      end
      return { success: false, error: "License code is #{status_message}" }
    end

    # Validate license school matches term school
    unless license.school == term.school
      return { success: false, error: "License code is not valid for this school" }
    end

    # Create license payment method
    payment_method = student.payment_methods.build(
      method_type: "license",
      license: license
    )

    unless payment_method.save
      error_messages = payment_method.errors.full_messages.join(", ")
      return { success: false, error: "License validation error: #{error_messages}" }
    end

    # Create purchase
    purchase = student.purchases.build(
      purchaseable: term,
      payment_method: payment_method
    )

    if purchase.process!
      # Mark license as redeemed
      license.update!(status: :redeemed)
      { success: true }
    else
      error_messages = purchase.errors.full_messages.join(", ")
      { success: false, error: "Enrollment failed: #{error_messages}" }
    end
  rescue StandardError => e
    Rails.logger.error "License enrollment error: #{e.message}"
    { success: false, error: "An error occurred during enrollment. Please try again." }
  end
end
