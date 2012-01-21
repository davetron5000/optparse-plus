#!/usr/bin/env ruby

STDOUT.puts "standard output"
STDERR.puts "standard error" if ARGV.length > 0
exit ARGV.length
