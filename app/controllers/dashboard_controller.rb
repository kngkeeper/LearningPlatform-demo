class DashboardController < ApplicationController
  before_action :authenticate_user!
  before_action :authorize_platform_admin!

  def index
    @dashboard_data = DashboardService.new.platform_analytics
  end

  def school
    @school = School.find(params[:school_id])
    @dashboard_data = DashboardService.new.school_analytics(@school)
  end

  private

  def authorize_platform_admin!
    redirect_to root_path, alert: "Access denied." unless current_user&.platform_admin?
  end
end
