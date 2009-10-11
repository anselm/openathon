require 'openssl' 
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
    donation2 = params[:donation2]
    donation = params[:donation]
    donation2 = donation if donation
    donation = donation2.to_i
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
      donation2 = donation if donation2
      donation = donation2.to_i
      @payment.update_attributes( :amount => donation )
    end
    if @payment.amount < 1
      @message = " bad donation amount entered.  Please hit back and try again"
      render :action => 'error'
      return
    end

    # capture the company match if there is one
    matching_company = params[:matching_company]
    if matching_company
      @payment.update_attributes( :matching_company => matching_company)
    end

    # try get a party if there is one passed - this overrides anything from before.
    @party = nil
    @party = User.find(params[:party].to_i) if params[:party]
    @partyid = 0
    @partyid = @party.id if @party
    @payment.update_attributes( :owner_id => @partyid ) if @partyid > 0
    
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

    @paypal_business_email = SETTINGS[:paypal_business_email]
    @business_key = PAYPAL_MYPRIVKEY
    @business_cert = PAYPAL_MYPUBCERT
    @business_certid = SETTINGS[:paypal_cert]
    @action_url = "http://www.paypal.com/cgi-bin/webscr"
    Paypal::Notification.ipn_url = @action_url
    Paypal::Notification.paypal_cert = PAYPAL_CERT

  end

  def confirm_standard
    begin
      if current_user && current_user.team && current_user.team.id
        flash[:notice] = "Payment completed!"
        redirect_to :action => "show", :controller => "teams", :id => current_user.team.id
      else
        flash[:notice] = "Payment completed!"
        redirect_to "/"
      end
    rescue
      flash[:notice] = "Payment completed!"
      redirect_to "/"
    end
  end

  def payment_received

    # test
    @action_url = "http://www.paypal.com/cgi-bin/webscr"
    Paypal::Notification.ipn_url = @action_url
    Paypal::Notification.paypal_cert = PAYPAL_CERT

    notify = Paypal::Notification.new(request.raw_post)

    ActionController::Base.logger.info "payment_received!!!"
    ActionController::Base.logger.info notify.to_s

    # Update our records
    payment_id = params[:custom]

    # capture the payer details returned by PayPal
    firstname = params[:first_name]
    lastname = params[:last_name]
    email = params[:payer_email]

    completed = false
    completed = true if notify.params["payment_status"] == "Completed"
    ActionController::Base.logger.info "paymet status is #{completed}"

    if completed == true && payment_id && payment_id.to_i > 0

     @payment = Payment.find(:first,:conditions => { :id => payment_id.to_i } )
     if @payment
      ActionController::Base.logger.info "found payment #{@payment.id} of kind #{@payment.description} for amount #{@payment.amount}"
      # update the payment if it is a donation style
      if @payment.description == Payment::CHECKOUT
        @payment.update_attributes( :description=> Payment::DONE, :firstname => firstname, :lastname => lastname, :email => email  )
        ActionController::Base.logger.info "updated a donation payment"
      end

      # update the party status if it is a membership fee
      # TODO these should not land here
      @party = nil
      @party = User.find(:first,:conditions => { :id => @payment.owner_id } ) if @payment.owner_id
      if @party
         if @payment.description == Payment::FEE
           ActionController::Base.logger.info "user set to paid"
           @party.paid = true
           @party.save
           ActionController::Base.logger.info "payment set to paid"
           @payment.update_attributes( :description=> Payment::DONE_FEE, :firstname => firstname, :lastname => lastname, :email => email )
         end
      end
     end
    end

#    begin
      if notify.acknowledge
        ActionController::Base.logger.info "Paypal transaction acknowledged!"
        if notify.complete?
          # we already know if this is complete or not ... but anyway do this for good luck
          ActionController::Base.logger.info "Paypal transaction complete!"
           # yay!try figure out who paid and then record that
        else
        end
      else
        # this case doesn't strictly make sense since we have the transaction already 
        ActionController::Base.logger.info "Paypal transaction acknowledge failure!!"
      end  
#    rescue => e
#      ActionController::Base.logger.info "notify acknowledge crashed because of #{e}"
#    end

    render :nothing => true
  end

end

