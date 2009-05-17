require 'rubygems'

require File.dirname(__FILE__) + '/../lib/pelvis'
require 'pelvis/protocols/xmpp'

class TestDelegate
  include Pelvis::SafeDelegate

  def initialize
    @completed, @failed = false, false
    @data = []
  end
  attr_reader :data

  def completed?
    @completed
  end

  def failed?
    @failed
  end

  def received(data)
    @data << data
  end

  def completed(event)
    @completed = event
    EM.stop
  end

  def failed(error)
    @failed = error
    EM.stop
  end
end

class Resourced < Pelvis::Actor
  def self.resources
    ['/howdy']
  end

  operation "/w_resource"
  def stuff
    send_data 'message' => 'howdy'
    finish
  end
end

class Simple < Pelvis::Actor
  operation "/echo"
  def echo
    send_data params
    finish
  end
end

require File.dirname(__FILE__) + '/helpers'

if ENV["DEBUGGER"]
  Pelvis.logger.level = Logger::DEBUG
else
  Pelvis.logger.level = Logger::FATAL
end
