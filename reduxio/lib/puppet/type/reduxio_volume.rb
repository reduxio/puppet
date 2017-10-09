Puppet::Type.newtype(:reduxio_volume) do
  @doc = 'Manage Volumes on Reduxio Storage'

  apply_to_all
  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the volume'
  end

  newproperty(:size) do
    desc 'The volume size (in GB)'
    newvalues(/^\d+$/)
  end

  newproperty(:description) do
    desc 'Description of the volume'
  end

  newproperty(:history_policy) do
    desc 'History policy of the volume'
  end

  newproperty(:blocksize) do
    desc 'Block size (sector size) of the volume (512 or 4096 bytes)'
    newvalues(/^\d+$/)
  end

  newparam(:url) do
    desc 'Use this optional property to explicitly determine the Reduxio system connection URL to configure the entity on. Useful in local manifest execution. When this field is not provided, the machine will be derived from the network device'
  end

end