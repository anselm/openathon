class IndexController < ApplicationController

  layout 'twocolumn'

  before_filter :require_admin , :only => :admin

  def index
    if (current_user && current_user.team_id).is_a? Numeric 
      redirect_to :controller => :teams, :action => :show, :id => current_user.team_id
      return
    end
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
    note = Note.new(:kind => "announcement" ) if !note
    note.description = params[:announcement]
    note.save
    redirect_to "/admin"
  end

  def admin_message
  end

end
