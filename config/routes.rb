resources :projects do
  resources :payments do
    collection do
      get :partial_payment
      get :register
      get :finalize
    end
  end
end

match "/finalize", to: "payments#finalize"