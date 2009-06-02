desc "Release the version"
task :release do
  puts "Releasing #{@spec.version}"

  `git show-ref tags/v#{@spec.version}`
  unless $?.success?
    abort "There is no tag for v#{@spec.version}"
  end

  base_dir = File.expand_path(File.dirname(__FILE__) + '/..')
  release_directory = "#{base_dir}/.releasing"

  if File.exists?(release_directory)
    abort "Removing the #{release_directory} directory, we need it!"
  end

  Dir.mkdir(release_directory)

  puts "Extracting the tag's contents to #{release_directory}"
  system("git archive --format tar tags/v#{@spec.version} | tar -C #{release_directory} -xpf -")
  unless $?.success?
    abort "There was a problem extracting"
  end

  puts "Creating a gem inside #{release_directory}"
  system("cd #{release_directory} && rake gem")
  unless $?.success?
    abort "There was a problem creating the gem"
  end

  puts "Uploading gem to internal gem server"
  ENV.delete("GEM_PATH")
  system("samurai", "gem_upload", "#{release_directory}/pkg/#{@spec.name}-#{@spec.version}.gem") || abort("Could not upload gem")

  puts "Removing #{release_directory}"
  FileUtils.rm_rf(release_directory)

  ints = @spec.version.ints + [0]
  next_version = Gem::Version.new(ints.join(".")).bump

  puts "Changing the version to #{next_version}."

  version_file = "#{base_dir}/lib/#{@spec.name}/version.rb"
  File.open(version_file, "w") do |f|
    f.puts <<-EOT
module #{@lib_module}
  VERSION = "#{next_version}"
end
    EOT
  end

  puts "Committing the version change"
  system("git", "commit", version_file, "-m", "Next version: #{next_version}")

  puts "Pushing tag and commits up in..."
  5.times do |i|
    print "#{5 - i}.. "
    $stdout.flush
  end
  puts

  system("git", "push")
  system("git", "push", "--tags")

  puts "Finished"
end
