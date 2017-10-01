require 'puppet/provider/reduxio'
require 'puppet/util/network_device'
require 'puppet'

Puppet::Type.type(:reduxio_volume_to_hg_assignmnet).provide(:posix, :parent => Puppet::Provider::Reduxio) do
    desc 'Manage Reduxio volume assignments to hostgroup.'
    confine :feature => :posix

    mk_resource_methods

    def self.list_instances(conn_info = nil)
        get_api([conn_info]).transport.list_assignments.each.collect do |vol|
            new(rest_asgn_to_puppet_asgn(vol))
        end
    end


    def self.rest_asgn_to_puppet_asgn(rest_assign)
        return {
            :volume => rest_assign["vol"],
            :hg   => rest_assign["hostgroup"],
            :name   => "#{rest_assign["vol"]}/#{rest_assign["hg"]}",
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
            transport(conn_info).unassign(parse_volume_name, hostgroup_name=parse_hg_name)
            return nil
        else
            assgn = transport(conn_info).find_assignment_by_hostgroup(parse_volume_name,parse_hg_name)
            Puppet.debug("assgn=#{assgn}")
            if assgn == nil
                Puppet.debug("inoam after find asgn=nil")
                transport(conn_info).assign(vol_name=parse_volume_name, host_name=nil, hostgroup_name=parse_hg_name, lun=@resource[:lun])
                Puppet.debug("inoam here")
            end
            return true
        end
    end

    def flush
        if set_assign
            transport(conn_info).list_assignments(vol=parse_volume_name).each do |assign|
                if assign["vol"] == parse_volume_name && assign["hostgroup"] == parse_hg_name
                    @property_hash = self.class.rest_asgn_to_puppet_asgn(assign)
                end
            end
        end
    end


end
