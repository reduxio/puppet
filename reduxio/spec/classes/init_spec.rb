require 'spec_helper'
describe 'reduxio' do
  context 'with default values for all parameters' do
    it { should contain_class('reduxio') }
  end
end
