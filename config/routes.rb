Poligraft::Application.routes.draw do
  root :to => "main#index"
  match 'poligraft' => "main#poligraft", :as => 'poligraft', :via => [:get, :post, :options]
  match 'plucked' => "main#plucked", :as => 'plucked'
  match 'about' => "main#about", :as => 'about'
  match 'feedback' => "main#feedback", :as => 'feedback'
  match 'thanks' => "main#thanks", :as => 'thanks'
  match ':slug(.:format)' => "main#result", :as => 'result'
  match ':slug/widget(.:format)' => "main#result_widget", :as => 'result_widget', :via => [:get]
end
