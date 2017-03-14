require 'puppet/provider/reduxio'
require 'puppet/util/network_device'

Puppet::Type.type(:reduxio_volume).provide(:posix,
:parent => Puppet::Provider::Reduxio) do
    desc 'Manage Reduxio Volume creation, modification and deletion.'
    confine :feature => :posix

    mk_resource_methods

    def self.list_instances(conn_info = nil)
        get_api([conn_info]).transport.list_volumes.each.collect do |vol|
            new(cli_vol_to_puppet_vol(vol))
        end
    end

    def self.cli_vol_to_puppet_vol(cli_vol)
        return {
            :name               => cli_vol["name"],
            :size               => "#{cli_vol["size"] / 1024 / 1024 / 1024}",
            :description        => cli_vol["description"],
            :history_policy     => cli_vol["policy"],
            :blocksize          => "#{cli_vol["blocksize"]}",
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
                transport(conn_info).update_volume(
                    name=@resource[:name],
                    nil,
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
            @property_hash = self.class.cli_vol_to_puppet_vol(transport(conn_info).find_volume_by_name(@resource[:name]))
        end
    end



end
