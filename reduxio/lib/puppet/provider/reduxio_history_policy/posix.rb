require 'puppet/provider/reduxio'
require 'puppet/util/network_device'

Puppet::Type.type(:reduxio_history_policy).provide(:posix,
:parent => Puppet::Provider::Reduxio) do
    desc 'Manage Reduxio Hostgroup creation, modification and deletion.'
    confine :feature => :posix

    mk_resource_methods


    def self.list_instances(conn_info = nil)
        get_api([conn_info]).transport.list_history_policies.each.collect do |hp|
            new(rest_hp_to_puppet_hp(hp))
        end
    end


    def self.rest_hp_to_puppet_hp(rest_hp)
        return {
            :name               => rest_hp["name"],
            :is_default         => rest_hp["is_default"],
            :seconds            => rest_hp["seconds"],
            :hours              => rest_hp["hours"],
            :days               => rest_hp["days"],
            :weeks              => rest_hp["weeks"],
            :months             => rest_hp["months"],
            :retention          => rest_hp["retention"],
            :ensure             => :present
        }
    end


    def set_hp
        hp = transport(conn_info).find_hp_by_name(@resource[:name])
        if @property_flush[:ensure] == :absent
            return nil
        else
            if hp
                transport(conn_info).update_hp(
                    name=@resource[:name],
                    is_default=@resource[:is_default],
                    seconds=@resource[:seconds],
                    hours=@resource[:hours],
                    days=@resource[:days],
                    weeks=@resource[:weeks],
                    months=@resource[:months],
                    retention=@resource[:retention]
                )
            end
            return true
        end
    end

    def flush
        if set_hp
            @property_hash = self.class.rest_hp_to_puppet_hp(transport(conn_info).find_hp_by_name(@resource[:name]))
        end
    end

end
