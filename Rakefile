# encoding: utf-8

require 'etc'
require 'fileutils'
require 'json'

@loom_config = nil


task :default => :list_targets

task :list_targets do |t, args|
  a = "#{File.basename(File.dirname(__FILE__))} Rakefile"
  b = "running on Ruby #{RUBY_VERSION}"
  puts "#{a} #{b}"
  system("rake -T")
  puts ''
end

desc "installs rake tasks for Loom"
task :install do |t, args|
  Dir.mkdir(installed_tasks_dir) unless Dir.exists?(installed_tasks_dir)

  cmd = "cp lib/tasks/*.rake #{installed_tasks_dir}"
  try(cmd, "failed to install tasks")

  puts "[#{t.name}] task completed, tasks installed to #{installed_tasks_dir}"
  puts ''
end

namespace :list do

  desc "lists tasks available to install"
  task :available do |t, args|
    if Dir.exists?(available_tasks_dir)
      cmd = "ls -1 #{available_tasks_dir}/"
      try(cmd, "failed to list contents of #{available_tasks_dir} directory")
    else
      puts "[#{t.name}] no tasks are installed at #{available_tasks_dir}"
    end

    puts ''
  end

  desc "lists currently installed tasks"
  task :installed do |t, args|
    if Dir.exists?(installed_tasks_dir)
      cmd = "ls -1 #{installed_tasks_dir}/"
      try(cmd, "failed to list contents of #{installed_tasks_dir} directory")
    else
      puts "[#{t.name}] no tasks are installed at #{installed_tasks_dir}"
    end

    puts ''
  end

end

desc "removes the tasks folder from the Loom SDK"
task :uninstall do |t, args|
  FileUtils.rm_r(installed_tasks_dir) if Dir.exists?(installed_tasks_dir)

  puts "[#{t.name}] task completed, #{installed_tasks_dir} was removed"
  puts ''
end


def config()
  @loom_config || (@loom_config = JSON.parse(File.read(loom_config_file)))
end

def exec_with_echo(cmd)
  puts(cmd)
  stdout = %x[#{cmd}]
  puts(stdout) unless stdout.empty?
  $?.exitstatus
end

def fail(message)
  abort("◈ #{message}")
end

def loom_config_file()
  'loom.config'
end

def available_tasks_dir()
  File.join(File.dirname(__FILE__), 'lib', 'tasks')
end

def installed_tasks_dir()
  File.join(Dir.home, '.loom', 'tasks')
end

def try(cmd, failure_message)
  fail(failure_message) if (exec_with_echo(cmd) != 0)
end

def write_loom_config(config)
  File.open(loom_config_file, 'w') { |f| f.write(JSON.pretty_generate(config)) }
end

