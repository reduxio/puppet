Puppet::Type.newtype(:reduxio_host) do
  @doc = 'Manage hosts on Reduxio Storage'

  apply_to_all
  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the host (1-31 characters)'
    validate do |value|
      fail("Name too long #{value}") unless value.length.between?(1, 31)
    end
  end

  newproperty(:description) do
    desc 'Description of the host'
  end

  newparam(:iscsi_name) do
    desc 'iSCSI name of the host. Leave empty to use the iSCSI name of the system which is executing the manifest (must have iscsi tools installed). This field, once the entity has been created created, is not updatable and will be ignored'
  end

  newparam(:url) do
    desc 'Use this optional property to explicitly determine the Reduxio system connection URL to configure the entity on. Useful in local manifest execution. When this field is not provided, the machine will be derived from the network device'
  end

end