class CoursesController < ApplicationController
  before_action :authenticate_user!
  before_action :redirect_platform_admins_to_dashboard
  before_action :ensure_student
  before_action :set_course, only: [ :show ]

  def index
    @courses = available_courses_for_enrollment
  end

  def show
    authorize @course, :access?
  rescue Pundit::NotAuthorizedError
    redirect_to courses_path, alert: "You don't have access to this course."
  end

  private

  def available_courses_for_enrollment
    return Course.none unless current_user.student

    student = current_user.student
    Course.available_for_enrollment(student.school)
  end

  def ensure_student
    redirect_to new_user_session_path unless current_user&.student?
  end

  def set_course
    @course = Course.find(params[:id])
  end

  def redirect_platform_admins_to_dashboard
    redirect_to dashboard_path if current_user&.platform_admin?
  end
end
