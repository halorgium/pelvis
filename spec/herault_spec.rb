require File.dirname(__FILE__) + '/spec_helper'
require 'examples/actors/herault'

describe "Herault" do
  include Pelvis::Helpers

  it "should subscribe to the presence messages of agents that advertise to it and remove advertisements on unavailable" do
    @agents = [[:herault]]
    start_agents do |herault|
      herault.add_actor Herault
      connect(:foo) do |foo|
        foo.add_actor Simple
        foo.on_advertised {
          herault.protocol.presence_handlers.keys.should include(identity_for(:foo))
          Herault.operation_map['/echo'].keys.should == [ identity_for(:foo) ]

          herault.protocol.subscribe_presence(identity_for(:foo)) do |i, s|
            if s == :unavailable
              Herault.operation_map['/echo'].should == {}
              EM.stop
            end
          end
          foo.protocol.stop
        }
      end
    end
  end
end
