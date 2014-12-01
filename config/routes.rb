resources :projects do
  
  resources :invoice_payments, only: [:show, :index] do
    collection do
      put '/edit/:id', to: 'invoice_payments#edit'
    end
  end

  resources :payments do
    collection do
      get :generate
      post :register
    end
    member do
      match :finalize      
    end
  end
  
  #  resources :invoice_payments
end


resources :invoice_payments, only: [:show, :index] do
  collection do
    put '/edit/:id', to: 'invoice_payments#edit'
  end
end
match "/finalize", to: "payments#finalize"


