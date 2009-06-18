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
  end
end
