# Encoding: utf-8
# ASP.NET Core Buildpack
# Copyright 2014-2016 the original author or authors.
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

require 'fileutils'
require 'open3'

module AspNetCoreBuildpack
  class Copier
    def cp(from, to, out)
      before = files_in_dest(to)
      FileUtils.mkdir_p(to)
      args = ['-R']
      args += ['-l', '--remove-destination'] if RUBY_PLATFORM =~ /linux/
      _, s = Open3.capture2('cp', *args, from, to)
      raise "Could not copy from #{from} to #{to}" unless s.success?
      after = files_in_dest(to)

      out.print("Copied #{(after - before).length} files from #{from} to #{to}")
    end

    private

    def files_in_dest(dest)
      Dir.glob("#{dest}/**/*", File::FNM_DOTMATCH).select do |f|
        File.basename(f).delete('.') != ''
      end
    end
  end
end
