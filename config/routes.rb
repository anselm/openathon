ActionController::Routing::Routes.draw do |map|

  # http://guides.rubyonrails.org/routing.html

  map.resource  :account, :controller => "users"
  map.resource  :user_session

  map.resources :users

  # map.resources :notes
  # map.connect 'notes/:number', :controller => 'notes', :action => 'search' 
  map.resources :notes, :collection => { :search => [:get, :post] } 

  map.root :controller => 'index', :action => 'index'

  map.connect ':controller/:action/:id'
  map.connect ':controller/:action/:id.:format'

end

