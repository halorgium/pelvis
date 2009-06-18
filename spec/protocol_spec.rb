require File.dirname(__FILE__) + '/spec_helper'
require 'examples/actors/herault'

class DummyActor < Pelvis::Actor; end

describe "A protocol" do
  include Pelvis::Helpers

  describe "#subscribe_presence" do
    it "should call the block when the specified identity advertises" do
      block = Proc.new { |id, status|
        id.should == identity_for(:foo)
        status.should == :available
        EM.stop
      }

      @agents = [[:herault]]
      start_agents { |agent|
        agent.protocol.subscribe_presence(identity_for(:foo), &block)
        connect(:foo) {
          EM.add_timer(1) { raise "Didn't get subscription advertisement" }
        }
      }
    end

    if ENV['PROTOCOL'] = 'xmpp'
      it "should call the block when the specified identity leaves" do
        block = Proc.new { |id, status|
          if status != :available
            id.should == identity_for(:foo)
            status.should == :unavailable
            EM.stop
          end
        }

        @agents = [[:herault]]
        start_agents { |agent|
          agent.protocol.subscribe_presence(identity_for(:foo), &block)
          connect(:foo) { |foo_agent|
            EM.add_timer(10) { raise "Didn't get subscription advertisement" }
            foo_agent.protocol.stream.instance_eval { stop }
          }
        }
      end
    end
  end
end
