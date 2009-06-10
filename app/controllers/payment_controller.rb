class PaymentController < ApplicationController
  include ActiveMerchant::Billing

  layout 'normal'

  def index
  end

  def sponsor
    @team = Team.find(params[:id])
    @party = nil
    @party = User.find(params[:party].to_i) if params[:party]
    if !@party
      @message = "Sorry we can't figure out who you mean to donate to"
      render :action => 'error'
      return
    end
    # build a new payment that is marked as state new
    payment = Payment.new(:owner_id=>@party.id,:amount=>0,:description=>'new')
    payment.save
    session[:payment] = payment
  end

  def checkout
    # move payment state along
    payment = session[:payment]
    if !payment
      @message = "Sorry an internal error has occured"
      render :action => 'error'
      return
    end 
    # collect both possible donations
    donation = params[:donation]
    donation2 = params[:donation2]
    donation = donation2 if donation2
    donation = donation.to_f
    donation = donation * 100
    donation = donation.to_i
    if donation < 1
      @message = "Sorry no donation found - did you pick a value?"
      render :action => 'error'
      return
    end
    payment.update_attributes( :description=>'checkout', :amount => donation )
    
    # TODO remove garbage
    setup_response = setup_gateway.setup_purchase(donation,
      :ip               => request.remote_ip,
      :return_url       => "http://openathon.makerlab.com/confirm", #url_for(:controller="payment",:action => 'confirm', :only_path => false),
      :cancel_return_url => "http://openathon.makerlab.com/" # url_for(:controller="payment",:action => 'sponsor', :only_path => false)
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
    payment = session[:payment]
    if !payment
      @message = "Sorry your payment went through but we had trouble recording it"
      render :action => 'error'
      return
    else
      payment.update_attributes( :description=>'done' )
    end
  end

  def donate
#    @enrollment = current_user.enrollments.find(params[:id])
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

