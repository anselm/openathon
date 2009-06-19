class IndexController < ApplicationController

  layout 'home'  # :only => :admin

  def privacy
    render :layout => 'twocolumn'
  end

  def tos
    render :layout => 'twocolumn'
  end

  def index
  end

  def news
    render :layout => 'twocolumn'
  end

  def donate
  end

  def about
    render :layout => 'twocolumn'
  end

  def admin
    # TODO GUARDS HERE
  end

end
