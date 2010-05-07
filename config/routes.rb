Truthify::Application.routes.draw do |map|
  root :to => "main#index"
  match 'truthify'  => "main#truthify", :as => 'truthify'
  match ':slug'     => "main#result",  :as => 'result'
end
