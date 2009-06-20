class IndexController < ApplicationController

  layout 'twocolumn'

  before_filter :require_admin , :only => :admin

  def index
    render :layout => 'home'
  end

  def privacy
  end

  def tos
  end

  def news
  end

  def donate
  end

  def about
  end

  def admin
    @teams = Team.all
    @users = User.all
  end

end
