resources :projects do
  
  resources :invoice_payments do
      collection do
#    get '/invoice_payments/:id', to: 'invoice_payments#show'
#    
#    get '/invoice_payments', to: 'invoice_payments#index'
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


resources :invoice_payments do
  collection do
#    get '/invoice_payments/:id', to: 'invoice_payments#show'
#    
#    get '/invoice_payments', to: 'invoice_payments#index'
    put '/edit/:id', to: 'invoice_payments#edit'
    

end
end
#match "/invoice_payments/show", to: "invoice_payments#show"
match "/finalize", to: "payments#finalize"

#match '/invoice_payments/view' => 'invoice_payments#view'