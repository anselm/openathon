class TeamsController < ApplicationController

  layout 'normal'

  # for these methods there MUST be a team in mind
  before_filter :get_team, :only => [:show,
                                     :edit,
                                     :update,
                                     :destroy,
                                     :invite,
                                     :sponsor
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

  before_filter :verify_new_team, :only => [:new]

private

  def get_team
    @team = Team.find(params[:id])
    return @team != nil
  end

  def verify_new_team
    if current_user.team_id != nil
      flash[:notice] = "You already have a team, showing your team status page instead."
      redirect_to :controller => :teams, :action => :show, :id => current_user.team_id
    end
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
    q = params[:q]
    @teams = Team.get_active_with_search(q)
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
    if false && !current_user.paid?
      flash[:notice] = 'You must pay the entry fee before starting a team.'
      redirect_to payment_path
    else 
      @team = Team.new(params[:team])
      respond_to do |format|
        if @team.save
          if !@team.set_captain(current_user)
            raise "No user logged in"
          end
          if current_user && current_user.admin?
            @team.slot_finalize_admin
          else
            @team.slot_finalize_not_admin
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
  end

  def update
    respond_to do |format|
      if @team.update_attributes(params[:team])
        if current_user && current_user.admin?
          @team.slot_finalize_admin
        else
          @team.slot_finalize_not_admin
        end
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
    # remove members
    @member_list = User.find(:all, :conditions => ["team_id = ?", @team.id])
    @member_list.each do |user|
      user.team_id = nil
      user.save
    end
    # remove time
    Booking.destroy_all(:team_id => @team.id)
    # deactivate
    @team.active = false 
    @team.save
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

  def invite
    if flash[:body]
      @body = flash[:body]
    else
      userid = 0
      userid = current_user.id if current_user
      teamid = 0
      teamid = @team.id if @team
      @body = "Hey Friend, I'm doing this awesome thing!\n\n" +
              "Help me raise funds our team for ethos music project" +
	      "Click on this link to help sponsor me" +
              "Go to http://openathon.makerlab.com/sponsor/#{teamid}?party=#{userid} and support me!\n\n" +
              "Thanks!"
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
    if email_blob.empty?
      flash[:no_emails] = true
      flash[:body] = params[:user_message]
      redirect_to :action => :invite
    end
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
    current_user.team_id = @team.id
    current_user.save
  end

end

