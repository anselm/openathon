class PasswordResetsController < ApplicationController

  layout 'twocolumn'

  before_filter :load_user_using_perishable_token, :only => [:edit, :update]  
  #before_filter :require_no_user  
  
  # user requests a password change  
  def create
   if request.post?
     @user = User.find_by_email(params[:email])  
     if @user   
       @user.reset_perishable_token!
       magic_url = edit_password_reset_url(@user.perishable_token)  
       #MailMailer.deliver_password_reset_instructions(@user,magic_url) 
       from = "support@raiseyourvoicepdx.com"
       from_alias = "RaiseYourVoice Support"
       to = @user.email
       to_alias = "#{@user.firstname} #{@user.lastname}"
       subject = "Raise Your Voice Password Reset Instructions"
       message = "Please visit this URL to reset your password: #{magic_url}"
       send_email(from, from_alias, to, to_alias, subject, message)
       flash[:notice] = "Instructions to reset your password have been emailed to you."  
       redirect_to root_url  
     else  
       flash[:error] = "No user was found with that email address"  
     end
   end
  end  
  
  def update  
   if request.put?
    @user.password = params[:user][:password]  
    @user.password_confirmation = params[:user][:password_confirmation]  
    if @user.save
      flash[:notice] = "Password successfully updated."  
      redirect_to signin_url  
    else  
      flash.now[:error] = "Passwords did not match."  
    end  
  end  
  end  
    
  private  

  def load_user_using_perishable_token  
    @user = User.find_using_perishable_token(params[:token])  
    unless @user  
      flash[:notice] = "We're sorry, but we could not locate your account. " +  
      "If you are having issues try copying and pasting the URL " +  
      "from your email into your browser or restarting the " +  
      "reset password process."  
      redirect_to root_url  
    end  
  end

end
