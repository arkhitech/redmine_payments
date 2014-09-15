resources :payments do
  member do
    get :make_payment
    post :show_payment
  end
end

resources :transactions
