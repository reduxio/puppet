require 'puppet/provider/reduxio'
require 'puppet/util/network_device'

Puppet::Type.type(:reduxio_host).provide(:posix,
:parent => Puppet::Provider::Reduxio) do
    desc 'Manage Reduxio Host creation, modification and deletion.'
    confine :feature => :posix

    mk_resource_methods

    INITIATOR_NAME_FILE = "/etc/iscsi/initiatorname.iscsi"


    def self.list_instances(conn_info = nil)
        get_api([conn_info]).transport.list_hosts.each.collect do |vol|
            new(cli_host_to_puppet_host(vol))
        end
    end


    def self.cli_host_to_puppet_host(cli_host)
        return {
            :name               => cli_host["name"],
            :description        => cli_host["description"],
            :ensure             => :present
        }
    end


    def self.get_local_iscsi_name
        raise Puppet::Error, "Failed parsing initiator name file (#{INITIATOR_NAME_FILE})" unless File.exists?(INITIATOR_NAME_FILE)

        File.open(INITIATOR_NAME_FILE).each do |line|
            next unless line.include?('=')
            return line.split('=')[1].strip
        end

        raise Puppet::Error, "Failed parsing initiator name file (#{INITIATOR_NAME_FILE}) for local initiator iscsi name"
    end


    def set_host
        host = transport(conn_info).find_host_by_name(@resource[:name])
        if @property_flush[:ensure] == :absent
            transport(conn_info).delete_host(@resource[:name])
            return nil
        else
            if host
                transport(conn_info).update_host(
                    name=@resource[:name],
                    nil,
                    description=@resource[:description]
                )
            else
                Puppet.debug("Creating new host: #{@resource[:name]}")
                iscsi_name = @resource[:iscsi_name] || self.class.get_local_iscsi_name()
                transport(conn_info).create_host(
                    name=@resource[:name],
                    iscsi_name=iscsi_name,
                    description=@resource[:description]
                )
            end
            return true
        end
    end

    def flush
        if set_host
            @property_hash = self.class.cli_host_to_puppet_host(transport(conn_info).find_host_by_name(@resource[:name]))
        end
    end

end
