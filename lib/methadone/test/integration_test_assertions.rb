module Methadone::IntegrationTestAssertions
  # Assert that a file's contents contains one or more regexps
  #
  # filename:: The file whose contents to check
  # contains:: either a regexp or array of regexpts that the file's contents must match
  def assert_file(filename, contains:)
    contents = File.read(filename)
    Array(contains).each do |regexp|
      assert_match(regexp,contents,"Expected #{filename} to contain #{regexp}")
    end
  end

  # Assert that the stdout contains an appropriate banner for your app
  #
  # stdout:: The standard out, presumably of running `«your-app» --help`
  # bin_name:: The binary name of your app 
  # takes_options:: set this to true if your app should take options
  # takes_arguments:: set this to a hash of the arguments your app should take, with the key being the arg name and the value
  # being either `:required` or `:optional`
  def assert_banner(stdout, bin_name, takes_options: , takes_arguments: {})
    if takes_options
      assert_match(/Options/, stdout)
      if takes_arguments == false || takes_arguments.empty?
        assert_match(/Usage: #{Regexp.escape(bin_name)}.*\[options\]\s*$/,stdout)
      else
        expected_args = takes_arguments.map { |arg, required|
          if required == :required
            arg.to_s
          else
            "[#{arg}]"
          end
        }.join(" ")

        assert_match(/Usage: #{Regexp.escape(bin_name)}.*\[options\]\s*#{Regexp.escape(expected_args)}$/,stdout)
      end
    else
      assert_match(/Usage: #{Regexp.escape(bin_name)}\s*$/,stdout)
    end
  end

  # Assert that your app takes the given option(s)
  #
  # stdout:: The standard out, presumably of running `«your-app» --help`
  # options:: options your app should take.  Put the literal value in here e.g. `--foo` or `--[no-]bar`.  The array form is to
  # allow you to assert long and short options for readable tests:
  #
  #     assert_option(stdout, "--version")
  #     assert_option(stdout, "-h", "--help")
  def assert_option(stdout, *options)
    options.each do |option|
      assert_match(/#{Regexp.escape(option)}/,stdout)
    end
  end

  # Assert that your app has a one-line summary
  # stdout:: The standard out, presumably of running `«your-app» --help`
  def assert_oneline_summary(stdout)
    output = stdout.split(/\n/)
    assert output.size >= 3, "Expected 3 or more lines:\n#{stdout}"
    assert_match(/^\s*$/,output[1],"Should be a blank line after the banner")
    assert_match(/^\w+\s+\w+/,output[2],"Should be at least two words describing your app")
  end
end
