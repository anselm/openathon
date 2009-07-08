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

    # TURNED OFF BECAUSE WE DO NOT WANT TO REQUIRE PARTICIPANTS TO HAVE A PAYPAL ACCOUNT
    paypal_express = false
    if paypal_express    
        setup_response = setup_gateway.setup_purchase(
                                  donation,
                                  :ip => request.remote_ip,
                                  :return_url => url_for(
                                                   :controller=>"payment",
                                                   :action => 'confirm',
                                                   :only_path => false),
                                  :cancel_return_url => url_for(
                                                   :controller=>"payment",
                                                   :action => 'sponsor',
                                                   :only_path => false)
                             )
       url = setup_gateway.redirect_url_for(setup_response.token)
       redirect_to url
    end

    # HERE IS A DIFFERENT APPROACH THAT USES PAYPAL STANDARD NOT EXPRESS FOR MORE FLEXIBILITY
    paypal_standard = true
    if paypal_standard

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

      # cert_id is the certificate if we see in paypal when we upload our own certificates
      # cmd _xclick need for buttons
      # item name is what the user will see at the paypal page
      # custom and invoice are passthrough vars which we will get back with the asunchronous
      # notification
      # no_note and no_shipping means the client want see these extra fields on the paypal payment
      # page
      # return is the url the user will be redirected to by paypal when the transaction is completed.

      @decrypted = {
        "cert_id" => SETTINGS[:paypal_cert],
        "cmd" => "_xclick",
        "business" => SETTINGS[:paypal_business_email],
        "item_name" => SETTINGS[:paypal_item_name],
        "item_number" => "#{@payment.id}",
        "custom" =>"#{@payment.id}",
        "amount" => "#{@payment.amount}",
        "currency_code" => "USD",
        "country" => "US",
        "no_note" => "1",
        "no_shipping" => "1",
        "notify_url" => @payment_received_url,
        "return" => @return_url
      }
      # @encrypted_basic = encrypt_stuff(decrypted)

      @business_key = PAYPAL_MYPRIVKEY
      @business_cert = PAYPAL_MYPUBCERT
      @business_certid = SETTINGS[:paypal_cert]
      Paypal::Notification.ipn_url = @action_url
      Paypal::Notification.paypal_cert = PAYPAL_CERT
      # FALL THROUGH TO checkout.html.erb - and that goes to confirm_standard

    end
  end

  def confirm_standard
    # TODO do something useful here
    redirect_to "/" 
  end

  def encrypt_stuff(data)
    my_cert_file = "/www/sites/raiseyourvoice_secrets/my-pubcert.pem"
    my_key_file = "/www/sites/raiseyourvoice_secrets/my-prvkey.pem"
    paypal_cert_file = "/www/sites/raiseyourvoice_secrets/paypal_cert.pem"
    IO.popen("/usr/bin/openssl smime -sign -signer #{my_cert_file} -inkey #{my_key_file} -outform der - nodetach -binary | /usr/bin/openssl smime -encrypt -des3 -binary -outform pem #{paypal_cert_file}", 'r+') do | pipe|
            data.each { |x,y| pipe << "#{x}=#{y}\n" }
            pipe.close_write
            @data = pipe.read
            return @data
      end
      return "" # wont get here
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

  # THIS IS NOT USED FOR NOW - WE ARE TRYING PAYMENTS STANDARD 
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

  # UNUSED FOR NOW
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
      @payment.update_attributes( :description=> Payment::DONE )
    end
  end

  # UNUSED FOR NOW
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

