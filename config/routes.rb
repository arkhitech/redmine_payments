resources :projects do
  resources :payments do
    collection do
      get :partial_payment
      post :register
      match :finalize
    end
  end
end

match "/finalize", to: "payments#finalize"