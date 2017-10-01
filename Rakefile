
require 'pathname'
require File.join(File.dirname(__FILE__), 'lib', 'tasks', 'rakefiles', 'support')
include LoomTasks


def available_tasks_dir()
  File.join(File.dirname(__FILE__), 'lib', 'tasks')
end

def installed_tasks_dir()
  File.join(Dir.home, '.loom', 'tasks')
end

def installed_rakefiles_dir()
  File.join(installed_tasks_dir, 'rakefiles')
end

def installed_templates_dir()
  File.join(installed_tasks_dir, 'templates')
end

task :default => :list_targets

task :list_targets do |t, args|
  a = "loomtasks v#{VERSION} Rakefile"
  b = "running on Ruby #{RUBY_VERSION}"
  puts "#{a} #{b}"
  system("rake -T")
end

desc [
  "installs rake task files for Loom",
  "files will be installed to #{installed_tasks_dir}"
].join("\n")
task :install do |t, args|
  Dir.mkdir(installed_tasks_dir) unless Dir.exists?(installed_tasks_dir)
  Dir.mkdir(installed_rakefiles_dir) unless Dir.exists?(installed_rakefiles_dir)
  Dir.mkdir(installed_templates_dir) unless Dir.exists?(installed_templates_dir)

  FileUtils.cp_r(Dir.glob(File.join('lib', 'tasks', '*.rake')), installed_tasks_dir)
  FileUtils.cp_r(Dir.glob(File.join('lib', 'tasks', 'rakefiles', '*.rake')), installed_rakefiles_dir)
  FileUtils.cp_r(Dir.glob(File.join('lib', 'tasks', 'rakefiles', '*.rb')), installed_rakefiles_dir)
  FileUtils.cp_r(Dir.glob(File.join('lib', 'tasks', 'templates', '*')), installed_templates_dir)

  puts "[#{t.name}] task completed, tasks installed to #{installed_tasks_dir}"
end

desc [
  "shows usage and project info",
].join("\n")
task :help do |t, args|
  system("rake -D")

  puts "Log bugs to: https://github.com/pixeldroid/loomtasks/issues"
  puts "Project home page: https://github.com/pixeldroid/loomtasks"
  puts ''
  puts "Please see the README for additional details."
end

desc [
  "reports loomtasks version (v#{VERSION})",
].join("\n")
task :version do |t, args|
  puts "loomtasks v#{VERSION}"
end

namespace :list do

  desc [
    "lists loomtasks files available to install",
    "files from this project are in #{available_tasks_dir}"
    ].join("\n")
  task :available do |t, args|
    if Dir.exists?(available_tasks_dir)
      puts("files available in #{available_tasks_dir}:")
      project_root  = Pathname.new(available_tasks_dir)
      Dir.glob(File.join("#{available_tasks_dir}", '**', '*')).reject { |f| File.directory?(f) }.each do |f|
        puts(Pathname.new(f).relative_path_from(project_root).to_s)
      end
    else
      puts "[#{t.name}] no files are available at #{available_tasks_dir}"
    end
  end

  desc [
    "lists currently installed task files",
    "installed task files are in #{installed_tasks_dir}"
  ].join("\n")
  task :installed do |t, args|
    if Dir.exists?(installed_tasks_dir)
      puts("files installed in #{installed_tasks_dir}:")
      project_root  = Pathname.new(installed_tasks_dir)
      Dir.glob(File.join("#{installed_tasks_dir}", '**', '*')).reject { |f| File.directory?(f) }.each do |f|
        puts(Pathname.new(f).relative_path_from(project_root).to_s)
      end
    else
      puts "[#{t.name}] no files are installed at #{installed_tasks_dir}"
    end
  end

end

desc [
  "removes the tasks folder from the Loom home directory",
  "the task folder is #{installed_tasks_dir}",
  "the entire tasks folder will be removed, so use with caution if you added anything in there",
].join("\n")
task :uninstall do |t, args|
  FileUtils.rm_r(installed_tasks_dir) if Dir.exists?(installed_tasks_dir)

  puts "[#{t.name}] task completed, #{installed_tasks_dir} was removed"
end
