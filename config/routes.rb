Poligraft::Application.routes.draw do |map|
  root :to => "main#index"
  match 'poligraft' => "main#poligraft",  :as => 'poligraft'
  match 'about'     => "main#about",      :as => 'about'
  match 'feedback'  => "main#feedback",   :as => 'feedback'
  match ':slug(.:format)' => "main#result",         :as => 'result'
end
