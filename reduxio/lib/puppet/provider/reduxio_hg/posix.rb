require 'puppet/provider/reduxio'
require 'puppet/util/network_device'

Puppet::Type.type(:reduxio_hg).provide(:posix,
:parent => Puppet::Provider::Reduxio) do
    desc 'Manage Reduxio Hostgroup creation, modification and deletion.'
    confine :feature => :posix

    mk_resource_methods


    def self.list_instances(conn_info = nil)
        get_api([conn_info]).transport.list_hgs.each.collect do |hg|
            new(rest_hg_to_puppet_hg(hg))
        end
    end


    def self.rest_hg_to_puppet_hg(rest_hg)
        return {
            :name               => rest_hg["name"],
            :description        => rest_hg["description"],
            :ensure             => :present
        }
    end


    def set_hg
        hg = transport(conn_info).find_hg_by_name(@resource[:name])
        if @property_flush[:ensure] == :absent
            Puppet.debug("Deleting host: #{@resource[:name]}")
            transport(conn_info).delete_hg(@resource[:name])
            return nil
        else
            if hg
                transport(conn_info).update_hg(
                    name=@resource[:name],
                    description=@resource[:description]
                )
            else
                Puppet.debug("Creating new hg: #{@resource[:name]}")
                transport(conn_info).create_hg(
                    name=@resource[:name],
                    description=@resource[:description]
                )
            end
            return true
        end
    end

    def flush
        if set_hg
            @property_hash = self.class.rest_hg_to_puppet_hg(transport(conn_info).find_hg_by_name(@resource[:name]))
        end
    end

end
