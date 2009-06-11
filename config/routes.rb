ActionController::Routing::Routes.draw do |map|

  # people
  map.resource  :account, :controller => "users"
  map.resource  :user_session
  map.resources :users
  map.signup    'signup',      :controller => 'users',           :action => 'new'
  map.signin    'signin',      :controller => 'user_sessions',   :action => 'new'
  map.signout   'signout',     :controller => 'user_sessions',   :action => 'destroy'

  # passwords
  map.password_resets 'password_resets', :controller => 'password_resets', :action => 'create'
  map.edit_password_reset 'password_reset/:id', :controller => 'password_resets', :action => 'edit'

  # teams
  map.resources :teams
  map.invite   'invite/:id',  :controller => 'teams',    :action => 'invite'
  map.join     'join',        :controller => 'teams',    :action => 'join'
  map.leave    'leave',       :controller => 'teams',    :action => 'leave'
  map.calendar 'calendar',    :controller => 'teams',    :action => 'calendar'
  map.search   'search',      :controller => 'teams',    :action => 'teams'
  map.teams    'teams',       :controller => 'teams',    :action => 'teams'
 
  # money
  map.sponsor  'sponsor/:id', :controller => 'payment',  :action => 'sponsor'
  map.payment  'payment/:id', :controller => 'payment',  :action => 'sponsor'
  map.checkout 'checkout',    :controller => 'payment',  :action => 'checkout'
  map.confirm  'confirm',     :controller => 'payment',  :action => 'confirm'
  map.donate   'donate/:id',  :controller => 'payment',  :action => 'donate'
  map.complete 'complete',    :controller => 'payment',  :action => 'complete'

  # general activities
  map.admin    'admin',  :controller => 'index',    :action => 'admin'
  map.news     'news',   :controller => 'index',    :action => 'news'
  map.root               :controller => 'index',    :action => 'index'

  # anything else
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

end

