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

  def allowed_keys
    %w{
    id
    email email1 email2 email3 email4
    username
    first_name last_name full_name
    primary_address
    tags
    bio occupation profile_content
    twitter_login
    facebook_username facebook_profile_url
    linkedin_id
    website
    profile_image_url_ssl
    }
  end

  def person_filtered
    person = params['payload']['person'].select do |key, value|
      allowed_keys.include? key
    end
  end
end

get '/' do
  "Hello from Sinatra on Heroku!"
end

post '/people/created' do
  check_token!

  person = person_filtered
  person_without_id = p.tap { |p| p.delete('id') }
  logger.info person.inspect

  index = algolia_index 'people'
  res = index.add_object(person_without_id, person['id'])
  logger.info "ObjectID=" + res["objectID"]

  'OK'
end

post '/people/changed' do
  check_token!

  person = person_filtered
  person['objectID'] = person['id']
  person.delete('id')
  logger.info person.inspect

  index = algolia_index 'people'
  index.save_object(person)

  'OK'
end

post '/people/merged' do
  check_token!

  logger.info params.inspect

  person = person_filtered
  logger.info person.inspect

  'OK'
end

post '/people/deleted' do
  check_token!

  person = person_filtered
  logger.info person.inspect

  index = algolia_index 'people'
  index.delete_object(person['id'])

  'OK'
end