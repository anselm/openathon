class UsersController < ApplicationController

  layout 'twocolumn'

  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:promo, :show, :edit, :update]
  
  def index
  end

  def new
    @user = User.new
  end
  
  def create
    @user = User.new(params[:user])
    if @user.save
      @user.sanitize_force
      flash[:notice] = "Account registered!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end
  
  def show
    @user = @current_user
  end

  def edit
    @user = @current_user
  end
  
  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      @user.sanitize_force
      flash[:notice] = "Account updated!"
      redirect_to account_url
    else
      render :action => :edit
    end
  end

  def promo
    if @current_user && params[:promo] != nil
      if params[:promo].to_s == SETTINGS[:promo_code].to_s
        flash[:notice] = "Promotional code accepted!"
        @current_user.paid = true
        @current_user.save
        redirect_to account_url
      else
        flash[:error] = "Promotional code not accepted"
      end
    end
  end

end
