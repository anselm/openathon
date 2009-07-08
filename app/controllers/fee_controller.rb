class FeeController < ApplicationController
#  include ActiveMerchant::Billing

  layout 'twocolumn'

  DONATION_FEE = 13

  def index
    @amount = DONATION_FEE * 100
    if !current_user
      @message = "Sorry you need to login"
      render :action => 'error'
      return
    end
    @payment = Payment.new(:owner_id=>current_user.id,:amount=>@amount,:description=> Payment::FEE )
    @payment.save
    session[:payment] = @payment
  end

  def checkout
    # there must be a payment
    @payment = session[:payment]
    if !@payment
      @message = "Sorry an internal error has occured"
      render :action => 'error'
      return
    end
    if !current_user
      @message = "Sorry no donation found - did you pick a value?"
      render :action => 'error'
      return
    end
    @amount = DONATION_FEE * 100
    @party = current_user
    @partyid = @party.id if @party
    @payment.update_attributes( :description=> Payment::CHECKOUT_FEE )
    # setup payment
    setup_response = setup_gateway.setup_purchase(@amount,
      :ip               => request.remote_ip,
      :return_url       => url_for(:controller=>"fee",
                             :action => 'confirm', :only_path => false),
      :cancel_return_url => url_for(:controller=>"fee",
                              :action => 'index', :only_path => false)
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
      if current_user
         current_user.paid = true
         current_user.save
      end
      @payment.update_attributes( :description=> Payment::DONE_FEE )
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

