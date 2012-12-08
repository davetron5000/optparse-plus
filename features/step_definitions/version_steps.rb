When /^I successfully run `([^`]*)` with "([^"]*)" in the library path$/ do |command,dir|
  ENV["RUBYOPT"] = (ENV["RUBYOPT"] || '') + " -I" + File.join(Dir.pwd,ARUBA_DIR,'tmp',@app_name,dir)
  step %(I successfully run `#{command}`)
end
