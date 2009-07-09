class ScaffoldpaymentsController < ApplicationController
  layout "scaffold"
  before_filter :require_admin
  active_scaffold :payments do |config|
    config.label = "Payments"
    config.columns = [:id, :amount, :description, :firstname, :lastname, :matching_company, :email, :phone ]
  end
end

