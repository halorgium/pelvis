def console(obj)
  ARGV.clear # Avoid passing args to IRB

  require "irb"
  IRB.setup(nil)
  irb = IRB::Irb.new(IRB::WorkSpace.new(obj.send(:binding)))
  IRB.conf[:MAIN_CONTEXT] = irb.context

  old = trap(:INT) { irb.signal_handle }
  Thread.start do
    catch(:IRB_EXIT) { irb.eval_input }
    trap(:INT, old)
    puts
    puts "Ready to stop"
    EM.stop
  end
end
