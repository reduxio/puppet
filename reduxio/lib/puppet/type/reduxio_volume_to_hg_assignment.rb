Puppet::Type.newtype(:reduxio_volume_to_hg_assignment) do
    @doc = 'Manage volume assignments to hostgroup on Reduxio storage'

    apply_to_all
    ensurable

    def self.title_patterns
        [
            [
                /^(.*)\/(.*)$/,
                [
                    [:volume, lambda{|x| x} ],
                    [:hg,   lambda{|x| x} ]
                ]
            ],
            [
                /^(.*)$/,
                [
                    [:volume, lambda{|x| x}]
                ]
            ]
        ]
    end

    def name
        "#{self[:volume]}/#{self[:hg]}"
    end


    newparam(:volume, :namevar => true) do
        desc 'The volume name to assign the hostgroup to'
    end

    newparam(:hg, :namevar => true) do
      desc 'The hostgroup name to assign the volume to'
    end
    
    newparam(:lun) do
        desc 'Explicitly determine the assignment LUN. Leave empty to have automatically assigned LUN'
    end

    newparam(:url) do
        desc 'Use this optional property to explicitly determine the Reduxio system connection URL to configure the entity on. Useful in local manifest execution. When this field is not provided, the machine will be derived from the network device'
    end

end
