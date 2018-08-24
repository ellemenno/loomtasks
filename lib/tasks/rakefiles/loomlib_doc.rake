require 'fileutils'
require 'net/http'
require 'open-uri'
require 'tmpdir'
require 'uri'

require File.join(File.dirname(__FILE__), 'support')
include LoomTasks


@doc_config = nil

def doc_config()
  @doc_config || (@doc_config = LoomTasks.parse_yaml_config(doc_config_file))
end

def doc_build_dir()
  File.join(Dir.pwd, 'docs-build')
end

def doc_config_file()
  File.join('doc', 'src', '_config.yml')
end

def write_doc_config(config)
  LoomTasks.write_yaml_config(doc_config_file, config)
end

def build_docs(config_path, in_dir, out_dir)
  sdk_version = lib_config['sdk_version']
  sdk_dir = LoomTasks.sdk_root(sdk_version)
  processor = 'ghpages'

  options = [
    "-p #{processor}",
    "-c #{config_path}",
    "-l #{sdk_dir}/libs/#{LoomTasks.const_lib_name}.loomlib",
    "-i #{in_dir}",
    "-o #{out_dir}",
  ]

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
DOC_SOURCE_DIR = File.join(PROJECT_ROOT, 'doc', 'src')

TOOL_ERRORS = {
  :lsdoc => 'lsdoc not installed. See https://github.com/pixeldroid/lsdoc',
  :progp => 'missing programming-pages.rake. try rake docs:install_template'
}

lsdoc_exe = LoomTasks.path_to_exe('lsdoc')
if lsdoc_exe
  lsdoc_version = %x(#{lsdoc_exe} -v 2>&1).chomp
  Rake::Task['list_targets'].enhance { puts "(using #{lsdoc_version})" }
else
  Rake::Task['list_targets'].enhance { puts "(NOTE: #{TOOL_ERRORS[:lsdoc]})" }
end

unless Rake::Task.task_defined?('docs:build')
  begin
    load(File.join(DOC_TEMPLATE_DIR, '_tasks', 'programming-pages.rake'))
    Rake::Task['list_targets'].enhance { puts "(using programming-pages #{template_version})" } # template_version from programming-pages.rake
    Rake::Task['docs:build'].enhance ['docs:gen_api', 'docs:cp_build_dir'] # add pre-reqs
    Rake::Task['docs:build'].enhance { Rake::Task['docs:rm_build_dir'].invoke() } # add a post-step
  rescue LoadError
    # silent failure here, since it's not fatal,
    # and the user needs to be given a chance to install the template
    Rake::Task['list_targets'].enhance { puts "(NOTE: #{TOOL_ERRORS[:progp]})" }
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
    LoomTasks.fail(TOOL_ERRORS[:lsdoc]) unless LoomTasks.path_to_exe('lsdoc')
    LoomTasks.fail(TOOL_ERRORS[:progp]) unless Rake::Task.task_defined?('docs:build')
  end

  task :update_version do |t, args|
    lib_version = LoomTasks.lib_version(LoomTasks.const_lib_version_file)

    doc_config['project']['version'] = lib_version
    write_doc_config(doc_config)

    puts "[#{t.name}] task completed, #{doc_config_file} updated with version #{lib_version}"
  end

  desc [
    "downloads the latest programming pages release from GitHub",
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

    puts "[#{t.name}] generating api files..."
    build_docs(config_path, in_dir, out_dir)

    puts "[#{t.name}] task completed, api docs generated into #{out_dir}"
  end

  task :cp_build_dir do |t, args|
    if (Dir.exists?(doc_build_dir))
      target_dir = ghpages_dir # loaded from programming-pages.rake
      puts "[#{t.name}] adding api files..."
      FileUtils.cp_r(File.join(doc_build_dir, '.'), target_dir)
    else
      puts "[#{t.name}] no api files found in #{doc_build_dir}"
    end
  end

  task :rm_build_dir do |t, args|
    if (Dir.exists?(doc_build_dir))
      puts "[#{t.name}] removing temporary build dir #{doc_build_dir}"
      FileUtils.rm_rf(doc_build_dir)
    end
  end

end
