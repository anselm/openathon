class ScaffoldController < ApplicationController
  layout "scaffold"

  before_filter :require_admin

  active_scaffold :team do |config|
    config.columns = [:active,:bookings,:description,:name,:users ]
  end

end

