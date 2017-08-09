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
    raise ArgumentError, "#{ARG_ERROR_PREFIX} Invalid scheme #{@url.scheme}. Must be https" 	unless @url.scheme == 'https'
    raise ArgumentError, "#{ARG_ERROR_PREFIX} no auth token specified" 				unless @url.user
    Puppet.debug("Reduxio network deviced called with host '#{@url.host}'")
    @transport = RdxCliAPI.new(@url.host, @url.user)
  end


  def facts
    @facts ||= {}
  end

end