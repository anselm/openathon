class TeamsController < ApplicationController

  layout 'twocolumn'

  # for these methods there MUST be a team in mind
  before_filter :get_team, :only => [:show,
    :edit,
    :update,
    :destroy,
    :invite,
    :raise,
    :sponsor,
    :join,
    :leave
  ]

  # for these methods there MUST be a member logged in
  before_filter :verify_member, :only => [:new,
    :raise,
    :raise_confirm,
    :raise_do,
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
  before_filter :verify_paid, :only => [:new, :join]

  private

  def get_team
    @team = nil
    @team = Team.find(:first,:conditions=>{:id=>params[:id]}) if params[:id]
    return @team != nil
  end

  def verify_new_team
    if current_user.team_id != nil
      flash[:error] = "You already have a team, showing your team status page instead."
      redirect_to :controller => :teams, :action => :show, :id => current_user.team_id
    end
  end

  def verify_paid
    unless current_user.paid
      flash[:error] = "You must pay the entry fee before starting a team."
      redirect_to "/registration_fee"
    end
  end

  def verify_member
    if current_user == nil
      # flash[:error] = "Please signup to create or join a team."
      redirect_to "/signup"
      return false
    end
    return true
  end

  def verify_powers
    if current_user == nil
      flash[:error] = "Please sign in to edit your team."
      redirect_to "/signin"
      return false
    end
    if @team == nil || !@team.is_owner?(current_user)
      flash[:error] = "This is not your team - you cannot change it."
      return false
    end
  end

  def create_note
    @note = Note.new(params[:note])
    @note.description = Sanitize.clean @note.description

    respond_to do |format|
      if @note.save
        flash[:notice] = 'Note was successfully created.'
        # redirect_to teams_path
        format.html { redirect_to teams_path }
        format.xml  { render :xml => @note, :status => :created, :location => @note }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @note.errors, :status => :unprocessable_entity }
      end
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
    @announcement = Note.find(:first, :conditions => { :kind => "announcement" } )
    @member_list = @team.payment_sorted_users()
    render :layout => "threecolumn"
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

    if !current_user
      store_location "/create"
      redirect_to "/signup"
      return
    end

    if false && !current_user.paid?
      flash[:error] = 'You must pay the entry fee before starting a team.'
      redirect_to "/registration_fee" 
    else 
      @team = Team.new(params[:team])
      respond_to do |format|
        if @team.save
          @team.sanitize_force
          if !@team.set_captain(current_user)
            raise "No user logged in"
          end
          #if current_user && current_user.admin?
          #  @team.slot_finalize_admin
          #else
          #  @team.slot_finalize_not_admin
          #end
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
        @team.sanitize_force
        #if current_user && current_user.admin?
        #  @team.slot_finalize_admin
        #else
        #  @team.slot_finalize_not_admin
        #end
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

  # TODO get this big chunk of text outta here!
  def raise
    if flash[:body]
      @body = flash[:body]
    else
      userid = 0
      userid = current_user.id if current_user
      teamid = 0
      teamid = current_user.team_id
      @raise_link = "http://raiseyourvoicepdx.com/sponsor/#{teamid}?party=#{userid}"
      @body = <<HERE
Hi Friend!<br /><br /><img align="right" src="http://scottley.smugmug.com/photos/585883850_4eMdY-S.jpg">

I am writing because I am participating in an innovative and exciting fundraiser called <a href="#{@raise_link}">Raise Your Voice</a> – a 24-hour Karaoke Marathon to benefit Ethos Music Center held at Voicebox Karaoke – and I need your help!<br /><br />

My team, <b>#{current_user.team.name}</b> has committed to sing for <b>#{current_user.team.hours} hours</b> throughout the event, and we need to raise <b>$#{(current_user.team.hours.to_i*500)}</b>, so we need YOUR help to reach our goal!<br /><br />

In addition to raising money for such a great non-profit, Ethos Music Center, we are competing for the top team and individual fundraisers. The individuals and teams who raise the most will be honored with some sweet prizes. It is really easy to <a href="#{@raise_link}">donate</a>, and all donations are tax deductible to the full extent of the law.<br /><br />

Ethos is a non-profit dedicated to providing music education to youth in under served communities throughout Oregon. Created as a response to the elimination of music programs in public schools, Ethos provides music lessons on a sliding scale to students of various ages, and their studies have shown that kids who take music lessons achieve higher grades and have better attendance records at school.<br /><br />

Voicebox Karaoke is a new karaoke lounge in Northwest with private karaoke party suites.  If all 6 spaces are filled with teams constantly for all 24 hours, and each team meets the goal of $500 per hour, we will raise over $60,000 for Ethos!<br /><br />

Every little bit helps – whether you can afford $10, $100, or more, please take a second to support our cause and <a href="#{@raise_link}">Raise Your Voice</a> in support of music education!<br /><br  />

Thank you in advance!<br /><br />
#{current_user.firstname} #{current_user.lastname}

