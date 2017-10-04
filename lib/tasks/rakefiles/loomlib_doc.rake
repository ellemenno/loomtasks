
require 'fileutils'

require File.join(File.dirname(__FILE__), 'support')
include LoomTasks


def build_docs(in_dir, out_dir)
  sdk_version = lib_config['sdk_version']
  sdk_dir = LoomTasks.sdk_root(sdk_version)
  processor = 'ghpages'
  template_dir = File.join(sdk_dir, 'ghpages-template')

  options = [
    "-p #{processor}",
    "-t #{template_dir}",
    "-l #{sdk_dir}/libs/#{LoomTasks.const_lib_name}.loomlib",
    "-o #{out_dir}",
    "-c #{in_dir}/lsdoc.config",
    "-i #{in_dir}/index.md",
  ]

  examples_dir = File.join(in_dir, 'examples')
  guides_dir = File.join(in_dir, 'guides')

  options << "-e #{examples_dir}" if (Dir.exists?(examples_dir))
  options << "-g #{guides_dir}" if (Dir.exists?(guides_dir))

  cmd = "lsdoc #{options.join(' ')}"
  try(cmd, "failed to generate docs")
end

LIB_DOC = 'docs'
JEKYLL_CMD = 'jekyll serve -s docs/ -d docs-site -I'

[
  File.join('docs', '**'),
].each { |f| CLEAN << f }
[
  'docs',
].each { |f| CLOBBER << f }

FileList[
  File.join('doc', '*.*'),
].each do |src|
  file LIB_DOC => src
end

namespace :docs do

task :check_tools do |t, args|
  LoomTasks.fail('lsdoc not installed. See https://github.com/pixeldroid/lsdoc') unless (LoomTasks.which('lsdoc'))
end

  desc [
    "creates docs ready for rendering by github pages, or jekyll",
    "requires lsdoc to be installed",
    "expects user-generated documentation to be at doc/,",
    "outputs GitHub pages compatible files at docs/,",
    "if jekyll is installed, you can preview the doc site locally:",
    "  $ #{JEKYLL_CMD}",
  ].join("\n")
  task :ghpages => ['docs:check_tools', 'lib:install'] do |t, args|
    pwd = Dir.pwd
    in_dir = File.join(pwd, 'doc')
    out_dir = File.join(pwd, 'docs')

    if (Dir.exists?(out_dir))
      FileUtils.rm_r(Dir.glob(File.join(out_dir, '*')))
      puts "[#{t.name}] emptying #{out_dir} to start clean"
    end

    build_docs(in_dir, out_dir)

    puts "[#{t.name}] task completed, docs generated into #{out_dir}"
    puts "[#{t.name}] preview locally: #{JEKYLL_CMD}" if (LoomTasks.which('jekyll'))
  end

end

desc [
  "shorthand for rake docs:ghpages",
].join("\n")
task :docs => 'docs:ghpages'
