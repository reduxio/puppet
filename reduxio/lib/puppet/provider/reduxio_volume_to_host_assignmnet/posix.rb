require 'puppet/provider/reduxio'
require 'puppet/util/network_device'
require 'puppet'

Puppet::Type.type(:reduxio_volume_to_host_assignmnet).provide(:posix, :parent => Puppet::Provider::Reduxio) do
    desc 'Manage Reduxio volume assignments to host.'
    confine :feature => :posix

    mk_resource_methods

    def self.list_instances(conn_info = nil)
        get_api([conn_info]).transport.list_assignments.each.collect do |vol|
            new(cli_asgn_to_puppet_asgn(vol))
        end
    end


    def self.cli_asgn_to_puppet_asgn(cli_assign)
        return {
            :volume => cli_assign["vol"],
            :host   => cli_assign["host"],
            :name   => "#{cli_assign["vol"]}/#{cli_assign["host"]}",
            :lun    => cli_assign["lun"],
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
            transport(conn_info).assign(vol_name=parse_volume_name, host_name=parse_host_name, lun=@resource[:lun])
            return true
        end
    end

    def flush
        if set_assign
            transport(conn_info).list_assignments(vol=parse_volume_name).each do |assign|
                if assign["vol"] == parse_volume_name && assign["host"] == parse_host_name
                    @property_hash = self.class.cli_asgn_to_puppet_asgn(assign)
                end
            end
        end
    end


end
