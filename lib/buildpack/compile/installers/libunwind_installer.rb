# Encoding: utf-8
# ASP.NET Core Buildpack
# Copyright 2015-2016 the original author or authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require_relative 'installer'

module AspNetCoreBuildpack
  class LibunwindInstaller < Installer
    CACHE_DIR = 'libunwind'.freeze

    def cache_dir
      CACHE_DIR
    end

    def initialize(build_dir, bp_cache_dir, deps_dir, deps_idx, manifest_file, shell)
      @bp_cache_dir = bp_cache_dir
      @build_dir = build_dir
      @deps_dir = deps_dir
      @deps_idx = deps_idx
      @manifest_file = manifest_file
      @shell = shell
    end

    def cached?
      # File.open can't create the directory structure
      return false unless File.exist? File.join(@bp_cache_dir, CACHE_DIR)
      cached_version = File.open(cached_version_file, File::RDONLY | File::CREAT).select { |line| line.chomp == version }
      !cached_version.empty?
    end

    def install(out)
      dest_dir = File.join(@deps_dir, @deps_idx, CACHE_DIR)

      out.print("libunwind version: #{version}")
      @shell.exec("#{buildpack_root}/compile-extensions/bin/download_dependency_by_name #{name} #{version} /tmp/#{dependency_name}", out)
      @shell.exec("#{buildpack_root}/compile-extensions/bin/warn_if_newer_patch_by_name #{name} #{version} #{buildpack_root}/manifest.yml", out)
      @shell.exec("mkdir -p #{dest_dir}; tar xzf /tmp/#{dependency_name} -C #{dest_dir}", out)
      write_version_file(version)
    end

    def install_description
      'Extracting libunwind'.freeze
    end

    def create_links(out)
      @shell.exec("mkdir -p #{File.join(@deps_dir, @deps_idx, 'lib')}; cd #{File.join(@deps_dir, @deps_idx, 'lib')}; ln -s ../libunwind/lib/* .", out)
    end

    def name
      'libunwind'.freeze
    end

    def library_path
      File.join('$HOME'.freeze, CACHE_DIR, 'lib'.freeze)
    end

    def should_install(_app_dir)
      !cached?
    end

    def version
      compile_extensions_dir = File.join(File.dirname(__FILE__), '..', '..', '..', '..', 'compile-extensions')
      @version ||= `#{compile_extensions_dir}/bin/default_version_for #{@manifest_file} #{name}`
    end

    private

    def dependency_name
      "libunwind-x-#{version}.tar.gz"
    end
  end
end
