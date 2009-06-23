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

  def admin_announcement
    note = Note.find(:first, :conditions => { :kind => "announcement" } )
    note = Note.new(:kind => "announcement", :description => params[:announcement] ) if !note
    note.save
    redirect_to "/admin"
  end

  def admin_message
  end

end
