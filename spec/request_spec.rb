require File.dirname(__FILE__) + '/spec_helper'
require 'examples/actors/herault'

describe "A request on pelvis" do
  include Pelvis::Helpers

  before(:each) do
    @agents = [
      [:foo, [Simple]],
      [:bar],
    ]
  end

  it "works when the identity is specified" do
    @disable_advertise = true
    results = TestDelegate.new
    start_agents do |agent|
      agent.request(:direct, "/number", {:number => 1, :hash => { :one => 2 }}, :identities => [identity_for(:foo)], :delegate => results)
    end
    should_be_good(results)
  end

  it "discovers through herault when identities are not specified" do
    @agents.unshift([:herault, [Herault]])
    results = TestDelegate.new
    start_agents do |agent|
      agent.request(:all, "/number", {:number => 1, :hash => { :one => 2 }}, :delegate => results)
    end
    should_be_good(results)
  end

  def should_be_good(results)
    results.should be_completed
    results.should_not be_failed

    results.data.size.should == 1
    res = results.data.first
    res.should == { 'number' => 1, 'hash' => { 'one' => 2 } }
  end
end
