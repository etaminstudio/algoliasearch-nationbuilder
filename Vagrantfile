# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure('2') do |config|

  config.vm.box = 'ubuntu/trusty32'

  config.vm.hostname = 'algoliasearch-nationbuilder.dev'
  config.vm.network :private_network, ip: '192.168.33.98'

  config.vm.provision :shell, path: 'bootstrap.sh', keep_color: true

  config.vm.provider 'virtualbox' do |v|
    v.memory = 1024
    v.cpus = 2
  end
end