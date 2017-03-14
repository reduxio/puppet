# Copyright (c) 2016 reduxio Systems
# All Rights Reserved.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.


require 'json'
require 'net/ssh'
require 'time'

VOLUMES                     = 'volumes'
TIME                        = 'time'
HOSTS                       = 'hosts'
HG_DIR                      = 'hostgroups'
NEW_COMMAND                 = 'new'
UPDATE_COMMAND              = 'update'
LS_COMMAND                  = 'ls'
DELETE_COMMAND              = 'delete'
LIST_ASSIGN_CMD             = 'list-assignments'
CLI_DATE_FORMAT             = '%m/%d/%Y-%H:%M:%S'

class RdxApiCmd

    def initialize(cmd_prefix, argument=nil, flags=nil, boolean_flags=nil, forcecmd=nil)
        if cmd_prefix.instance_of?(Array)
            cmd_prefix.collect { |x| x.strip! || x }
            @cmd = cmd_prefix.join(' ')
        end
        @arg = nil
        @flags = {}
        @booleanflags = {}
        if argument
            argument(argument)
        end
        if flags
            if flags.instance_of?(Array)
                flags.each do |flag|
                    flag(flag[0], flag[1])
                end
            else
                flags.each do |key, value|
                    flag(key, value)
                end
            end
        end
        if boolean_flags
            boolean_flags.each do |boolean_flag|
                boolean_flag(boolean_flag)
            end
        end
        if forcecmd
            force
        end
    end

    def argument(argument)
        @arg = argument
    end

    def flag(name, value)
        if value
            @flags[name.strip] = value
        end
    end

    def boolean_flag(name)
        if name
            @booleanflags[name.strip] = true
        end
    end

    def force
        boolean_flag('force')
    end

    def set_json_output
        flag('output', 'json')
    end

    def build
        argument_string = '' unless argument_string = @arg
        flags_str = ''
        @flags.sort.each do |key, value|
            flags_str += " -#{key} \"#{value}\""
        end
        @booleanflags.sort.each do |key, value|
            flags_str += " -#{key}"
        end
        "#{@cmd} #{argument_string} #{flags_str}"
    end

end

