
class PaymentController < ApplicationController
  include ActiveMerchant::Billing

  def index
  end

  def checkout
    setup_response = setup_gateway.setup_purchase(100,
      :ip                => request.remote_ip,
      :return_url        => url_for(:action => 'confirm', :only_path => false),
      :cancel_return_url => url_for(:action => 'index', :only_path => false)
    )
    redirect_to setup_gateway.redirect_url_for(setup_response.token)
  end

  def confirm
    redirect_to :action => 'index' unless params[:token]
    details_response = setup_gateway.details_for(params[:token])
    if !details_response.success?
      @message = details_response.message
      render :action => 'error'
      return
    end
    @address = details_response.address
  end

  def complete
    purchase = setup_gateway.purchase(5000,
      :ip       => request.remote_ip,
      :payer_id => params[:payer_id],
      :token    => params[:token]
    )
    if !purchase.success?
      @message = purchase.message
      render :action => 'error'
      return
    end
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

