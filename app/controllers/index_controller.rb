class IndexController < ApplicationController
  layout 'normal', :only => :admin

  def index
  end

  def news
  end

  def donate
  end

  def admin
    # TODO GUARDS HERE
  end

end
