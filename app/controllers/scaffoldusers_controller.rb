class ScaffoldusersController < ApplicationController
  layout "scaffold"
  before_filter :require_admin
  active_scaffold :users do |config|
    config.label = "Users"
    config.columns = [:id, :admin, :email, :firstname, :lastname, :paid, :team_id ]
  end

  def csv
    render :text => User.to_csv, :content_type => 'text/csv'
  end


end

