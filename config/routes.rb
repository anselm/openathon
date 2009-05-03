ActionController::Routing::Routes.draw do |map|

  # http://guides.rubyonrails.org/routing.html

  map.resource  :account, :controller => "users"
  map.resource  :user_session
  map.resources :users
  
  map.resources :teams
  map.start    'start',    :controller => 'team',    :action => 'start'
  map.join     'join',     :controller => 'team',    :action => 'join'
  map.calendar 'calendar', :controller => 'team',    :action => 'calendar'
  map.search   'search',   :controller => 'team',    :action => 'search'
  map.browse   'browse',   :controller => 'team',    :action => 'browse'
  map.teams    'teams',    :controller => 'team',    :action => 'teams'
  map.team     'team',     :controller => 'team',    :action => 'team'

  # map.resources :notes
  # map.connect 'notes/:number', :controller => 'notes', :action => 'search' 
  # map.resources :notes, :collection => { :search => [:get, :post] } 

  # general activities
  # map.donate   'donate', :controller => 'index',    :action => 'donate'
  # map.news     'news',   :controller => 'index',    :action => 'news'
  map.root     :controller => 'index',    :action => 'index'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

end

