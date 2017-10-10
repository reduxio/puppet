require 'puppet/provider/reduxio'
require 'puppet/util/network_device'

Puppet::Type.type(:reduxio_volume).provide(:posix,
:parent => Puppet::Provider::Reduxio) do
    desc 'Manage Reduxio Volume creation, modification and deletion.'
    confine :feature => :posix

    mk_resource_methods

    def self.list_instances(conn_info = nil)
        tmp_transport = get_api([conn_info]).transport
        hps = tmp_transport.list_history_policies
        tmp_transport.list_volumes.each.collect do |vol|
            new(rest_vol_to_puppet_vol(vol, hps, tmp_transport))
        end
    end

    def self.rest_vol_to_puppet_vol(rest_vol, hps, tmp_transport)
        hp = tmp_transport.find_hp_name_by_id(rest_vol["history_policy_id"], hps)
        return {
            :name               => rest_vol["name"],
            :size               => "#{rest_vol["size"]["size_in_bytes"] / 1024 / 1024 / 1024}",
            :description        => rest_vol["description"],
            :history_policy     => hp,
            :blocksize          => "#{rest_vol["block_size"]}",
            :ensure             => :present
        }
    end


    def set_volume
        if @property_flush[:ensure] == :absent
            transport(conn_info).delete_volume(@resource[:name])
            return nil
        else
            volume = transport(conn_info).find_volume_by_name(@resource[:name])
            if volume
                if (not @resource[:blocksize].nil?) && volume["block_size"].to_s != @resource[:blocksize].to_s
                  raise Puppet::Error, "Cannot update blocksize for volume '#{volume["name"]}', Blocksize is #{volume["block_size"]}, requested to update to #{@resource[:blocksize]}"
                end
                transport(conn_info).update_volume(
                    name=@resource[:name],
                    description=@resource[:description],
                    size=@resource[:size],
                    history_policy=@resource[:history_policy]
                )
            else
                Puppet.debug("Creating new volume: #{@resource[:name]}")
                transport(conn_info).create_volume(
                    name=@resource[:name],
                    size=@resource[:size],
                    description=@resource[:description],
                    history_policy=@resource[:history_policy],
                    blocksize=@resource[:blocksize]
                )
            end
            return true
        end
    end

    def flush
        if set_volume
            tmp_transport = transport(conn_info)
            hps = tmp_transport.list_history_policies
            @property_hash = self.class.rest_vol_to_puppet_vol(transport(conn_info).find_volume_by_name(@resource[:name]), hps, tmp_transport)
        end
    end



end
