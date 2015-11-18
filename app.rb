require 'rubygems'
require 'sinatra'
require 'algoliasearch'

Algolia.init :application_id => ENV['ALGOLIA_APP_ID'],
             :api_key        => ENV['ALGOLIA_ADMIN_KEY']

before do

  # Parse JSON in body
  if request.body.size > 0
    request.body.rewind
    @params = JSON.parse request.body.read
  end

end


helpers do
  def valid_token?
    return params['token'] === ENV['NATIONBUILDER_WEBHOOK_TOKEN']
  end

  def check_token!
    unless valid_token?
      halt 403, 'Bad token'
    end
  end

  def algolia_index(name)
    Algolia::Index.new(name)
  end
end

get '/' do
  "Hello from Sinatra on Heroku!"
end

post '/people/created' do
  check_token!

  person = params['payload']['person']
  logger.info person.inspect

  index = algolia_index 'people'
  res = index.add_object(people)
  logger.info "ObjectID=" + res["objectID"]

  'OK'
end

post '/people/changed' do
  check_token!

  person = params['payload']['person']

  logger.info person.inspect

  'People changed'
end

post '/people/merged' do
  check_token!

  person = params['payload']['person']

  logger.info person.inspect

  'People merged'
end

post '/people/deleted' do
  check_token!

  person = params['payload']['person']

  logger.info person.inspect

  'People deleted'
end