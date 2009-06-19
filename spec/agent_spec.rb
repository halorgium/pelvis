require File.dirname(__FILE__) + '/spec_helper'
require 'examples/actors/herault'

class Herault
  def self.reset
    @operation_map = nil
  end
end

describe "An Agent" do
  include Pelvis::Helpers
  Pelvis::Agent.readvertise_wait_interval = 0

  # FIXME: this is awful complex but it works
  it "should readvertise it's resources when herault returns from an absence" do
    @agents = [[:herault]]
    start_agents do |herault|
      herault.add_actor Herault
      connect(:foo) do |foo|
        simple = foo.add_actor Simple
        foo.on_advertised do
          foo.protocol.subscribe_presence(identity_for(:herault)) do |i, s|
            if s == :available
              simple.on_readvertising do |ad|
                ad.on_succeeded do
                  Herault.operation_map['/echo'].keys.should == [ identity_for(:foo) ]
                  EM.stop
                end
              end
            else
              Herault.reset
              connect(:herault) { |h| h.add_actor Herault }
            end
          end
          herault.protocol.stop
        end
      end
    end
  end
end
