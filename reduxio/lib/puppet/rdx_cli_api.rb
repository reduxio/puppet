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
require 'rest-client'

VOLUMES                     = 'volumes'
BOOKMARKS                   = 'bookmarks'
ASSIGNMENTS                 = 'assignments'
HISTORY_POLICIES            = 'history_policies'
HOSTS                       = 'hosts'
HOSTGROUPS                  = 'hostgroups'
HTTP_GET                    = 'get'
HTTP_POST                   = 'post'
HTTP_PUT                    = 'put'
HTTP_DELETE                 = 'delete'


class RdxCliAPI

    def initialize(rdx_host, rdx_token)
        @client      = RestClient::Resource.new(
                "https://"+rdx_host+"/api", 
                :verify_ssl => OpenSSL::SSL::VERIFY_NONE, 
                :headers    => {
                    "content-type" => "application/json",
                    "X-Auth-Token" => rdx_token,
                    "X-PRETTY-JSON" => true
            }
        )
    end

    def send_rest_cmd(cmd_args,rest_cmd_type,json=nil)
        Puppet.debug("Sending rest cmd. Path: " + cmd_args + " type: " + rest_cmd_type)
        begin
            if json != nil
                output = @client[cmd_args].send(rest_cmd_type,json)
            else
                output = @client[cmd_args].send(rest_cmd_type)
            end
        rescue RestClient::ExceptionWithResponse => e
            message = e.message
            begin
                if (!e.response.nil?)
                    message = e.response
                    message = JSON.parse(e.response)["message"]
                end
            rescue Exception => e1
                Puppet.debug("Failed parsing response, response=\n" + e.response)             
            end
            raise Puppet::Error, "Failed rest command '#{cmd_args}'. Error: #{e.class}, message: #{message}"

        end

        begin
            if output != ""
                json_output = JSON.parse(output)
            end
        rescue Exception => e
            raise Puppet::Error, "Failed parsing Reduxio REST JSON output (cmd:'#{cmd_args}'. Error: #{e.class}, message: #{e.message})"
        end
        return json_output
    end

    def construct_url(*args)
        args.join("/")
    end

    def list_volumes
        return send_rest_cmd(VOLUMES,HTTP_GET)
    end

    def find_volume_by_name(volname)
        list_volumes.each do |vol|
            return vol if vol["name"] == volname
        end
        return nil
    end

    def find_volume_by_wwid(wwid)
        list_volumes.each do |vol|
            return vol if vol["wwid"] == wwid
        end
    end
    
    def find_volume_name_by_id(volume_id, volumes) 
      volumes.each do |vol|
        return vol["name"] if vol["id"].to_s == volume_id.to_s
      end
      return nil
    end
    
    def find_host_name_by_id(host_id, hosts) 
      hosts.each do |host|
        return host["name"] if host["id"].to_s == host_id.to_s
      end
      return nil
    end
    
    def find_hg_name_by_id(hg_id, hgs)
      hgs.each do |hg|
        return hg["name"] if hg["id"].to_s == hg_id.to_s
      end
      return nil
    end
    
    def find_hp_name_by_id(hp_id, hps)
      hps.each do |hp|
        return hp["name"] if hp["id"].to_s == hp_id.to_s
      end
      return nil
    end
    
    def update_volume(name, description=nil, size=nil, history_policy=nil)
        vol = find_volume_by_name(name)
        history_policy_id = vol["history_policy_id"]
        if history_policy != nil
            history_policy_obj = find_history_policy_by_name(history_policy)
            if history_policy_obj == nil
                raise Puppet::Error, "Failed finding history policy '#{history_policy}'"
            end
            history_policy_id = history_policy_obj["id"]
        end
        send_rest_cmd(construct_url(VOLUMES,vol["id"].to_s),HTTP_PUT,{
            'name' => name,
            'size' => {
                'unit'  => 'GB',
                'value' => size
            },
            'history_policy_id' => history_policy_id,
            'description' => description
        }.to_json)
    end

    def list_history_policies
        return send_rest_cmd(HISTORY_POLICIES,HTTP_GET)
    end

    def find_history_policy_by_name(name)
        list_history_policies.each do |history_policy|
            return history_policy if history_policy["name"] == name
        end
        return nil
    end

    def create_volume(name, size=nil, description=nil, history_policy=nil, blocksize=nil)
        if history_policy != nil
            history_policy_obj = find_history_policy_by_name(history_policy)
            if history_policy_obj == nil
                raise Puppet::Error, "Failed finding history policy '#{history_policy}'"
            end
            send_rest_cmd(VOLUMES,HTTP_POST,{
                'name' => name,
                'size' => {
                    'unit'  => 'GB',
                    'value' => size
                },
                'history_policy_id' => history_policy_obj["id"],
                'block_size' => blocksize,
                'description' => description
            }.to_json)
        else
            send_rest_cmd(VOLUMES,HTTP_POST,{
                'name' => name,
                'size' => {
                    'unit'  => 'GB',
                    'value' => size
                },
                'block_size' => blocksize,
                'description' => description
            }.to_json)
        end
    end

    def delete_volume(name)
        send_rest_cmd(construct_url(VOLUMES,name),HTTP_DELETE)
    end

    def revert_volume(name, date=nil)
        send_rest_cmd(construct_url(VOLUMES,name),HTTP_PUT,{
            'revert_date' => date
        }.to_json)
    end

    def list_hosts
        return send_rest_cmd(HOSTS,HTTP_GET)
    end

    def find_host_by_name(hostname)
        list_hosts.each do |host|
            return host if host["name"] == hostname
        end
        return nil
    end

    def create_host(name, iscsi_name, hg_id=nil, user_chap=nil, password_chap=nil, description=nil)

        send_rest_cmd(HOSTS,HTTP_POST,{
            'name' => name,
            'iscsi_name' => iscsi_name,
            'description' => description,
            'user_chap' => user_chap,
            'password_chap' => password_chap,
            'description' => description
            }.to_json)

        host = find_host_by_name(name)

        if hg_id != nil
            found_hg = find_hg_by_name(hg_id)
            if found_hg != nil
                send_rest_cmd(construct_url(HOSTGROUPS,found_hg["id"].to_s,HOSTS,host["id"].to_s),HTTP_POST,{}.to_json)
            end
        end
    end

    def list_hosts_by_hg(hg_id)
        return send_rest_cmd(construct_url(HOSTGROUPS,hg_id.to_s,HOSTS),HTTP_GET)
    end

    def find_hg_by_host_name(host_name)
        list_hgs.each do |hg|
            list_hosts_by_hg(hg["id"]).each do |host|
                return hg["id"] if host["name"] == host_name
            end
        end

        return nil
    end

    def delete_hg_to_host_assignment(host_name)
        hg = find_hg_by_host_name(host_name)
        if hg != nil
            send_rest_cmd(construct_url(HOSTGROUPS,find_hg_by_host_name(host_name).to_s,HOSTS,find_host_by_name(host_name)["id"].to_s),HTTP_DELETE)
        end
    end

    def delete_host(name)
        delete_hg_to_host_assignment(name)
        send_rest_cmd(construct_url(HOSTS,name),HTTP_DELETE)
    end

    def update_host(name, hg_id=nil, user_chap=nil, password_chap=nil, description=nil)
        host = find_host_by_name(name)
        send_rest_cmd(HOSTS+"/"+host["id"].to_s,HTTP_PUT,{
            'user_chap' => user_chap,
            'password_chap' => password_chap,
            'description' => description
            }.to_json)

        hg = find_hg_by_name(hg_id)
        if hg != nil
            if host["hostgroup_id"] !=  hg["id"]
                delete_hg_to_host_assignment(name)
                send_rest_cmd(construct_url(HOSTGROUPS,hg["id"].to_s,HOSTS,host["id"].to_s),HTTP_POST,{}.to_json)
            end
        else
            delete_hg_to_host_assignment(name)
        end
    end

    def assign(vol_name, host_name=nil, hostgroup_name=nil, lun=nil)
        send_rest_cmd(ASSIGNMENTS,HTTP_POST,{
            'volume_id' => vol_name,
            'host_id' => host_name,
            'hostgroup_id' => hostgroup_name
            }.to_json)
    end

    def list_hgs
        return send_rest_cmd(HOSTGROUPS,HTTP_GET)
    end

    def find_hg_by_name(hgname)
        list_hgs.each do |hg|
            return hg if hg["name"] == hgname
        end
        return nil
    end

    def delete_hg(name)
        send_rest_cmd(construct_url(HOSTGROUPS,name),HTTP_DELETE)
    end

    def update_hg(name, description=nil)
        send_rest_cmd(construct_url(HOSTGROUPS,name),HTTP_PUT,{
            'name' => name,
            'description' => description
            }.to_json)
    end

    def create_hg(name, description=nil)
        send_rest_cmd(HOSTGROUPS,HTTP_POST,{
            'name' => name,
            'description' => description
            }.to_json)
    end

    def unassign(vol_name, host_name=nil, hostgroup_name=nil)
        if host_name.nil?
          host_url_match = "hostgroup_id=#{hostgroup_name}"
        else
          host_url_match = "host_id=#{host_name}"
        end
        send_rest_cmd(construct_url(ASSIGNMENTS,"?volume_id=#{vol_name}&#{host_url_match}"),HTTP_DELETE)
    end
    
    def find_assignment_by_host(vol_name, host_name)
        vol = find_volume_by_name(vol_name)
        host = find_host_by_name(host_name)
        return nil if (host.nil? || vol.nil?)
        list_volume_to_host_assignments.each do |assgn|
            return assgn if assgn["volume_id"] == vol["id"] && assgn["host_id"] == host["id"]
        end
        return nil
    end
    
    def find_assignment_by_hostgroup(vol_name, hostgroup_name)
        vol = find_volume_by_name(vol_name)
        hostgroup = find_hg_by_name(hostgroup_name)
        return nil if (hostgroup.nil? || vol.nil?)
        list_volume_to_hg_assignments.each do |assgn|
            return assgn if assgn["volume_id"] == vol["id"] && assgn["hostgroup_id"] == hostgroup["id"]
        end
        return nil
    end

    def list_assignments(vol=nil, host=nil, hg=nil)
        return send_rest_cmd(ASSIGNMENTS,HTTP_GET)
    end
    
    def list_volume_to_host_assignments(vol=nil, host=nil, hg=nil)
        return list_assignments.reject{ |assign| assign["host_id"] == 0 }
    end
    
    def list_volume_to_hg_assignments(vol=nil, host=nil, hg=nil) 
        return list_assignments.reject{ |assign| assign["hostgroup_id"] == 0 }
    end
    
    def list_history_policies
        return send_rest_cmd(HISTORY_POLICIES,HTTP_GET)
    end

    def find_hp_by_name(name)
        list_history_policies.each do |hp|
            return hp if hp["name"] == name
        end
        raise Puppet::Error, "History policy '#{name}' does not exist!"
    end

    def update_hp(name,is_default,seconds,hours,days,weeks,months,retention)
        hp = find_hp_by_name(name)
        send_rest_cmd(construct_url(HISTORY_POLICIES,hp["id"].to_s),HTTP_PUT,{
            'is_default' => is_default,
            'seconds'    => seconds,
            'hours'      => hours,
            'days'       => days,
            'weeks'      => weeks,
            'months'     => months,
            'retention'  => retention
            }.to_json)
    end

end
