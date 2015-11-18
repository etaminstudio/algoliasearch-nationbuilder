require 'rubygems'
require 'sinatra'
require 'http'

get '/' do
  "Hello from Sinatra on Heroku!"
end

post '/people/created' do
  'People created'
end

post '/people/changed' do
  'People changed'
end

post '/people/deleted' do
  'People deleted'
end