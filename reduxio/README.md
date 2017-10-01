# Reduxio StorKit for Puppet module

Reduxio Puppet module for managing Reduxio HX Series, using a network device or locally. 
The module enables the user to create, modify and update volumes, hosts and assignment. 

Note: This module does not automate the configuration of the iSCSI initiator. This
includes the configuration of iSCSI sessions, but also the Reduxio iSCSI best practices
documented in the [Reduxio Support Portal](https://support.reduxio.com "Reduxio Support Portal").
These should be configured manually or using another Puppet module.

## Requirements

1. Reduxio HX Series system running Reduxio TimeOS v2.7 or higher.
2. ['net-ssh' Ruby Gem](https://github.com/net-ssh/net-ssh "'net-ssh' Ruby Gem").
3. Puppet v3.6 or higher.

## Installation
    shell> puppet module install rdxdev-reduxio 
    
**Note:** It is recommended to restart puppet and puppetmaster services after module installation. 

## Usage
Reduxio Puppet module can be used either as a network device or locally.

### Example Manifest
```
# The volume title is also the name of the volume that will be created on the Reduxio system.
reduxio_volume { 'vol1':
  ensure          => 'present',
  description     => 'Volumes creation with puppet',
  size            => 11,
  history_policy  => 'Critical-Apps',
  blocksize       => 512
}

reduxio_volume { 'vol2':
  ensure          => 'present',
  description     => 'Volume creation with puppet',
  size            => 101,
  history_policy  => 'Critical-Apps',
  blocksize       => 512
}

reduxio_volume { 'vol3':
  ensure          => 'present',
  description     => 'Volume creation with puppet',
  size            => 100,
  history_policy  => 'Critical-Apps',
  blocksize       => 512
}

reduxio_host { 'host':
  ensure          => 'present',
  # Omitting 'iscsi_name' field will create a host with iscsi_name as the agent that is executing the manifest.
  # Using this feature relies on the /etc/iscsi/initiatorname.iscsi file.
  iscsi_name      => 'iqn.2010-10.example'
}

# The most recommended way to define an assignment is in the entity title: <vol_name>/<host_name>.
reduxio_volume_to_host_assignmnet {'vol1/host':
  ensure          => 'present'
}

# Alternative way to define an assignment. The title in this case will not have any functional affect on the 
# Reduxio assignmnet. 
reduxio_volume_to_host_assignmnet {'second_assignment':
  ensure          => 'present',
  volume          => 'vol2',
  host            => 'host'
}

# The way to define volume to hostgroup (hg) assignment is in the entity title
reduxio_volume_to_host_assignmnet {'vol1/hg1':
  ensure          => 'present'
}

# Recommended entities execution order
Reduxio_history_policy <| |> -> Reduxio_volume <| |> -> Reduxio_hg <| |> -> Reduxio_host <| |> -> Reduxio_volume_to_host_assignmnet <| |> -> Reduxio_volume_to_hg_assignmnet <| |>

```

### Updating objects
Updating objects' attributes is supported, however as names are the unique identifiers of objects, changing objects names is not possible. 

### Network Device
The Reduxio Puppet module can act as a network device. Example `device.conf` file, which should reside in a node which shall
be the proxy to the Reduxio system (aka proxy node):
 
 ```
 [devicename]
 type reduxio
 url ssh://login_username:login_password@reduxio_system_address
```

The device name (or cert name) is unrelated to the agent node host name. Furthermore, it is recommended **not** to name
the devices as the proxy node host name, to avoid conflict in cases where the proxy node should act both as agent 
and as a Reduxio network device(s) proxy. The device name is the certificate name that the puppet master (server) will 
be authenticated with. If working with the same Reduxio system from multiple proxy nodes, make sure to name the devices
in each node differently, if wishing to execute different manifests from the the proxy nodes on the same Reduxio system.

Once defining a device.conf file on the proxy node, you should also define the relative manifest to the network device
on the puppet master node (usually in `site.pp` file):

```
    node 'devicename' {
        reduxio_volume { 'vol1':
          ensure          => 'present',
          description     => 'Volumes creation with puppet',
          size            => 11,
          history_policy  => 'Critical-Apps',
          blocksize       => 512
        }
    }
```

To disptach the network device configuration, run the following on the proxy node:

`shell> puppet device`

Note: If the network device hasn't been authenticated with the puppet master, you should specify `--waitforcert` 
parameter and sign the request on the puppet master while the proxy node is waiting for authentication. 
After signing, you should run again the `puppet device` command again. 

If using a non-default `device.cong` file, you can specify an alternative conf file:

` shell> puppet device --deviceconfig /path/to/alternative/conf/file`

### Locally

Using the Reduxio Puppet module locally can be achieved by explicitly defining a 'url' attribute per entity, allowing
the management of multiple Reduxio machines in a single manifest file. For example:

```
reduxio_volume { 'vol1':
  ensure          => 'present',
  description     => 'Volumes creation with puppet',
  size            => 11,
  history_policy  => 'Critical-Apps',
  blocksize       => 512,
  url             => 'ssh://login_username:login_password@reduxio1'
}

reduxio_volume { 'vol2':
  ensure          => 'present',
  description     => 'Volume creation with puppet',
  size            => 101,
  history_policy  => 'Critical-Apps',
  blocksize       => 512,
  url             => 'ssh://login_username:login_password@reduxio2'
}
```

This will create two volumes: `vol1` on `reduxio1` machine, and `vol2` on `reduxio2` machine. When working with multiple
machines, a title is unique per entitiy type, so one needs to explicitly define the `name` property when multiple entities
with the same name should be created accross multiple Reduxio systems. 

This approach can also be combined with the network device approach: Specifying the `url` attribute will override the 
`device.conf` settings.