require 'fileutils'
require 'net/http'
require 'open-uri'
require 'tmpdir'
require 'uri'

require File.join(File.dirname(__FILE__), 'support')
include LoomTasks


@doc_config = nil

def doc_config()
  @doc_config || (@doc_config = LoomTasks.parse_loom_config(doc_config_file))
end

def doc_build_dir()
  File.join(Dir.pwd, 'docs-build')
end

def doc_config_file()
  File.join('doc', 'lsdoc.config')
end

def write_doc_config(config)
  LoomTasks.write_loom_config(doc_config_file, config)
end

def build_docs(config_path, in_dir, out_dir, template_dir)
  sdk_version = lib_config['sdk_version']
  sdk_dir = LoomTasks.sdk_root(sdk_version)
  processor = 'ghpages'

  options = [
    "-p #{processor}",
    "-t #{template_dir}",
    "-l #{sdk_dir}/libs/#{LoomTasks.const_lib_name}.loomlib",
    "-o #{out_dir}",
    "-c #{config_path}",
    "-i #{in_dir}/index.md",
  ]

  examples_dir = File.join(in_dir, 'examples')
  guides_dir = File.join(in_dir, 'guides')

  options << "-e #{examples_dir}" if (Dir.exists?(examples_dir))
  options << "-g #{guides_dir}" if (Dir.exists?(guides_dir))

  cmd = "lsdoc #{options.join(' ')}"
  try(cmd, "failed to generate docs")
end

def update_doc_version()
  lib_version = LoomTasks.lib_version(LoomTasks.const_lib_version_file)
  doc_config['project']['version'] = doc_version
  write_doc_config(doc_config)
end

LIB_DOC = 'docs'

PP_RELEASE_API = 'https://api.github.com/repos/pixeldroid/programming-pages/releases/latest'
PROJECT_ROOT = Dir.pwd
DOC_TEMPLATE_DIR = File.join(PROJECT_ROOT, 'doc', 'template')
DOC_SOURCE_DIR = doc_build_dir

unless Rake::Task.task_defined?('docs:build')
  begin
    load File.join(DOC_TEMPLATE_DIR, '_tasks', 'programming-pages.rake')
    Rake::Task['docs:build'].enhance ['docs:gen_api'] # add a pre-req
    Rake::Task['docs:build'].enhance { Rake::Task['docs:rm_build_dir'].invoke() } # add a post-step
  rescue LoadError
    # silent failure here, since it's not fatal,
    # and the user needs to be given a chance to install the template
  end
end


[
  File.join('docs', '**'),
].each { |f| CLEAN << f }
[
  'docs',
].each { |f| CLOBBER << f }

FileList[
  File.join('doc', 'src', '*.*'),
].each do |src|
  file LIB_DOC => [src]
end

namespace :docs do

  task :check_tools do |t, args|
    LoomTasks.fail('lsdoc not installed. See https://github.com/pixeldroid/lsdoc') unless (LoomTasks.path_to_exe('lsdoc'))
    LoomTasks.fail('missing programming-pages.rake. try rake docs:install_template') unless Rake::Task.task_defined?('docs:build')
  end

  task :update_version do |t, args|
    lib_version = LoomTasks.lib_version(LoomTasks.const_lib_version_file)

    doc_config['project']['version'] = lib_version
    write_doc_config(doc_config)

    puts "[#{t.name}] task completed, #{doc_config_file} updated with version #{lib_version}"
  end

  desc [
    "downloads the latest programming pages release from GitHub,",
    "  installs to DOC_TEMPLATE_DIR",
  ].join("\n")
  task :install_template do |t, args|
    puts "[#{t.name}] asking GitHub for latest release.."

    uri = URI(PP_RELEASE_API)

    begin
      response = Net::HTTP.get_response(uri)
      LoomTasks.fail("#{response.code} - failed to access GitHub API at '#{PP_RELEASE_API}'") unless (response.code == '200')
    rescue SocketError
      LoomTasks.fail("failed to connect; is there network access?")
    end

    result = JSON.parse(response.body)
    asset_url = result['assets'].first['browser_download_url']
    puts "[#{t.name}] found asset at '#{asset_url}'"

    FileUtils.remove_dir(DOC_TEMPLATE_DIR) if (Dir.exists?(DOC_TEMPLATE_DIR))

    Dir.mktmpdir do |tmp_dir|
      Dir.chdir(tmp_dir) do
        puts "[#{t.name}] starting download.."
        uri = URI(asset_url)
        filepath = File.join('.', File.basename(asset_url))
        IO.write(filepath, uri.open().read())
        puts "[#{t.name}] download complete"

        puts "[#{t.name}] unzipping template.."
        cmd = "unzip -q #{filepath}"
        try(cmd, "unzip failed")

        puts "[#{t.name}] copying template files to DOC_TEMPLATE_DIR"
        FileUtils.cp_r(Dir.glob('*/').first, DOC_TEMPLATE_DIR)
      end
    end

    puts "[#{t.name}] task completed, template installed to #{DOC_TEMPLATE_DIR}"
  end

  desc [
    "creates api docs compatible with the programming pages template",
    "  https://github.com/pixeldroid/programming-pages",
    "requires programming pages template to be installed",
    "requires lsdoc to be installed",
    "generates into temp dir at #{doc_build_dir}",
    "expects user-generated documentation to be at doc/src/,",
    "expects programming-pages template to be at doc/template/,",
    "sets the library version number into #{doc_config_file}",
    "  #{doc_config_file} is expected to have a project.version key",
    "outputs GitHub pages compatible files at docs/",
  ].join("\n")
  task :gen_api => ['docs:check_tools', 'lib:install', 'docs:update_version'] do |t, args|
    pwd = Dir.pwd
    config_path = File.join(pwd, 'doc', 'lsdoc.config')
    template_dir = File.join(pwd, 'doc', 'template')
    in_dir = File.join(pwd, 'doc', 'src')
    out_dir = doc_build_dir

    if (Dir.exists?(out_dir))
      FileUtils.rm_r(Dir.glob(File.join(out_dir, '*')))
      puts "[#{t.name}] emptying #{out_dir} to start clean"
    end

    build_docs(config_path, in_dir, out_dir, template_dir)

    puts "[#{t.name}] task completed, docs generated into #{out_dir}"
  end

  task :rm_build_dir do |t, args|
    if (Dir.exists?(doc_build_dir))
      FileUtils.rm_rf(doc_build_dir)
      puts "[#{t.name}] removing temporary build dir #{doc_build_dir}"
    end
  end

end
