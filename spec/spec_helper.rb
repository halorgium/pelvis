require 'rubygems'

require File.dirname(__FILE__) + '/../lib/pelvis'
require 'pelvis/protocols/xmpp'

class TestDelegate
  include Pelvis::Delegate

  def initialize
    @data = []
  end
  attr_reader :data

  def completed?
    @completed
  end

  def errored?
    @errored
  end

  def receive(data)
    @data << data
  end

  def complete(event)
    @completed = event
    EM.stop
  end

  def error(event)
    @errored = error
    EM.stop
  end
end

class Simple < Pelvis::Actor
  operation "/number" do
    invocation.receive("number" => 1)
    invocation.complete("awesome")
  end
end

require File.dirname(__FILE__) + '/helpers'

Pelvis.logger.level = Logger::WARN
