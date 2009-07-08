require 'paypal'
require 'money'

class FeeController < ApplicationController
#  include ActiveMerchant::Billing

  layout 'twocolumn'

  DONATION_FEE = 13

  def index
    @amount = DONATION_FEE
    if !current_user
      @message = "Sorry you need to login"
      render :action => 'error'
      return
    end
    @party = current_user
    @partyid = @party.id if @party
    @payment = Payment.new(:owner_id=>current_user.id,:amount=>@amount,:description=> Payment::FEE )
    @payment.save
    session[:payment] = @payment

      @notify_url = url_for(
                        :controller=>"fee",
                        :action => 'payment_received',
                        :id => @payment.id,
                        :only_path => false
                         )

      @return_url = url_for(
                        :controller=>"fee",
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
  end

  def confirm_standard
      @payment = session[:payment]
      @party = current_user
      if @party
         @party.paid = true
         @party.save
      end
      @payment.update_attributes( :description=> Payment::DONE_FEE )
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

