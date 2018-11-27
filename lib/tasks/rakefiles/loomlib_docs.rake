require 'fileutils'
require 'pathname'
require 'tmpdir'

require File.join(File.dirname(__FILE__), 'support')
include LoomTasks


@doc_config = nil

def doc_config()
  @doc_config || (@doc_config = LoomTasks.parse_yaml_config(doc_config_file))
end

def doc_root_dir()
  File.join(Pathname.pwd, 'docs')
end

def doc_api_dir()
  File.join(doc_root_dir, '_api')
end

def doc_config_file()
  File.join(doc_root_dir, '_config.yml')
end

def write_doc_config(config)
  LoomTasks.write_yaml_config(doc_config_file, config)
end

def jekyll_cmd(verb)
  "bundle exec jekyll #{verb} --source #{doc_root_dir} --layouts #{doc_root_dir}/_layouts"
end

def jekyll_build
  jekyll_cmd('build')
end

def jekyll_watch
  jekyll_cmd('serve --watch --incremental')
end

def jekyll_serve_only
  "bundle exec jekyll serve --skip-initial-build --no-watch"
end

def build_api_docs(out_dir)
  sdk_version = lib_config['sdk_version']
  sdk_dir = LoomTasks.sdk_root(sdk_version)
  processor = 'ghpages'

  options = [
    "-p #{processor}",
    "-l #{sdk_dir}/libs/#{LoomTasks.const_lib_name}.loomlib",
    "-o #{out_dir}",
  ]

  cmd = "lsdoc #{options.join(' ')}"
  try(cmd, "failed to generate docs")
end


TOOL_ERRORS = {
  :lsdoc => 'lsdoc not installed. See https://github.com/pixeldroid/lsdoc',
  :bundler => 'gem dependencies not all resolved. Please run: bundle install',
  :doc_config => "missing doc config.\nTo scaffold a new docs directory, run: rake -f ~/.loom/tasks/scaffolding.rake new:docs",
}

lsdoc_exe = LoomTasks.path_to_exe('lsdoc')
if lsdoc_exe
  lsdoc_version = %x(#{lsdoc_exe} -v 2>&1).chomp
  Rake::Task['list_targets'].enhance { puts "(using #{lsdoc_version})" }
else
  Rake::Task['list_targets'].enhance { puts "(NOTE: #{TOOL_ERRORS[:lsdoc]})" }
end


namespace :docs do

  task :check_tools do |t, args|
    LoomTasks.fail(TOOL_ERRORS[:lsdoc]) unless LoomTasks.path_to_exe('lsdoc')
    LoomTasks.fail(TOOL_ERRORS[:bundler]) unless (LoomTasks.exec_with_echo('bundle check') == LoomTasks::EXIT_OK)
    LoomTasks.fail(TOOL_ERRORS[:doc_config]) if (doc_config.empty?)
  end

  task :update_version do |t, args|
    lib_version = LoomTasks.lib_version(LoomTasks.const_lib_version_file)

    doc_config['project']['version'] = lib_version
    write_doc_config(doc_config)

    puts "[#{t.name}] task completed, #{doc_config_file} updated with version #{lib_version}"
  end

  desc [
    "creates api docs compatible with the programming pages template",
    "  https://github.com/pixeldroid/programming-pages",
    "outputs GitHub pages compatible files at docs/",
    "requires lsdoc to be installed",
    "sets the library version number into #{doc_config_file}",
    "  #{doc_config_file} is expected to have a project.version key",
  ].join("\n")
  task :gen_api => ['docs:check_tools', 'docs:update_version', 'lib:install'] do |t, args|

    if (Dir.exists?(doc_api_dir))
      FileUtils.rm_r(Dir.glob(File.join(doc_api_dir, '*')))
      puts "[#{t.name}] emptying #{doc_api_dir} to start clean"
    end

    puts "[#{t.name}] generating api files..."
    build_api_docs(doc_root_dir)

    puts "[#{t.name}] task completed, api docs generated into #{doc_api_dir}"
  end

  desc [
    "calls jekyll to [just] generate the docs site",
    "  cmd: #{jekyll_build}",
  ].join("\n")
  task :build_site => ['docs:gen_api'] do |t, args|
    try(jekyll_build, 'unable to create docs')
    puts "[#{t.name}] task completed, find updated docs in ./_site"
  end

  desc [
    "calls jekyll to watch the docs and rebuild the site when files are changed",
    "  use CTRL-c to exit",
    "  cmd: #{jekyll_watch}",
  ].join("\n")
  task :watch_site do |t, args|
    begin                 # run jekyll
      puts jekyll_watch
      system(jekyll_watch)
    rescue Exception => e # capture the interrupt signal from a quit app
      puts ' (quit)'
    end
  end

  desc [
    "calls jekyll to serve the docs site, without first building it",
    "  cmd: #{jekyll_serve_only}",
  ].join("\n")
  task :serve_site do |t, args|
    begin                 # run jekyll
      puts jekyll_serve_only
      system(jekyll_serve_only)
    rescue Exception => e # capture the interrupt signal from a quit app
      puts ' (quit)'
    end
  end

end

desc [
  "builds and serves the documentation site",
].join("\n")
task :docs => ['docs:build_site', 'docs:serve_site']
