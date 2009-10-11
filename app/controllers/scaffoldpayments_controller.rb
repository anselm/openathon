class ScaffoldpaymentsController < ApplicationController
  layout "scaffold"
  before_filter :require_admin
  active_scaffold :payments do |config|
    config.label = "Payments"
    config.columns = [:owner_id, :amount, :description, :firstname, :lastname, :matching_company, :email, :phone, :title ]
  end

  def csv
    render :text => Payment.to_csv, :content_type => 'text/csv'
  end


end

