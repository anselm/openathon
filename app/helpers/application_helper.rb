require 'paypal'
require 'money'

module ApplicationHelper
  include Paypal::Helpers
end

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper
  def admin?
    @current_user.admin? 
  end

  def paid?
    @current_user.paid? 
  end

end
