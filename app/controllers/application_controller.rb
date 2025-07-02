class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  include Pundit::Authorization

  # Handle Pundit authorization failures
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  # Redirect to appropriate page after sign in
  def after_sign_in_path_for(resource)
    if resource.platform_admin?
      dashboard_path
    else
      root_path
    end
  end

  private

  def user_not_authorized(exception)
    policy_name = exception.policy.class.to_s.underscore
    flash[:alert] = t "#{policy_name}.#{exception.query}", scope: "pundit", default: :default
    redirect_back(fallback_location: root_path)
  end
end
