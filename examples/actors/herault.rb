require 'set'

class Herault < Pelvis::Actor
  def self.operation_map
    @operation_map ||= {}
  end

  operation "/security/advertise" do
    unless identity = invocation.job.args[:identity]
      next invocation.error("No identity provided")
    end

    invocation.job.args[:operations].each do |operation|
      add_identity_for_operation(identity, operation)
    end
    invocation.complete("done")
  end

  operation "/security/discover" do
    identities = identities_for(invocation.job.args[:operation])
    invocation.receive(:identities => identities) if identities.any?
    invocation.complete("done")
  end

  operation "/security/authorize" do
    invocation.receive(true)
    invocation.complete("done")
  end

  def add_identity_for_operation(identity, operation)
    self.class.operation_map[operation] ||= Set.new
    self.class.operation_map[operation] << identity
  end

  def identities_for(operation)
    self.class.operation_map[operation].to_a
  end
end
