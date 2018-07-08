require 'base_test'
require 'methadone'
require 'methadone/test/integration_test_assertions'
require 'fileutils'
require 'tmpdir'

class TestIntegrationTestAssertions < BaseTest
  include Methadone::IntegrationTestAssertions
  include FileUtils

  def setup
    @pwd = pwd
    @tmpdir = Dir.mktmpdir
    chdir @tmpdir
  end

  def teardown
    chdir @pwd
    rm_rf @tmpdir
  end

  test_that "assert_file works with one regexp" do
    Given { some_file }
    When {
      @code = ->() { assert_file("some_file.txt", contains: /foo/) }
    }
    Then { refute_raises(&@code) }
  end

  test_that "assert_file works with many regexps" do
    Given { some_file }
    When {
      @code = ->() { assert_file("some_file.txt", contains: [ /foo/, /bar/ ]) }
    }
    Then { refute_raises(&@code) }
  end

  test_that "assert_file fails if any regexp fails to match" do
    Given { some_file }
    When {
      @code = ->() { assert_file("some_file.txt", contains: [ /foo/, /baz/ ]) }
    }
    Then { assert_raises(&@code) }
  end

  test_that "assert_banner without takes_options passes for a banner with the bin name and no '[options]'" do
    Given {
      @bin_name = "foobar"
      @stdout = "Usage: foobar"
    }
    When {
      @code = ->() { assert_banner(@stdout,@bin_name,takes_options: false) }
    }
    Then { refute_raises(&@code) }
  end

  test_that "assert_banner without takes_options fails for a banner with the bin name and '[options]'" do
    Given {
      @bin_name = "foobar"
      @stdout = "Usage: foobar [options]"
    }
    When {
      @code = ->() { assert_banner(@stdout,@bin_name,takes_options: false) }
    }
    Then { assert_raises(&@code) }
  end

  test_that "assert_banner with takes_options passes for a banner with the bin name and '[options]'" do
    Given {
      @bin_name = "foobar"
      @stdout = "Usage: foobar [options]\nOptions\n  --help"
    }
    When {
      @code = ->() { assert_banner(@stdout,@bin_name,takes_options: true) }
    }
    Then { refute_raises(&@code) }
  end

  test_that "assert_banner with takes_options fails for a banner with the bin name but no '[options]'" do
    Given {
      @bin_name = "foobar"
      @stdout = "Usage: foobar\nOptions\n  --help"
    }
    When {
      @code = ->() { assert_banner(@stdout,@bin_name,takes_options: true) }
    }
    Then { assert_raises(&@code) }
  end

  test_that "assert_banner with takes_options and takes_arguments passes for a banner with the bin name, '[options]' and the arg list" do
    Given {
      @bin_name = "foobar"
      @stdout = "Usage: foobar [options] some_arg [some_other_arg]\nOptions\n  --help"
    }
    When {
      @code = ->() {
        assert_banner(@stdout,
                      @bin_name,
                      takes_options: true,
                      takes_arguments: { some_arg: :required, some_other_arg: :optional }
                     )
      }
    }
    Then { refute_raises(&@code) }
  end

  test_that "assert_banner with takes_options and takes_arguments failes for a banner with the bin name, '[options]' and no arg list" do
    Given {
      @bin_name = "foobar"
      @stdout = "Usage: foobar [options]\nOptions\n  --help"
    }
    When {
      @code = ->() {
        assert_banner(@stdout,
                      @bin_name,
                      takes_options: true,
                      takes_arguments: { some_arg: :required, some_other_arg: :optional }
                     )
      }
    }
    Then { assert_raises(&@code) }
  end

  test_that "assert_options with one option passes when stdout contains that option" do
    Given { @stdout = some_options }
    When { @code = ->() { assert_option(@stdout,"--help") } }
    Then { refute_raises(&@code) }
  end

  test_that "assert_options with many option passes when stdout contains that option" do
    Given { @stdout = some_options }
    When { @code = ->() { assert_option(@stdout,"-h", "--help") } }
    Then { refute_raises(&@code) }
  end

  test_that "assert_options fails when stdout does not the option" do
    Given { @stdout = some_options }
    When { @code = ->() { assert_option(@stdout,"--bleorg") } }
    Then { assert_raises(&@code) }
  end

  test_that "assert_oneline_summary passes when the stdout has at least three lines, the second of which is blank and the third of which has some words in it" do
    Given {
      @stdout = [
        "Usage: foobar",
        "",
        "The awesome app of awesome",
      ].join("\n")
    }
    When { @code = ->() { assert_oneline_summary(@stdout) } }
    Then { refute_raises(&@code) }
  end

  test_that "assert_oneline_summary fails when the stdout has at least three lines, the second of which is blank and the third of which has only one word in it" do
    Given {
      @stdout = [
        "Usage: foobar",
        "",
        "awesome",
      ].join("\n")
    }
    When { @code = ->() { assert_oneline_summary(@stdout) } }
    Then { assert_raises(&@code) }
  end

  test_that "assert_oneline_summary fails when the stdout has at least three lines, the second of which is not blank and the third of which has words in it" do
    Given {
      @stdout = [
        "Usage: foobar",
        "foo",
        "awesome app of awesome",
      ].join("\n")
    }
    When { @code = ->() { assert_oneline_summary(@stdout) } }
    Then { assert_raises(&@code) }
  end

  test_that "assert_oneline_summary fails when the stdout has less than three lines" do
    Given {
      @stdout = [
        "Usage: foobar",
        "awesome app of awesome",
      ].join("\n")
    }
    When { @code = ->() { assert_oneline_summary(@stdout) } }
    Then { assert_raises(&@code) }
  end

private

  def some_options
    [
      "-h, --help     Get Help",
      "--version      Show the version",
      "--[no-]output  Print output",
    ].join("\n")
  end

  def refute_raises(&block)
    block.()
  rescue Exception => ex
    assert false, "Expected block NOT to raise, but got a #{ex.class}/#{ex.message}"
  end

  def some_file
    File.open("some_file.txt","w") do |file|
      file.puts "foo"
      file.puts "bar"
    end
  end
end
