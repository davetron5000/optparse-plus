module Fullstop
  class Repo

    include Methadone::CLILogging
    include Methadone::SH
    include Methadone::ExitNow

    def self.clone_from(repo_url,force=false)
      repo_dir = repo_url.split(/\//)[-1].gsub(/\.git$/,'')
      if force && Dir.exists?(repo_dir)
        warn "deleting #{repo_dir} before cloning"
        FileUtils.rm_rf repo_dir
      end
      unless sh("git clone #{repo_url}") == 0
        exit_now!(1,"checkout dir already exists, use --force to overwrite")
      end
      Repo.new(repo_dir)
    end

    attr_reader :repo_dir
    def initialize(repo_dir)
      @repo_dir = repo_dir
    end

    def files
      Dir.entries(@repo_dir).each do |file|
        next if file == '.' || file == '..' || file == '.git'
        yield file
      end
    end
  end
end
