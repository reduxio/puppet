# The volume title is also the name of the volume that will be created on the Reduxio system
reduxio_volume { 'vol1':
  ensure          => 'present',
  description     => 'Volume created by Reduxio puppet module',
  size            => 11,
  history_policy  => 'Critical-Apps',
  blocksize       => 512
}

reduxio_volume { 'vol2':
  ensure          => 'present',
  description     => 'Volume created by Reduxio puppet module',
  size            => 101,
  history_policy  => 'Critical-Apps',
  blocksize       => 512
}

reduxio_volume { 'vol3':
  ensure          => 'present',
  description     => 'Volume created by Reduxio puppet module',
  size            => 100,
  history_policy  => 'Critical-Apps',
  blocksize       => 512
}

reduxio_host { 'host':
  ensure          => 'present',
  # Omitting 'iscsi_name' field will create a host with iscsi_name as the agent that is executing the manifest.
  # Using this feature relies on /etc/iscsi/initiatorname.iscsi file.
  iscsi_name      => 'iqn.2010-10.example'
}

# The most recommended way to define an assignment in the entity title: <vol_name>/<host_name>
reduxio_volume_to_host_assignmnet {'vol1/host':
  ensure          => 'present'
}

# Alternative way to define an assignmnet
reduxio_volume_to_host_assignmnet {'second_assignment':
  ensure          => 'present',
  volume          => 'vol2',
  host            => 'host'
}

# Recommended entities execution order
Reduxio_volume <| |> -> Reduxio_host <| |> -> Reduxio_volume_to_host_assignmnet <| |>
