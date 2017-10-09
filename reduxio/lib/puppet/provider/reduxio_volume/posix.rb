require 'puppet/provider/reduxio'
require 'puppet/util/network_device'

Puppet::Type.type(:reduxio_volume).provide(:posix,
:parent => Puppet::Provider::Reduxio) do
    desc 'Manage Reduxio Volume creation, modification and deletion.'
    confine :feature => :posix

    mk_resource_methods

    def self.list_instances(conn_info = nil)
        get_api([conn_info]).transport.list_volumes.each.collect do |vol|
            new(rest_vol_to_puppet_vol(vol))
        end
    end

    def self.rest_vol_to_puppet_vol(rest_vol)
        return {
            :name               => rest_vol["name"],
            :size               => "#{rest_vol["size"]["size_in_bytes"] / 1024 / 1024 / 1024}",
            :description        => rest_vol["description"],
            :history_policy     => rest_vol["history_policy_id"],
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
            @property_hash = self.class.rest_vol_to_puppet_vol(transport(conn_info).find_volume_by_name(@resource[:name]))
        end
    end



end
