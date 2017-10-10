require 'puppet/provider/reduxio'
require 'puppet/util/network_device'
require 'puppet'

Puppet::Type.type(:reduxio_volume_to_hg_assignment).provide(:posix, :parent => Puppet::Provider::Reduxio) do
    desc 'Manage Reduxio volume assignments to hostgroup.'
    confine :feature => :posix

    mk_resource_methods

    def self.list_instances(conn_info = nil)
        transport = get_api([conn_info]).transport
        volumes = transport.list_volumes
        hgs = transport.list_hgs
        transport.list_volume_to_hg_assignments.each.collect do |assgn|
            puppet_assgn = rest_asgn_to_puppet_asgn(assgn, hgs, volumes, transport)
            new(puppet_assgn)
        end
    end

    def self.rest_asgn_to_puppet_asgn(rest_assign, hgs, volumes, transport)
        volume = transport.find_volume_name_by_id(rest_assign["volume_id"], volumes)
        hg = transport.find_hg_name_by_id(rest_assign["hostgroup_id"], hgs)
        return {
            :volume => volume,
            :hg     => hg,
            :name   => "#{volume}/#{hg}",
            :lun    => rest_assign["lun"],
            :ensure => :present
        }
    end

    def parse_volume_name
        @resource[:volume]
    end

    def parse_hg_name
        @resource[:hg]
    end


    def set_assign
        if @property_flush[:ensure] == :absent
            transport(conn_info).unassign(parse_volume_name, nil, hostgroup_name=parse_hg_name)
            return nil
        else
            assgn = transport(conn_info).find_assignment_by_hostgroup(parse_volume_name,parse_hg_name)
            if assgn == nil
                transport(conn_info).assign(vol_name=parse_volume_name, host_name=nil, hostgroup_name=parse_hg_name, lun=@resource[:lun])
            end
            return true
        end
    end

    def flush
        if set_assign
            transport(conn_info).list_volume_to_hg_assignments(vol=parse_volume_name).each do |assign|
                if assign["vol"] == parse_volume_name && assign["hostgroup"] == parse_hg_name
                    @property_hash = self.class.rest_asgn_to_puppet_asgn(assign)
                end
            end
        end
    end


end
