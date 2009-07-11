ActionController::Routing::Routes.draw do |map|

  # activescaffold
  map.resources :scaffold
  map.resources :scaffoldusers
  map.resources :scaffoldpayments

  # csv
  map.teams_csv      'teams.csv',    :controller => 'scaffold',         :action => 'csv'
  map.users_csv      'users.csv',    :controller => 'scaffoldusers',    :action => 'csv'
  map.payments_csv   'payments.csv', :controller => 'scaffoldpayments', :action => 'csv'

  # people
  map.resource  :account, :controller => "users"
  map.resource  :user_session
  map.resources :users
  map.signup    'signup',      :controller => 'users',           :action => 'new'
  map.signin    'signin',      :controller => 'user_sessions',   :action => 'new'
  map.signout   'signout',     :controller => 'user_sessions',   :action => 'destroy'

  # passwords
  map.password_resets 'password_resets', :controller => 'password_resets', :action => 'create'
  map.edit_password_reset 'password_resets/:token', :controller => 'password_resets', :action => 'update'

  # teams
  map.resources :teams
  map.raise    'raise/:id',   :controller => 'teams',    :action => 'raise'
  map.invite   'invite/:id',  :controller => 'teams',    :action => 'invite'
  map.join     'join',        :controller => 'teams',    :action => 'join'
  map.leave    'leave',       :controller => 'teams',    :action => 'leave'
  map.calendar 'calendar',    :controller => 'teams',    :action => 'calendar'
  map.search   'search',      :controller => 'teams',    :action => 'teams'
  map.teams    'teams',       :controller => 'teams',    :action => 'teams'
  map.resources :notes

  # pay fee
  map.fee    'registration_fee', :controller => 'fee',  :action => 'index'
  map.fee_payment  'fee_payment',     :controller => 'fee',  :action => 'payment'
  map.fee_checkout 'fee_checkout',    :controller => 'fee',  :action => 'checkout'
  map.fee_confirm  'fee_confirm',     :controller => 'fee',  :action => 'confirm'
  map.fee_complete 'fee_complete',    :controller => 'fee',  :action => 'complete'

  # money
  map.sponsor  'sponsor/:id', :controller => 'payment',  :action => 'sponsor'
  map.donate   'donate/:id',  :controller => 'payment',  :action => 'sponsor'
  map.payment  'payment/:id', :controller => 'payment',  :action => 'confirm_standard'
  map.checkout 'checkout',    :controller => 'payment',  :action => 'checkout'
  map.confirm  'confirm',     :controller => 'payment',  :action => 'confirm'
  map.complete 'complete',    :controller => 'payment',  :action => 'complete'
  map.payment_received 'payment_received', :controller => 'payment', :action => 'payment_received'
  map.confirm_standard 'confirm_standard', :controller => 'payment', :action => 'confirm_standard'

  # general activities
  map.privacy    'privacy',:controller => 'index',    :action => 'privacy'
  map.tos    'tos',    :controller => 'index',    :action => 'privacy'
  map.about    'about',  :controller => 'index',    :action => 'about'
  map.admin    'admin',  :controller => 'index',    :action => 'admin'
  map.admin_announcement    'admin_announcement',  :controller => 'index',    :action => 'admin_announcement'
  map.admin_message    'admin_message',  :controller => 'index',    :action => 'admin_message'
  map.news     'news',   :controller => 'index',    :action => 'news'
  map.contact  'contact',   :controller => 'index',    :action => 'contact'
  map.start    'start',  :controller => 'index',    :action => 'start'
  map.root               :controller => 'index',    :action => 'index'

  # anything else
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

end

