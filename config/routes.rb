Truthify::Application.routes.draw do |map|
  root :to => "main#index"
  match 'truthify'  => "main#truthify", :as => 'truthify'
  match ':slug(.:format)'     => "main#result",  :as => 'result'
end
