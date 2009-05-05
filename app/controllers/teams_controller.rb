class TeamsController < ApplicationController

  # for these methods there MUST be a team in mind
  before_filter :get_team, :only => [:show,
                                     :edit,
                                     :update,
                                     :create,
                                     :destroy
                                    ]

  # for these methods there MUST be a member logged in
  before_filter :verify_member, :only => [:new,
                                          :create,
                                          :invite,
                                          :invite_confirm,
                                          :invite_do,
                                          :join
                                         ]

  # for these methods the logged in member MUST be owner
  before_filter :verify_powers, :only => [:edit,
                                          :update,
                                          :destroy
                                         ]

private

  def get_team
    @team = Team.find(params[:id])
    return @team != nil
  end

  def verify_member
    if current_user == nil
      flash[:notice] = "Please signup to create or join a team"
      redirect_to "/signup"
      return false
    end
    return true
  end

  def verify_powers
    if current_user == nil
      flash[:notice] = "Please signin to edit your team"
      redirect_to "/signin"
      return false
    end
    if @team == nil || !@team.is_owner?(current_user)
      flash[:notice] = "this is not your team - you cannot change it"
      return false
    end
  end

public


  def index
    @teams = Team.all
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @teams }
    end
  end

  def show
    @member_list = User.find(:all, :conditions => ["team_id = ?", @team.id])
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @team }
    end
  end

  def new
    @team = Team.new
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @team }
    end
  end

  def edit
  end

  def create
    @team = Team.new(params[:team])
    respond_to do |format|
      if @team.save
        if !@team.set_captain(current_user)
          raise "No user logged in"
        end
        flash[:notice] = 'Team was successfully created.'
        format.html { redirect_to(@team) }
        format.xml  { render :xml => @team, :status => :created, :location => @team }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @team.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @team.update_attributes(params[:team])
        flash[:notice] = 'Team was successfully updated.'
        format.html { redirect_to(@team) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @team.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @team.destroy
    respond_to do |format|
      format.html { redirect_to(teams_url) }
      format.xml  { head :ok }
    end
  end

  ########################################################################
  # Openathon specific work
  ########################################################################

  def calendar
  end

  def search
  end

  def invite
    if flash[:body]
      @body = flash[:body]
    else
      @body = "Hey Friend, I'm doing this awesome thing!\n\n"
              "Go to http://openathon.makerlab.com and support me!\n\nThanks!"
    end
    if flash[:recipients]
      @recipients = flash[:recipients]
    else
      @recipients = Array.new
    end
    @team = Team.find(current_user.team_id)
  end

  def invite_confirm
    @team = Team.find(current_user.team_id)
    email_blob = params[:email_blob]
    @recipients = email_blob.split
    @error_array = Array.new
    @recipients.each do |email|
      begin
        TMail::Address.parse(email)
      rescue
        @error_array << email
      end
    end
    flash[:body] = params[:user_message]
    flash[:recipients] = @recipients
    if @error_array.length > 0
      flash[:email_errors] = @error_array
      redirect_to :action => :invite
    end
    @body = params[:user_message]
  end

  def invite_do
    recipients = flash[:recipients]
    body = flash[:body]
    recipients.each do |email|
      InviteMailer.deliver_invite(current_user, email, body)
    end
    flash[:notice] = 'Invitations sent!'
    redirect_to(Team.find(current_user.team_id))
  end

  def join
    if !current_user
      redirect_to :controller => :users, :action => :signup
    elsif @team.is_member(current_user)
      flash[:notice] = "You're already a member of this team."
    elsif current_user.team_id == nil
      flash[:notice] = "You're now a member of this team."
      current_user.team_id = @team.id
      current_user.save
    else # If you are switching teams, since a user can only be on one team. (ugly)
      flash[:notice] = "You're now a member of this team."
      current_user.team_id = @team.id
      current_user.save
    end    
  end

end

