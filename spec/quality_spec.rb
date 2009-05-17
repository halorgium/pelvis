require File.dirname(__FILE__) + '/spec_helper'

describe "The library itself" do
  Spec::Matchers.create :have_no_tab_characters do
    match do |filename|
      @failing_lines = []
      File.readlines(filename).each_with_index do |line,number|
        @failing_lines << number + 1 if line =~ /\t/
      end
      @failing_lines.empty?
    end

    failure_message_for_should do |filename|
      "The file #{filename} has tab characters on lines #{@failing_lines.join(', ')}"
    end
  end

  Spec::Matchers.create :have_no_extraneous_spaces do
    match do |filename|
      @failing_lines = []
      File.readlines(filename).each_with_index do |line,number|
        next if line =~ /^\s+#.*\s+\n$/
        @failing_lines << number + 1 if line =~ /\s+\n$/
      end
      @failing_lines.empty?
    end

    failure_message_for_should do |filename|
      "The file #{filename} has spaces on the EOL on lines #{@failing_lines.join(', ')}"
    end
  end

  it "has no malformed lines of code" do
    Dir.chdir(File.dirname(__FILE__) + '/..') do
      Dir.glob("**/*.rb").each do |filename|
        filename.should have_no_tab_characters
        filename.should have_no_extraneous_spaces
      end
    end
  end
end
