class ApplicationController < ActionController::Base
  set_current_tenant_through_filter
  prepend_before_filter :set_tenant

  protect_from_forgery
  before_filter :set_locale
  before_filter :update_current_user, :if => :current_user

  def set_tenant
    if request.subdomain.blank? && request.host != 'localhost'
      redirect_to request.url.sub(request.domain, "www.#{request.domain}")
    end
    ActionMailer::Base.default_url_options[:host] = request.host
    @domain = Domain.find_or_create_by_name(request.host)
    set_current_tenant(@domain)
  end

  def set_locale
    I18n.locale = http_accept_language.preferred_language_from(%w[en fr es])
  end

  def update_current_user
    # Includes updated_at update
    current_user.update_attribute :locale, I18n.locale
  end

  rescue_from CanCan::AccessDenied do |exception|
    flash[:error] = exception.message
    redirect_to root_url
  end
end
