require 'erb'

module Methadone
  # <b>Methadone Internal - treat as private</b>
  #
  # Stuff to implement methadone's CLI app.  These
  # stuff isn't generally for your use and it's not
  # included when you require 'methadone'
  module CLI

    # Checks that the basedir can be used, either by
    # not existing, or by existing and force is true.
    # In that case, we clean it out entirely
    #
    # +basedir+:: base directory where the user wants to create a new project
    # +force+:: if true, and +basedir+ exists, delete it before proceeding
    #
    # This will exit the app if the dir exists and force is false
    def check_and_prepare_basedir!(basedir,force)
      if File.exists? basedir
        if force
          rm_rf basedir, :verbose => true, :secure => true
        else
          exit_now! 1,"error: #{basedir} exists, use --force to override"
        end
      end
      mkdir_p basedir
    end

    # Add content to a file
    #
    # +file+:: path to the file
    # +lines+:: Array of String representing the lines to add
    # +options+:: Hash of options:
    #             <tt>:before</tt>:: A regexp that will appear right after the new content. i.e.
    #                                this is where to insert said content.
    def add_to_file(file,lines,options = {})
      new_lines = []
      found_line = false
      File.open(file).readlines.each do |line|
        line.chomp!
        if options[:before] && options[:before] === line
          found_line = true
          new_lines += lines
        end
        new_lines << line
      end

      raise "No line matched #{options[:before]}" if options[:before] && !found_line

      new_lines += lines unless options[:before]
      File.open(file,'w') do |fp|
        new_lines.each { |line| fp.puts line }
      end
    end

    # Copies a file, running it through ERB
    #
    # +relative_path+:: path to the file, relative to the project root, minus the .erb extension
    #                   You should use forward slashes to separate paths; this method
    #                   will handle making the ultimate path OS independent.
    # +options+:: Options to affect how the copy is done:
    #             <tt>:from</tt>:: The name of the profile from which to find the file, "full" by default
    #             <tt>:as</tt>:: The name the file should get if not the one in relative_path
    #             <tt>:executable</tt>:: true if this file should be set executable
    #             <tt>:binding</tt>:: the binding to use for the template
    def copy_file(relative_path,options = {})

      relative_path = File.join(relative_path.split(/\//))

      template_path = File.join(template_dir(options[:from] || :full),relative_path + ".erb")
      template = ERB.new(File.open(template_path).readlines.join(''), nil ,'-')

      relative_path_parts = File.split(relative_path)
      relative_path_parts[-1] = options[:as] if options[:as]

      File.open(File.join(relative_path_parts),'w') do |file|
        file.puts template.result(options[:binding] || binding)
        file.chmod(0755) if options[:executable]
      end
    end

    # Get the location of the templates for profile "from"
    def template_dir(from)
      File.join(File.dirname(__FILE__),'..','..','templates',from.to_s)
    end

    def template_dirs_in(profile)
      template_dir = template_dir(profile)

      Dir["#{template_dir}/**/*"].select { |x|
        File.directory? x
      }.map { |dir|
        dir.gsub(/^#{template_dir}\//,'')
      }
    end

    def render_license_partial(partial)
      ERB.new(File.read(template_dir('full/'+partial))).result(binding).strip
    end

    # converts string to constant form:
    #   methadone-module_name-class_name => Methadone::ModuleName::ClassName
    def titlify(name)
      name.gsub(/(^|-|_)(.)/) {"#{'::' if $1 == '-'}#{$2.upcase}"}
    end

    def gemspec
      @gemspec || @gemspec=_get_gemspec
    end
    private
    def _get_gemspec
      files=Dir.glob("*.gemspec")
      raise "Multiple gemspec files" if files.size>1
      raise "No gemspec file" if files.size < 1
      Gem::Specification::load(files.first)
    end

    def normalize_command(cmd)
      #Note: not i18n-safe
      cmd.tr('A-Z','a-z').gsub(/[^a-z0-9_]/,'_').sub(/^_*/,'')
    end
  end
end
