class ProfessorDomainConstraint
  def matches?(request)
    domains = Rails.application.config_for(:domain).fetch(:professor, [])
    domains.include? request.domain.downcase
  end
end