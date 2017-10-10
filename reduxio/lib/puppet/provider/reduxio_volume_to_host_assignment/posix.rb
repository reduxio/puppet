require 'puppet/provider/reduxio'
require 'puppet/util/network_device'
require 'puppet'

Puppet::Type.type(:reduxio_volume_to_host_assignment).provide(:posix, :parent => Puppet::Provider::Reduxio) do
    desc 'Manage Reduxio volume assignments to host.'
    confine :feature => :posix

    mk_resource_methods

    def self.list_instances(conn_info = nil)
        transport = get_api([conn_info]).transport
        volumes = transport.list_volumes
        hosts = transport.list_hosts
        transport.list_volume_to_host_assignments.each.collect do |assgn|
            puppet_assgn = rest_asgn_to_puppet_asgn(assgn, hosts, volumes, transport)
            new(puppet_assgn)
        end
    end


    def self.rest_asgn_to_puppet_asgn(rest_assign, hosts, volumes, transport)
        volume = transport.find_volume_name_by_id(rest_assign["volume_id"], volumes)
        host = transport.find_host_name_by_id(rest_assign["host_id"], hosts)
        return {
            :volume => volume,
            :host   => host,
            :name   => "#{volume}/#{host}",
            :lun    => rest_assign["lun"],
            :ensure => :present
        }
    end

    def parse_volume_name
        @resource[:volume]
    end

    def parse_host_name
        @resource[:host]
    end


    def set_assign
        if @property_flush[:ensure] == :absent
            transport(conn_info).unassign(parse_volume_name, host_name=parse_host_name)
            return nil
        else
            assgn = transport(conn_info).find_assignment_by_host(parse_volume_name,parse_host_name)
            if assgn == nil
                transport(conn_info).assign(vol_name=parse_volume_name, host_name=parse_host_name, lun=@resource[:lun])
            end
            return true
        end
    end

    def flush
        if set_assign
            transport(conn_info).list_volume_to_host_assignments(vol=parse_volume_name).each do |assign|
                if assign["vol"] == parse_volume_name && assign["host"] == parse_host_name
                    @property_hash = self.class.rest_asgn_to_puppet_asgn(assign)
                end
            end
        end
    end


end
