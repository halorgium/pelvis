require File.dirname(__FILE__) + '/spec_helper'
require 'examples/actors/herault'

class DummyActor < Pelvis::Actor; end

describe "A protocol" do
  include Pelvis::Helpers

  describe "#subscribe_presence" do
    it "should call the block when the specified identity advertises" do
      block = Proc.new { @called_me = true }

      @agents = [[:herault, [DummyActor]], [:foo]]
      start_agents { |agent|
        agent.protocol.subscribe_presence(identity_for(:bar), &block)
        connect(:bar) {
          @called_me.should == true
          EM.stop
        }
      }
    end
  end
end
