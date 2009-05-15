require File.dirname(__FILE__) + '/spec_helper'
require 'examples/actors/herault'

describe "A request on pelvis" do
  include Pelvis::Helpers

  agents = [
    [:foo, [Simple]],
    [:bar],
  ]

  it "works when the identity is specified" do
    Pelvis::Agent.disable_advertisement = true
    results = TestDelegate.new
    EM.run do
      agent_start(agents) do |agent|
        agent.request(:all, "/number", {:number => 1, :hash => { :one => 2 }}, :identities => [identity_for(:foo)], :delegate => results)
      end
    end
    should_be_good(results)
  end

  it "discovers through herault when identities are not specified" do
    Pelvis::Agent.disable_advertisement = false
    agents.unshift([:herault, [Herault]])
    results = TestDelegate.new
    EM.run do
      agent_start(agents) do |agent|
        agent.request(:all, "/number", {:number => 1, :hash => { :one => 2 }}, :delegate => results)
      end
    end
    should_be_good(results)
  end
  
  def should_be_good(results)
    results.should be_completed
    results.should_not be_errored

    results.data.size.should == 1
    res = results.data.first
    res.should be_a_kind_of(Pelvis::Message)
    res.data.should == { 'number' => 1, 'hash' => { 'one' => 2 } }
  end
end