class RdxCliAPI

    def initialize(rdx_ip, rdx_username, rdx_password)
        @host = rdx_ip
        @password = rdx_password
        @username = rdx_username
        _connect
    end

    def _connect
        begin
            Puppet.debug("creating new ssh session to #{@host}")
            @rdx_ssh_connect = Net::SSH.start(@host, @username, :password => @password)
        rescue Exception => e
            raise Puppet::Error, "Failed connecting to Reduxio CLI: (Error: #{e.class}, message: #{e.message})"
        end
    end

    def run_cmd(cmd)
        cmd.set_json_output
        begin
            output = @rdx_ssh_connect.exec!(cmd.build)
        rescue
            raise
        end
        json_output = nil

        begin
            json_output = JSON.parse(output)
        rescue Exception => e
            raise Puppet::Error, "Failed parsing Reduxio CLI JSON output (cmd:'#{cmd.build}'. Error: #{e.class}, message: #{e.message})"
        end

        if json_output["rc"] != 0
            raise Puppet::Error, "Failed Running Reduxio CLI Command: '#{cmd.build}'. Error message: #{json_output["msg"]}"
        end

        return json_output['data']

    end

    def list_volumes
        run_cmd(cmd=RdxApiCmd.new(cmd_prefix=[VOLUMES, LS_COMMAND]))["volumes"]
    end

    def find_volume_by_name(volname)
        list_volumes.each do |vol|
            return vol if vol["name"] == volname
        end
        return nil
    end

    def find_volume_by_wwid(wwid)
        cmd = RdxApiCmd.new(cmd_prefix=[VOLUMES, 'find-by-wwid'])
        cmd.argument(wwid)
        run_cmd(cmd=cmd)
    end

    def update_volume(name, new_name=nil, description=nil, size=nil, history_policy=nil)
        cmd = RdxApiCmd.new(cmd_prefix=[VOLUMES, UPDATE_COMMAND])
        cmd.argument(name)
        cmd.flag('size', size)
        cmd.flag('new-name', new_name)
        cmd.flag('policy', history_policy)
        cmd.flag('description', description)
        run_cmd(cmd=cmd)
    end

    def create_volume(name, size=nil, description=nil, history_policy=nil, blocksize=nil)
        cmd = RdxApiCmd.new(cmd_prefix=[VOLUMES, NEW_COMMAND])
        cmd.argument(name)
        cmd.flag('size', size)
        cmd.flag('description', description)
        cmd.flag('policy', history_policy)
        cmd.flag('blocksize', blocksize)
        run_cmd(cmd=cmd)
    end

    def delete_volume(name)
        cmd = RdxApiCmd.new(cmd_prefix=[VOLUMES, DELETE_COMMAND])
        cmd.argument(name)
        cmd.force
        run_cmd(cmd=cmd)
    end

    def revert_volume(name, utc_date=nil, bookmark_name=nil)
        cmd = RdxApiCmd.new(cmd_prefix=[VOLUMES, 'revert'])
        cmd.argument(name)
        cmd.flag('timestamp', utc_date)
        cmd.flag('bookmark', bookmark_name)
        cmd.force
        run_cmd(cmd=cmd)
    end

    def clone_volume(parent_name, clone_name, str_date=nil, bookmark_name=nil, description=nil)
        cmd = RdxApiCmd.new(cmd_prefix=[VOLUMES, 'clone'])
        cmd.argument(parent_name)
        cmd.flag('name', clone_name)
        cmd.flag('timestamp', str_date)
        cmd.flag('bookmark', bookmark_name)
        cmd.flag('description', description)
        run_cmd(cmd=cmd)
    end

    def get_current_time
        (run_cmd(cmd=RdxApiCmd.new(cmd_prefix=[TIME]))[0]['time'].split(' ').take 2).join(' ')
    end

    def list_vol_bookmarks(vol)
        cmd = RdxApiCmd.new(cmd_prefix=[VOLUMES, 'list-bookmarks'])
        cmd.argument(vol)
        run_cmd(cmd=cmd)
    end

    def get_vol_bookmark(vol, bm_name)
        bookmarks = list_vol_bookmarks(vol=vol)
        bookmarks.each do |bookmark|
            return bookmark if bookmark['name'] == bm_name
        end
        false
    end

    def add_vol_bookmark(vol, bm_name, str_date=nil, bm_type=nil)
        str_date = Time.parse(get_current_time).strftime(CLI_DATE_FORMAT) if (!str_date) || str_date.downcase == 'now'
        cmd = RdxApiCmd.new(cmd_prefix=[VOLUMES, 'bookmark'])
        cmd.argument(vol)
        cmd.flag('name', bm_name)
        cmd.flag('timestamp', str_date)
        if bm_type && bm_type.downcase == 'manual'
            bm_type = 'Manual'
        else
            bm_type = 'Automatic'
        end
        cmd.flag('type', bm_type)
        run_cmd(cmd=cmd)
    end

    def delete_vol_bookmark(vol, bm_name)
        cmd = RdxApiCmd.new(cmd_prefix=[VOLUMES, 'delete-bookmark'])
        cmd.argument(vol)
        cmd.flag('name', bm_name)
        run_cmd(cmd=cmd)
    end

    def modify_vol_bookmark(vol, bm_name, new_name=nil, bm_type=nil)
        cmd = RdxApiCmd.new(cmd_prefix=[VOLUMES, 'modify-bookmark'])
        cmd.argument(vol)
        cmd.flag('name', bm_name)
        cmd.flag('new-name', new_name)
        cmd.flag('type', bm_type)
        run_cmd(cmd=cmd)
    end

    def list_hosts
        run_cmd(RdxApiCmd.new(cmd_prefix=[HOSTS, LS_COMMAND]))['hosts']
    end

    def find_host_by_iqn(iqn)
        list_hosts.each do |host1|
            if host1['iscsi_name'] == iqn
                return host1
            end
        end
        nil
    end

    def find_host_by_name(hostname)
        list_hosts.each do |host|
            return host if host["name"] == hostname
        end
        return nil
    end

    def create_host(name, iscsi_name, description=nil)
        cmd = RdxApiCmd.new(cmd_prefix=[HOSTS, NEW_COMMAND])
        cmd.argument(name)
        cmd.flag('iscsi-name', iscsi_name)
        cmd.flag('description', description)
        run_cmd(cmd=cmd)
    end

    def delete_host(name)
        cmd = RdxApiCmd.new(cmd_prefix=[HOSTS, DELETE_COMMAND])
        cmd.argument(name)
        cmd.force
        run_cmd(cmd=cmd)
    end

    def update_host(name, new_name=nil, description=nil)
        cmd = RdxApiCmd.new(cmd_prefix=[HOSTS, UPDATE_COMMAND])
        cmd.argument(name)
        cmd.flag('new-name', new_name)
        cmd.flag('description', description)
        run_cmd(cmd=cmd)
    end

    def list_hostgroups
        run_cmd(cmd=RdxApiCmd.new(cmd_prefix=[HG_DIR, LS_COMMAND]))
    end

    def find_hostgroup_by_name(hostgroup)
        cmd = RdxApiCmd.new(cmd_prefix=[LS_COMMAND, HG_DIR + '/' + hostgroup])
        hostgroup1 = run_cmd(cmd=cmd)
        if hostgroup1
            hostgroup1 = hostgroup1['hostgroups'][0]
        end
        hostgroup1
    end

    def create_hostgroup(name, description=nil)
        cmd = RdxApiCmd.new(cmd_prefix=[HG_DIR, NEW_COMMAND])
        cmd.argument(name)
        cmd.flag('description', description)
        run_cmd(cmd=cmd)
    end

    def delete_hostgroup(name)
        cmd = RdxApiCmd.new(cmd_prefix=[HG_DIR, DELETE_COMMAND])
        cmd.argument(name)
        cmd.force
        run_cmd(cmd=cmd)
    end

    def update_hostgroup(name, new_name=nil, description=nil)
        cmd = RdxApiCmd.new(cmd_prefix=[HG_DIR, UPDATE_COMMAND])
        cmd.argument(name)
        cmd.flag('new-name', new_name)
        cmd.flag('description', description)
        run_cmd(cmd=cmd)
    end

    def list_hosts_in_hostgroup(name)
        cmd = RdxApiCmd.new(cmd_prefix=[HG_DIR, 'list-hosts'])
        cmd.argument(name)
        run_cmd(cmd=cmd)
    end

    def add_host_to_hostgroup(name, host_name)
        cmd = RdxApiCmd.new(cmd_prefix=[HG_DIR, 'add-host'])
        cmd.argument(name)
        cmd.flag('host', host_name)
        run_cmd(cmd=cmd)
    end

    def remove_host_from_hostgroup(name, host_name)
        cmd = RdxApiCmd.new(cmd_prefix=[HG_DIR, 'remove-host'])
        cmd.argument(name)
        cmd.flag('host', host_name)
        run_cmd(cmd=cmd)
    end

    def add_hg_bookmark(hg_name, bm_name, str_date=nil, bm_type=nil)
        str_date = Time.parse(get_current_time).strftime(CLI_DATE_FORMAT) if (!str_date) || str_date.downcase == 'now'
        cmd = RdxApiCmd.new(cmd_prefix=[HG_DIR, 'add-bookmark'])
        cmd.argument(hg_name)
        cmd.flag('name', bm_name)
        cmd.flag('timestamp', str_date)
        cmd.flag('type', bm_type)
        run_cmd(cmd=cmd)
    end

    def assign(vol_name, host_name=nil, hostgroup_name=nil, lun=nil)
        cmd = RdxApiCmd.new(cmd_prefix=[VOLUMES, 'assign'])
        cmd.argument(vol_name)
        cmd.flag('host', host_name)
        cmd.flag('group', hostgroup_name)
        cmd.flag('lun', lun)
        run_cmd(cmd=cmd)
    end

    def unassign(vol_name, host_name=nil, hostgroup_name=nil)
        cmd = RdxApiCmd.new(cmd_prefix=[VOLUMES, 'unassign'])
        cmd.argument(vol_name)
        cmd.flag('host', host_name)
        cmd.flag('group', hostgroup_name)
        run_cmd(cmd=cmd)
    end

    def list_assignments(vol=nil, host=nil, hg=nil)
        cmd = RdxApiCmd.new(cmd_prefix=[VOLUMES, LIST_ASSIGN_CMD])
        if vol
            cmd.argument(vol)
        elsif host
            cmd = RdxApiCmd(cmd_prefix=[HOSTS, LIST_ASSIGN_CMD])
            cmd.argument(host)
        elsif hg
            cmd = RdxApiCmd(cmd_prefix=[HG_DIR, LIST_ASSIGN_CMD])
            cmd.argument(hg)
        end
        run_cmd(cmd=cmd)
    end

    def get_settings
        cli_hash = run_cmd(cmd=RdxApiCmd.new(cmd_prefix=['settings', LS_COMMAND]))
        translate_settings_to_hash(cli_hash=cli_hash)
    end

    def translate_settings_to_hash(cli_hash)
        new_hash = {}
        cli_hash.each do |key, value|
            next if key == 'directories' || key == 'email_recipient_list'
            new_hash[key] = {}
            value.each do |inter_hash|
                if inter_hash.include?'Name'
                    new_hash[key][inter_hash['Name']] = inter_hash['value']
                else
                    new_hash[key][inter_hash['name']] = inter_hash['value']
                end
            end
        end
        new_hash
    end

end
