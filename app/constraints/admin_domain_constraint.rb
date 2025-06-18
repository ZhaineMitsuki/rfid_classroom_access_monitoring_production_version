class AdminDomainConstraint
  def matches?(request)
    domains = Rails.application.config_for(:domain).fetch(:admin, [])
    domains.include? request.domain
  end
end