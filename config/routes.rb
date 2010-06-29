Poligraft::Application.routes.draw do |map|
  root :to => "main#index"
  match 'poligraft'  => "main#poligraft", :as => 'poligraft'
  match ':slug(.:format)'     => "main#result",  :as => 'result'
end
