reduxio_volume { 'nitro':
  ensure          => 'present',
  description     => 'Volume creation with puppet',
  size            => 101,
  history_policy  => 'Critical-Apps',
  blocksize       => 512,
  url             => 'ssh://rdxadmin:admin@nitro-mgmt'
}

reduxio_volume { 'orion':
  ensure          => 'present',
  description     => 'Volume creation with puppet',
  size            => 101,
  history_policy  => 'Critical-Apps',
  blocksize       => 512,
  url             => 'ssh://rdxadmin:admin@orion-mgmt'
}

reduxio_host { 'nitro_host':
  ensure          => 'present',
  url             => 'ssh://rdxadmin:admin@nitro-mgmt'
}

reduxio_host { 'orion_host':
  ensure          => 'present',
  url             => 'ssh://rdxadmin:admin@orion-mgmt'
}


reduxio_volume_to_host_assignmnet {'nitro/nitro_host':
  ensure          => 'present',
  url             => 'ssh://rdxadmin:admin@nitro-mgmt'
}

reduxio_volume_to_host_assignmnet {'orion/orion_host':
  ensure          => 'present',
  url             => 'ssh://rdxadmin:admin@orion-mgmt'
}



Reduxio_volume <| |> -> Reduxio_host <| |> -> Reduxio_volume_to_host_assignmnet <| |>
