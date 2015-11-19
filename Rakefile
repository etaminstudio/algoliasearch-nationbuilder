require 'dotenv/tasks'
require 'algoliasearch'
require 'csv'
require 'yaml'
require 'nationbuilder'

task :init_config do
  @config = YAML.load_file('config.yml')
end

task :init_algolia => :dotenv do
  Algolia.init :application_id => ENV['ALGOLIA_APP_ID'],
               :api_key        => ENV['ALGOLIA_ADMIN_KEY']
  @algolia = Algolia::Index.new ENV['ALGOLIA_INDEX']
end

task :init_nationbuilder => :dotenv do
  @nationbuilder = NationBuilder::Client.new(ENV['NATIONBUILDER_NATION'], ENV['NATIONBUILDER_API_TOKEN'])
end

# Imports people from NationBuilder to an Algolia index
task :import_people => [:init_config, :init_algolia, :init_nationbuilder] do |t, args|
  puts 'Import all people from NationBuilder'

  response = @nationbuilder.call(:people, :index, limit: 100)
  paginated = NationBuilder::Paginator.new(@nationbuilder, response)

  # Batch import, 100 at a time
  page = 1
  imported = 0
  loop do
    data = paginated.body['results']

    persons = []

    data.each do |line|
      full_name = [line['first_name'], line['last_name']].reject(&:empty?).join(' ')
      puts "Importing person ##{line['id']} (#{full_name})"
      person = @nationbuilder.call(:people, :show, id: line['id'])
      next if person.nil?

      person = person['person']

      # Skip banned
      unless person['banned_at'].nil?
        puts '> skip (banned)'
        next
      end

      person.select! do |key, value|
        @config['allowed_keys'].include? key
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

      persons << person
    end

    @algolia.save_objects(persons)

    imported += persons.length
    puts "#{imported} people imported..."

    if paginated.next?
      sleep 10 # seconds
      page += 1
      paginated = paginated.next
    else
      puts 'Everybody has been imported!'
      break
    end
  end

end

# Imports a CSV file to an Algolia index
# Usage: `rake import_csv[file.csv]`
task :import_csv, [:file] => [:init_config, :init_algolia] do |t, args|
  puts 'Initial import'
  puts "File: #{args.file}"

  # Read the file
  data = CSV.read(args.file)
  puts "#{data.length} lines read"

  keys = data.slice!(0)

  # Batch import, 500 at a time
  while data.length > 0
    if data.length > 500
      batch = data.slice! 0, 500
    else
      batch = data
    end

    batch.map! do |line|
      hash = Hash[keys.zip(line)]
      hash.select! do |key, value|
        @config['allowed_keys'].include? key
      end
      hash['objectID'] = hash['nationbuilder_id']
      hash.delete('nationbuilder_id')
      hash
    end

    res = @algolia.save_objects(batch)

    puts res.inspect
  end

end