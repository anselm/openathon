class PaymentController < ApplicationController
  include ActiveMerchant::Billing

  layout 'twocolumn'

  def index
  end

  # this consolidates general donation and sponsorship of a specific party
  # it can take an input like so or nothing:
  #  /id?party=1234
  # and it tries to make the right kind of display
  def sponsor
    # the form wants to show all teams
    @teams = Team.get_active_with_search(nil)
    # try get a specific team to start with
    @team = Team.find(:first,:conditions => { :id => params[:id] } ) if params[:id]
    # get one randomly if none set
    #@team = @teams[rand(@teams.length)] if !@team && @teams.length
    # Get all parties of current team so the view doesn't need to be javascript based
    @parties = []
    @parties = User.find(:all, :conditions => ["team_id = ?", @team.id]) if @team
    # try get a party if there is one passed
    # throw away the team basically after this - we don't care about it
    @party = nil
    @party = User.find(params[:party].to_i) if params[:party]
    @partyid = 0
    @partyid = @party.id if @party
    # collect both possible donations ( we can do this later but might as well get it now also )
    donation = params[:donation]
    donation2 = params[:donation2]
    donation = donation2 if donation2
    donation = donation.to_f
    donation = donation * 100
    donation = donation.to_i
    # build a new payment that is marked as state new
    @payment = Payment.new(:owner_id=>@partyid,:amount=>donation,:description=>'new')
    @payment.save
    session[:payment] = @payment
  end

  # here is the real meat - all values need to be prepared by here
  # throw away the team basically after this - we don't care about it - since party has it
  # http://localhost:3000/donate?team=2&party=2&donation=10.00&donation2=20&x=101&y=11
  def checkout
    # there must be a payment
    @payment = session[:payment]
    if !@payment
      @message = "Sorry an internal error has occured"
      render :action => 'error'
      return
    end
    # the donation can change based on parameters supplied
    if @payment.amount < 100
      # collect both possible donations
      donation = params[:donation]
      donation2 = params[:donation2]
      donation = donation2 if donation2
      donation = donation.to_f
      donation = donation * 100
      donation = donation.to_i
      @payment.update_attributes( :amount => donation )
    end
    if @payment.amount < 100
      @message = "Sorry no donation found - did you pick a value?"
      render :action => 'error'
      return
    end
    # try get a party if there is one passed - this overrides anything from before.
    @party = nil
    @party = User.find(params[:party].to_i) if params[:party]
    @partyid = 0
    @partyid = @party.id if @party
    @payment.update_attributes( :owner_id => @partyid ) if @partyid > 0
    # it is ok not to have a person to donate to in the case of the general fun
    #if @payment.owner_id == 0
    #  @message = "Sorry no person to donate to found"
    #  render :action => 'error'
    #  return
    #end

    # move payment along to the next stage
    @payment.update_attributes( :description=>'checkout', :amount => donation )
    
    # TODO remove garbage
    setup_response = setup_gateway.setup_purchase(donation,
      :ip               => request.remote_ip,
      :return_url       => url_for(:controller=>"payment",
                             :action => 'confirm', :only_path => false),
      :cancel_return_url => url_for(:controller=>"payment",
                              :action => 'sponsor', :only_path => false)
    )
    url = setup_gateway.redirect_url_for(setup_response.token)
    redirect_to url
  end

  def confirm
    ActionController::Base.logger.info "confirm"
    redirect_to :action => 'index' unless params[:token]
    ActionController::Base.logger.info "confirm 2"
    details_response = setup_gateway.details_for(params[:token])
    if !details_response.success?
      @message = details_response.message
      render :action => 'error'
      return
    end
    @address = details_response.address
  end

  def complete
    ActionController::Base.logger.info "purchase"
    purchase = setup_gateway.purchase(100,
      :ip       => request.remote_ip,
      :payer_id => params[:payer_id],
      :token    => params[:token]
    )
    if !purchase.success?
      @message = purchase.message
      render :action => 'error'
      return
    else
      # should be ok
    end
    @payment = session[:payment]
    if !@payment
      @message = "Sorry your payment went through but we had trouble recording it"
      render :action => 'error'
      return
    else
      @payment.update_attributes( :description=>'done' )
    end
  end

  def notify
    notify = Paypal::Notification.new(request.raw_post)
    enrollment = Enrollment.find(notify.item_id)

    if notify.acknowledge
      @payment = Payment.find_by_confirmation(notify.transaction_id) ||
        enrollment.invoice.payments.create(:amount => notify.amount,
          :payment_method => 'paypal', :confirmation => notify.transaction_id,
          :description => notify.params['item_name'], :status => notify.status,
          :test => notify.test?)
      begin
        if notify.complete?
          @payment.status = notify.status
        else
          logger.error("Failed to verify Paypal's notification, please investigate")
        end
      rescue => e
        @payment.status = 'Error'
        raise
      ensure
        @payment.save
      end
    end
    render :nothing => true
  end

private

  def setup_gateway
    @gateway ||= PaypalExpressGateway.new(
      :login => SETTINGS[:paypal_username],
      :password => SETTINGS[:paypal_password],
      :signature => SETTINGS[:paypal_signature]
    )
    return @gateway
  end

end

