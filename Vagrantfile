Vagrant.configure("2") do |config|
  config.vm.box = "precise32"
  config.vm.hostname = "codesite-dev"
  config.vm.provision :shell, :path => "config/bootstrap.sh"
  config.vm.network :forwarded_port, host: 8083, guest: 80
end
