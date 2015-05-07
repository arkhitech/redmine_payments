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
    collection do
      get  'shared_invoice/:token' => 'payments#shared_invoice', as: :shared_invoice
      get  'shared_project/:token' => 'payments#shared_project', as: :shared_project
    end
  end
  
  resources :copy_invoices, only: [:index] 
  resources :invoices, only: [] do
    member do
      get :copy
    end
  end
  
end

resources :invoice_payments, only: [:show, :index] do
  collection do
    put '/edit/:id', to: 'invoice_payments#edit'
  end
end
match "/finalize", to: "payments#finalize"

 