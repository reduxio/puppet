Puppet::Type.newtype(:reduxio_history_policy) do
  @doc = 'Manage history policies on Reduxio Storage'

  apply_to_all
  ensurable

  newparam(:name, :namevar => true) do
    desc 'The name of the history policy'
  end

  newproperty(:is_default) do
    desc 'Description of the host'
  end

  newproperty(:seconds) do
    desc 'history policy seconds'
  end

  newproperty(:hours) do
    desc 'history policy hours'
  end

  newproperty(:days) do
    desc 'history policy days'
  end

  newproperty(:weeks) do
    desc 'history policy weeks'
  end

  newproperty(:months) do
    desc 'history policy months'
  end

  newproperty(:retention) do
    desc 'history policy retention'
  end

  newparam(:url) do
    desc 'Use this optional property to explicitly determine the Reduxio system connection URL to configure the entity on. Useful in local manifest execution. When this field is not provided, the machine will be derived from the network device'
  end

end