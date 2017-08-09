require 'puppet/provider'
require 'puppet/util/network_device'
require 'puppet/util/network_device/reduxio/device'

class Puppet::Provider::Reduxio < Puppet::Provider

  @@transports = {}

  def self.transport(args=nil)
    @device ||= get_api(args)
    @transport = @device.transport
  end

  def self.get_api(args = nil)
    dev = Puppet::Util::NetworkDevice.current
    if not dev and Facter.value(:url)
      dev ||= Puppet::Util::NetworkDevice::Reduxio::Device.new(Facter.value(:url))
    elsif not dev and args and args.length == 1 and !args[0].nil?
      dev ||= Puppet::Util::NetworkDevice::Reduxio::Device.new(args[0])
    elsif not dev and ENV['RDX_PUPPET_TRANSPORT_URL']
      dev ||= Puppet::Util::NetworkDevice::Reduxio::Device.new(ENV['RDX_PUPPET_TRANSPORT_URL'])
    end
    raise Puppet::Error, "#{self.class} : device not initialized #{caller.join("\n")}" unless dev
    return dev
  end



  def self.prefetch(resources)
    resources_by_url = {}
    resources.each do |name, resource|
      url = resource[:url] || nil
      (resources_by_url[url] ||= {})[name] = resource
    end

    resources_by_url.each do |url, url_resources|
      list_instances(url).each do |instance|
        found_resource = url_resources[instance.name]
        if found_resource
          found_resource.provider = instance
        end
      end
    end
  end

  def self.instances
    list_instances(nil)
  end


  def initialize(value={})
    super(value)
    @property_flush = {}
  end

  def create
    @property_flush[:ensure] = :present
  end

  def destroy
    @property_flush[:ensure] = :absent
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def transport(*args)
    if args[0]
      (@@transports[args[0]] ||= self.class.get_api(args)).transport
    else
      self.class.transport(args)
    end
  end

  def method_missing(name, *args)
    self.class.method_missing(name, args)
  end

  def conn_info
    return resource[:url] if resource[:url]
    return nil
  end

end