HERE

      flash[:body] = @body
    end
    if flash[:recipients]
      @recipients = flash[:recipients]
    else
      @recipients = Array.new
    end
    @team = nil
    @team = Team.find(:first,:conditions=>{:id=>current_user.team_id}) if current_user
  end

  def raise_confirm
    @team = nil
    @team = Team.find(:first,:conditions=>{:id=>current_user.team_id}) if current_user
    email_blob = params[:email_blob]
    if email_blob.empty?
      flash[:no_emails] = true
      flash[:body] = flash[:body]
      redirect_to :action => :raise
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
    flash[:body] = flash[:body]
    flash[:recipients] = @recipients
    if @error_array.length > 0
      flash[:email_errors] = @error_array
      redirect_to :action => :raise
    end
    @body = flash[:body]
    flash[:body] = @body
  end

  def raise_do
    if current_user
      current_user.invitedfriends = true
      current_user.save
    end
    recipients = flash[:recipients]
    body = flash[:body]
    recipients.each do |email|
      MailMailer.deliver_invite(current_user, email, body)
    end
    flash[:notice] = 'Invitations sent!'
    @team = nil
    @team = Team.find(:first,:conditions=>{:id=>current_user.team_id}) if current_user
    redirect_to(@team) if @team
    redirect_to("/") if !@team # OH OH
  end

  def invite
    if flash[:body]
      @body = flash[:body]
    else
      @invite_link = "http://raiseyourvoicepdx.com/teams/#{current_user.team_id}"
      @body =  <<HERE
Hi Friend!<br /><br /><img align="right" src="http://scottley.smugmug.com/photos/585883850_4eMdY-S.jpg">

I am writing because I am participating in an innovative and exciting fundraiser called <a href="#{@invite_link}">Raise Your Voice</a> – a 24-hour Karaoke Marathon to benefit Ethos Music Center held at Voicebox Karaoke – and I want YOU to join my team.<br /><br />

My team, <b>#{current_user.team.name}</b> has committed to sing for <b>#{current_user.team.hours} hours</b> throughout the event, and we need to raise <b>$#{(current_user.team.hours.to_i*500)}</b>, so we need YOUR help to reach our goal!<br /><br />

Ethos is a non-profit dedicated to providing music education to youth in under served communities throughout Oregon. Created as a response to the elimination of music programs in public schools, Ethos provides music lessons on a sliding scale to students of various ages, and their studies have shown that kids who take music lessons achieve higher grades and have better attendance records at school.<br /><br />

Voicebox Karaoke is a new karaoke lounge in Northwest with private karaoke party suites.  If all 6 spaces are filled with teams constantly for all 24 hours, and each team meets the goal of $500 per hour, we will raise over $60,000 for Ethos!<br /><br />

Let’s help Ethos fund their programs, while having a sweet time singing karaoke at an event that has never been done in Portland before! I would love to have you on my team.<br /><br />

Click <a href="#{@invite_link}">HERE</a> to Join!<br /><br />

Thanks,<br /><br />
#{current_user.firstname} #{current_user.lastname}
HERE
    flash[:body] = @body
    end
    if flash[:recipients]
      @recipients = flash[:recipients]
    else
      @recipients = Array.new
    end
    @team = nil
    @team = Team.find(:first,:conditions=>{:id=>current_user.team_id}) if current_user
  end

  def invite_confirm
    @team = nil
    @team = Team.find(:first,:conditions=>{:id=>current_user.team_id}) if current_user
    email_blob = params[:email_blob]
    if email_blob.empty?
      flash[:no_emails] = true
      flash[:body] = flash[:body]
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
    flash[:body] = flash[:body]
    flash[:recipients] = @recipients
    if @error_array.length > 0
      flash[:email_errors] = @error_array
      redirect_to :action => :invite
    end
    @body = flash[:body]
    flash[:body] = @body
  end

  def invite_do
    if current_user
      current_user.invitedfriends = true
      current_user.save
    end
    recipients = flash[:recipients]
    body = flash[:body]
    recipients.each do |email|
      MailMailer.deliver_invite(current_user, email, body)
    end
    flash[:notice] = 'Invitations sent!'
    @team = nil
    @team = Team.find(:first,:conditions=>{:id=>current_user.team_id}) if current_user
    redirect_to(@team) if @team
    redirect_to("/") if !@team # OH OH
  end

  def leave
    if current_user
      current_user.team_id = nil
      current_user.save
    end
  end

  def join
    if @team && current_user
      current_user.team_id = @team.id
      current_user.save
      @member_list = User.find(:all, :conditions => ["team_id = ?", @team.id])
      if @member_list.length == 0
        @team.set_captain(current_user)
      end 
      flash[:notice] = "You've joined the team!"
      redirect_to(@team)
    else
      flash[:error] = "You have not paid the entry fee."
      redirect_to "/registration_fee"
    end
  end

end

