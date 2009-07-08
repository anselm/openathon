require 'paypal'
require 'money'

class PaymentController < ApplicationController

#  include ActiveMerchant::Billing
#  include ActiveMerchant::Billing::Integrations

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
    donation = donation.to_i
    # build a new payment that is marked as state new
    @payment = Payment.new(:owner_id=>@partyid,:amount=>donation,:description=> Payment::NEW )
    @payment.save
    session[:payment] = @payment
  end

  # here is the real meat - all values need to be prepared by here
  # throw away the team basically after this - we don't care about it - since party has it
  # http://localhost:3000/donate?team=2&party=2&donation=10.00&donation2=20&x=101&y=11
  def checkout
    # there must be a payment
    @payment = session[:payment]
    if !@payment || !@payment.amount
      @message = "Sorry an internal error has occured"
      render :action => 'error'
      return
    end

    # the donation can change based on parameters supplied
    if @payment.amount < 1
      # collect both possible donations
      donation = params[:donation]
      donation2 = params[:donation2]
      donation = donation2 if donation2
      donation = donation.to_i
      @payment.update_attributes( :amount => donation )
    end
    if @payment.amount < 1
      @message = "xSorry no donation found - did you pick a value?"
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
    @payment.update_attributes( :description=> Payment::CHECKOUT , :amount => donation )

      @notify_url = url_for(
                        :controller=>"payment",
                        :action => 'payment_received',
                        :id => @payment.id,
                        :only_path => false
                         )

      @return_url = url_for(
                        :controller=>"payment",
                        :action => 'confirm_standard',
                        :only_path => false
                         )

      @payment_received_url = payment_received_url
      @action_url = "http://www.paypal.com/cgi-bin/webscr"
      @business_key = PAYPAL_MYPRIVKEY
      @business_cert = PAYPAL_MYPUBCERT
      @business_certid = SETTINGS[:paypal_cert]
      Paypal::Notification.ipn_url = @action_url
      Paypal::Notification.paypal_cert = PAYPAL_CERT
      # FALL THROUGH TO checkout.html.erb - and that goes to confirm_standard

  end

  def confirm_standard
    # TODO do something useful here
    redirect_to "/" 
  end

  def payment_received

    notify = Paypal::Notification.new(request.raw_post)
    
    # apparently we could check to see if the transaction was already found locally and done
    # unused
    #if !Trans.count("*", :conditions => ["paypal_transaction_id = ?", notify.transaction_id]).zero?
    #  # do some logging here...
    #end

    # get some kind of identifier from the request
    ActionController::Base.logger.info "payment_received with param #{params[:id]}"
    ActionController::Base.logger.info notify.to_s

    if notify.acknowledge
      begin
        if notify.complete?
           # yay!try figure out who paid and then record that
        else
        end
      rescue => e
        # bad...
      ensure
      end
    else
      # bad...
    end  

    render :nothing => true
  end

end

