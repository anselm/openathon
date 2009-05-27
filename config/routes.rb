ActionController::Routing::Routes.draw do |map|

  # http://guides.rubyonrails.org/routing.html

  map.resource  :account, :controller => "users"
  map.resource  :user_session
  map.resources :users
  map.signup    'signup',      :controller => 'users',           :action => 'new'
  map.signin    'signin',      :controller => 'user_sessions',   :action => 'new'
  map.signout   'signout',     :controller => 'user_sessions',   :action => 'destroy'

  map.resources :teams
  map.invite   'invite/:id',  :controller => 'teams',    :action => 'invite'
  map.join     'join',        :controller => 'teams',    :action => 'join'
  map.leave    'leave',       :controller => 'teams',    :action => 'leave'
  map.calendar 'calendar',    :controller => 'teams',    :action => 'calendar'
  map.search   'search',      :controller => 'teams',    :action => 'search'
  map.teams    'teams',       :controller => 'teams',    :action => 'teams'

  # map.resources :notes
  # map.connect 'notes/:number', :controller => 'notes', :action => 'search' 
  # map.resources :notes, :collection => { :search => [:get, :post] }

  # Payment related
  map.payment  'payment/:id', :controller => 'payment', :action => 'index'
  map.donate   'donate', :controller => 'payment',    :action => 'donate'

  # general activities
  map.admin    'admin',  :controller => 'index',    :action => 'admin'
  map.news     'news',   :controller => 'index',    :action => 'news'
  map.root               :controller => 'index',    :action => 'index'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

end

