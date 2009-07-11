class ScaffoldusersController < ApplicationController
  layout "scaffold"
  before_filter :require_admin
  active_scaffold :users do |config|
    config.label = "Users"
    config.columns = [:admin, :email, :firstname, :lastname, :paid ]
  end

  def csv
    render :text => User.to_csv, :content_type => 'text/csv'
  end


end

