Puppet::Type.newtype(:reduxio_hg) do
  @doc = 'Manage host groups on Reduxio Storage'

  apply_to_all
  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the host group (1-31 characters)'
    validate do |value|
      fail("Name too long #{value}") unless value.length.between?(1, 31)
    end
  end

  newproperty(:description) do
    desc 'Description of the host'
  end

  newparam(:url) do
    desc 'Use this optional property to explicitly determine the Reduxio system connection URL to configure the entity on. Useful in local manifest execution. When this field is not provided, the machine will be derived from the network device'
  end

end