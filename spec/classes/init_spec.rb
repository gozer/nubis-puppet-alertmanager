require 'spec_helper'
describe 'nubis_alertmanager' do
  context 'with default values for all parameters' do
    it { should contain_class('nubis_alertmanager') }
  end
end
