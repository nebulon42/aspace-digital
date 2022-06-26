Rails.application.routes.draw do
  scope AppConfig[:public_proxy_prefix] do
    get '/ebook/retrieve/:url' => 'ebook_reader#retrieve'
    get '/reader' => 'ebook_reader#show'
  end
end