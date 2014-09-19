resources :projects do
  resources :payments do
    collection do
      get :generate
      post :register
    end
    member do
      match :finalize      
    end
  end
end

match "/finalize", to: "payments#finalize"