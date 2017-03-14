require 'puppet/util/network_device'
require 'puppet/rdx_cli_api'
require 'puppet/util/network_device/reduxio'
require 'uri'

class Puppet::Util::NetworkDevice::Reduxio::Device

  attr_accessor :transport

  ARG_ERROR_PREFIX = "Reduxio Network device:"
  
  def initialize(url, other = nil)
    Puppet.debug("Reduxio network device initialized with url: #{url}, other: #{other}")
  	@url = URI.parse(url)
    raise ArgumentError, "#{ARG_ERROR_PREFIX} Invalid scheme #{@url.scheme}. Must be ssh" 	unless @url.scheme == 'ssh'
    raise ArgumentError, "#{ARG_ERROR_PREFIX} no user specified" 				unless @url.user
    raise ArgumentError, "#{ARG_ERROR_PREFIX} no password specified" 		unless @url.password
    Puppet.debug("Reduxio network deviced called with host '#{@url.host}'")
    @transport = RdxCliAPI.new(@url.host, @url.user, @url.password)
  end


  def facts
    @facts ||= {}
  end

end