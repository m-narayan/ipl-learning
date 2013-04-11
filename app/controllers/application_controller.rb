class ApplicationController < ActionController::Base
  protect_from_forgery
   before_filter :load_subdomain
  include UrlHelper
  include ActiveMerchant::Billing::Integrations::ActionViewHelper
  rescue_from CanCan::AccessDenied do |exception|
    redirect_to root_path, :alert => exception.message
  end

  def after_sign_in_path_for(resource_or_scope)
    if current_user.has_role? :admin 
     users_path
   elsif  params[:course_id] == "0" ||  params[:course_id] == nil 
    edit_user_registration_path    
  else
    @course = Course.find(params[:course_id])
    new_comment_path(:commentable=>params[:course_id],:commentable_type=>"course")
  end    
end
def load_subdomain
  if(request.subdomains[0] != nil)
    @subdomain = self.request.subdomains[0] || 'local'
    
  else
    @subdomain = "common"
  end
  end
end
