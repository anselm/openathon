class TeamsController < ApplicationController
  # GET /teams
  # GET /teams.xml
  def index
    @teams = Team.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @teams }
    end
  end

  # GET /teams/1
  # GET /teams/1.xml
  def show
    @team = Team.find(params[:id])
    @member_list = User.find(:all, :conditions => ["team_id = ?", @team.id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @team }
    end
  end

  # GET /teams/new
  # GET /teams/new.xml
  def new
    @team = Team.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @team }
    end
  end

  # GET /teams/1/edit
  def edit
    @team = Team.find(params[:id])
  end

  # POST /teams
  # POST /teams.xml
  def create
    @team = Team.new(params[:team])

    respond_to do |format|
      if @team.save
        # associate user with team

        if (current_user)
          dbuser = User.find(current_user.id)
          dbuser.team_id = @team.id
          dbuser.role = 'captain'
          dbuser.save
        else
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

  # PUT /teams/1
  # PUT /teams/1.xml
  def update
    @team = Team.find(params[:id])

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

  # DELETE /teams/1
  # DELETE /teams/1.xml
  def destroy
    @team = Team.find(params[:id])
    @team.destroy

    respond_to do |format|
      format.html { redirect_to(teams_url) }
      format.xml  { head :ok }
    end
  end
end


#
# Openathon specific work
#

class TeamsController
  # team : start a team page - here for now.
  def start
  end

  # team : join an existing team page
  def join
  end

  # team : team calendar of upcoming sessions
  def calendar
  end

  # team : search
  def search
  end

  # team : browse
  def browse
  end

  # team : see all teams
  def teams
  end

  # team : invite -- sends off an invitation email
  def invite
    if flash[:body]
      @body = flash[:body]
    else
      @body = "Hey Friend, I'm doing this awesome thing!\n\nGo to http://openathon.makerlab.com and support me!\n\nThanks!"
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

    # create an array to catch any invalid email addresses
    @error_array = Array.new

    # validate the email addresses
    @recipients.each do |email|
      begin
        TMail::Address.parse(email)
      rescue
        @error_array << email
      end
    end

    flash[:body] = params[:user_message]
    flash[:recipients] = @recipients

    # if there's any errored email addresses, try again

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

end