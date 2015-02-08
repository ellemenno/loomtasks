# encoding: utf-8

require File.join(File.dirname(__FILE__), 'lib', 'tasks', 'support')
include LoomTasks


def available_tasks_dir()
  File.join(File.dirname(__FILE__), 'lib', 'tasks')
end

def installed_tasks_dir()
  File.join(Dir.home, '.loom', 'tasks')
end

task :default => :list_targets

task :list_targets do |t, args|
  a = "LoomTasks v#{VERSION} Rakefile"
  b = "running on Ruby #{RUBY_VERSION}"
  puts "#{a} #{b}"
  system("rake -T")
  puts ''
end

desc "installs rake task files for Loom"
task :install do |t, args|
  Dir.mkdir(installed_tasks_dir) unless Dir.exists?(installed_tasks_dir)

  FileUtils.cp_r(Dir.glob(File.join('lib', 'tasks', '*.rake')), installed_tasks_dir)
  FileUtils.cp_r(Dir.glob(File.join('lib', 'tasks', '*.rb')), installed_tasks_dir)

  puts "[#{t.name}] task completed, tasks installed to #{installed_tasks_dir}"
  puts ''
end

namespace :list do

  desc "lists task files available to install"
  task :available do |t, args|
    if Dir.exists?(available_tasks_dir)
      puts("available tasks in #{available_tasks_dir}")
      Dir.glob("#{available_tasks_dir}/*").each { |f| puts(File.basename(f)) }
    else
      puts "[#{t.name}] no tasks are installed at #{available_tasks_dir}"
    end

    puts ''
  end

  desc "lists currently installed task files"
  task :installed do |t, args|
    if Dir.exists?(installed_tasks_dir)
      puts("installed tasks in #{installed_tasks_dir}")
      Dir.glob("#{installed_tasks_dir}/*").each { |f| puts(File.basename(f)) }
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
