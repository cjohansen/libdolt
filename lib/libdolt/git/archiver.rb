# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
#
#   This program is free software: you can redistribute it and/or modify
#   it under the terms of the GNU Affero General Public License as published by
#   the Free Software Foundation, either version 3 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#   GNU Affero General Public License for more details.
#
#   You should have received a copy of the GNU Affero General Public License
#   along with this program.  If not, see <http://www.gnu.org/licenses/>.
#++
require "fileutils"
require "shellwords"
require "libdolt/git"

module Dolt
  module Git
    class Archiver
      def initialize(work_dir, cache_dir)
        @work_dir = work_dir
        @cache_dir = cache_dir
      end

      # Returns a promise that resolves with the filename of the generated
      # tarball/zip file.
      #
      #   repo   - A repository object
      #   oid    - A valid commit oid
      #   format - A symbol. If it is not :zip, tar.gz is assumed.
      def archive(repo, oid, format = :tgz)
        filename = cache_path(repo, oid, format)
        return filename if File.exists?(filename)
        archive_repo(repo, oid, format)
      end

      private
      def archive_repo(repo, oid, format)
        process = Dolt::Git.shell(cmd(repo, oid, format))
        raise process.exception if !process.success?
        filename = cache_path(repo, oid, format)
        FileUtils.mv(work_path(repo, oid, format), filename)
        filename
      end

      def cmd(repository, oid, format)
        path_segment = repository.path_segment.gsub(/\//, "-")
        git = Dolt::Git.binary
        cmd = "sh -c '#{git} --git-dir #{repository.full_repository_path} archive "
        cmd += "--prefix='#{u(path_segment)}/' --format="
        wpath = u(work_path(repository, oid, format))
        cmd + (format.to_s == "zip" ? "zip #{u(oid)} > #{wpath}" : "tar #{u(oid)} | gzip -m > #{wpath}") + "'"
      end

      def cache_path(repository, oid, format)
        File.join(@cache_dir, basename(repository, oid, format))
      end

      def work_path(repository, oid, format)
        File.join(@work_dir, basename(repository, oid, format))
      end

      def basename(repository, oid, format)
        path_segment = "#{repository.path_segment}-#{oid}".gsub(/\//, "-")
        "#{path_segment}.#{ext(format)}"
      end

      def ext(format)
        format.to_s == "zip" ? "zip" : "tar.gz"
      end

      def u(string)
        Shellwords.escape(string)
      end
    end
  end
end
