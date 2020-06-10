#!/usr/bin/env ruby

require "pathname"
require "fileutils"


ARGV.each do |filename|
  filename = Pathname(filename)

  contents = File.read(filename).split(/\n/)
  File.open(filename,"w") do |file|
    contents.each do |line|
      file.puts line.gsub(/methadone/,"optparse_plus").gsub(/Methadone/,"OptparsePlus")
    end
  end

  if filename.split.any? { |_| _ == "methadone" }
    new_filename = filename.split.map { |_|
      if _ == "methadone"
        "optparse_plus"
      else
        _
      end
    }.join
    FileUtils.mkdir_p new_filename.dirname
    FileUtils.mv filename new_filename
  end

end
