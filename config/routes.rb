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
      post :generate_project_invoice_token
      post :generate_invoice_payment_token
    end
    member do
      match :finalize      
    end
  end
  #  resources :invoice_payments
end
 resources :payments, only: [] do
  collection do
    get  'shared_invoice/:token' => 'payments#shared_invoice', as: :shared_invoice
   
  end
end
  resources :payments, only: [] do
  collection do
    get  'shared_project/:token' => 'payments#shared_project', as: :shared_project
  end
end

resources :invoice_payments, only: [:show, :index] do
  collection do
    put '/edit/:id', to: 'invoice_payments#edit'
  end
end
match "/finalize", to: "payments#finalize"


