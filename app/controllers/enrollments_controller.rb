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

  def create
    @enrollment_options = build_enrollment_options

    # Access enrollment_type directly from params (not through strong parameters)
    enrollment_type = params[:enrollment_type]

    case enrollment_type
    when "course"
      result = enroll_in_course
    when "term"
      result = enroll_in_term
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
    params.permit(:card_number, :expiry_month, :expiry_year, :cvv, :cardholder_name)
  end

  def set_course
    @course = Course.find(params[:course_id])
  end

  def ensure_student
    redirect_to new_user_session_path unless current_user&.student?
  end

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
end
