require 'rubygems'
require 'spec/rake/spectask'
require 'rake/gempackagetask'

require File.dirname(__FILE__) + '/lib/pelvis/version'

@lib_module = Pelvis
@spec = Gem::Specification.new do |s|
  s.name      = 'pelvis'
  s.version   = Pelvis::VERSION
  s.platform  = Gem::Platform::RUBY
  s.has_rdoc  = false
  s.author    = 'Engine Yard'
  s.email     = 'tech@engineyard.com'
  s.homepage  = 'http://github.com/halorgium/pelvis'
  s.summary   = 'A vertebra-like framework'
  s.description = s.summary

  s.require_path = 'lib'
  s.files = %w(Rakefile) + Dir.glob("{lib,spec}/**/*")
  
  s.add_dependency 'rake'
  s.add_dependency 'extlib'
  s.add_dependency 'eventmachine', '>= 0.12.7'
  s.add_dependency 'blather', '>= 0.3.4'
  
  # this is because rubygems is lame
  s.add_dependency('mime-types', '>= 1.16')
  s.add_dependency('echoe', '>= 3.1.1')
  s.add_dependency('highline')
end

Rake::GemPackageTask.new(@spec) do |pkg|
  pkg.gem_spec = @spec
end

load 'tasks/release.rake'

desc 'Default: run spec examples'
task :default => 'spec'

desc "Run unit specifications"
Spec::Rake::SpecTask.new(:spec) do |t|
  t.spec_opts << %w(-fs --color)
  t.spec_opts << '--loadby' << 'random'
  t.spec_files = Dir["spec/**/*_spec.rb"]

  t.rcov_opts << '--exclude' << 'spec'
  t.rcov = ENV.has_key?('NO_RCOV') ? ENV['NO_RCOV'] != 'true' : true
  t.rcov_opts << '--text-summary'
  t.rcov_opts << '--sort' << 'coverage' << '--sort-reverse'
end
