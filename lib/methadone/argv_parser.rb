module Methadone #:nodoc:
  # Assists with parsing strings in the same way that ARGV might.
  # This is *not* used to parse the command-line, but used to 
  # parse config files/environment variables so they can be placed into ARGV and properly interpretted by 
  # OptionParser
  module ARGVParser #:nodoc:

  private

    # Parses +string+, returning an array that can be placed into ARGV or given to OptionParser
    def parse_string_for_argv(string) #:nodoc:
      return [] if string.nil?

      args = []               # return value we are building up
      current = 0             # pointer to where we are in +string+
      next_arg = ''           # the next arg we are building up to ultimatley put into args
      inside_quote = nil      # quote character we are "inside" of
      last_char = nil         # the last character we saw

      while current < string.length
        char = string[current]
        case char
        when /["']/
          if inside_quote.nil?         # eat the quote, but remember we are now "inside" one
            inside_quote = char
          elsif inside_quote == char   # we closed the quote we were "inside"
            inside_quote = nil
          else                         # we got a different quote, so it goes in literally
            next_arg << char
          end
        when /\s/
          if last_char == "\\"         # we have an escaped space, replace the escape char
            next_arg[-1] = char
          elsif inside_quote           # we are inside a quote so keep the space
            next_arg << char
          else                         # new argument
            args << next_arg
            next_arg = ''
          end
        else
          next_arg << char
        end
        current += 1
        last_char = char
      end
      args << next_arg unless next_arg == ''
      args
    end
  end
end
