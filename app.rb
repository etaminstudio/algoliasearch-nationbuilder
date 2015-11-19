require 'rubygems'
require 'sinatra'
require 'algoliasearch'
require 'dotenv'
require 'yaml'
require 'nationbuilder'

Dotenv.load

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
  def config
    YAML.load_file(File.join(settings.root, 'config.yml'))
  end

  def valid_token?
    return params['token'] === ENV['NATIONBUILDER_WEBHOOK_TOKEN']
  end

  def check_token!
    unless valid_token?
      halt 403, 'Bad token'
    end
  end

  def algolia_index
    Algolia::Index.new ENV['ALGOLIA_INDEX']
  end

  def person_filtered
    params['payload']['person'].select do |key, value|
      config['allowed_keys'].include? key
    end
  end
end

get '/' do
  'Hello World'
end

post '/people/created' do
  check_token!

  person = person_filtered
  person_without_id = p.tap { |p| p.delete('id') }
  logger.info person.inspect

  index = algolia_index
  res = index.add_object(person_without_id, person['id'])
  logger.info "ObjectID=" + res["objectID"]

  'OK'
end

post '/people/changed' do
  check_token!

  person = person_filtered
  index = algolia_index

  # Delete if banned
  unless person['banned_at'].nil?
    puts '> delete (banned)'
    index.delete_object(person['objectID'])
    halt 200
  end

  # Emails as array
  person['emails'] = []
  (1..5).each do |i|
    person['emails'] << person["email#{i}"]
    person.delete("email#{i}")
  end
  person['emails'] = person['emails'].compact.uniq

  # Geoloc
  unless person['primary_address'].nil? or person['primary_address']['lat'].nil? or person['primary_address']['lng'].nil?
    person['_geoloc'] = {
      lat: person['primary_address']['lat'],
      lng: person['primary_address']['lng']
    }
  end

  # Tags
  person['_tags'] = person['tags']
  person.delete('tags')

  # Set id
  person['objectID'] = person['id']
  person.delete('id')

  logger.info person.inspect

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

  index = algolia_index
  index.delete_object(person['id'])

  'OK'
end