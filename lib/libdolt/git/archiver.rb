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
require "when"
require "eventmachine"
require "em_pessimistic"
require "fileutils"

module Dolt
  module Git
    class Archiver
      def initialize(work_dir, cache_dir)
        # A hash of currently processing archiving jobs. It contains tuples of
        # "#{repo.id}-#{oid}-#{format}" => promises representing the eventual
        # completion of archiving tasks. When an archiving task is completed,
        # its promise is removed from the hash. Previously generated tarballs
        # can be found on disk.
        @processing = {}
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
        return When.resolve(filename) if File.exists?(filename)
        pending = pending_process(repo, oid, format)
        return pending if pending
        start_process(repo, oid, format)
      end

      private
      def process_id(repo, oid, format)
        "#{repo.id}-#{oid}-#{ext(format)}"
      end

      def pending_process(repo, oid, format)
        @processing[process_id(repo, oid, format)]
      end

      def start_process(repo, oid, format)
        @processing[process_id(repo, oid, format)] = When.defer do |d|
          p = EMPessimistic::DeferrableChildProcess.open(cmd(repo, oid, format))

          p.callback do |output, status|
            filename = cache_path(repo, oid, format)
            FileUtils.mv(work_path(repo, oid, format), filename)
            d.resolve(filename)
          end

          p.errback do |output, status|
            d.reject(Exception.new(output))
          end
        end
      end

      def cmd(repository, oid, format)
        path_segment = repository.path_segment.gsub(/\//, "-")
        cmd = "sh -c 'git --git-dir #{repository.full_repository_path} archive "
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
        path_segment = repository.path_segment.gsub(/\//, "-")
        "#{path_segment}-#{oid}.#{ext(format)}"
      end

      def ext(format)
        format.to_s == "zip" ? "zip" : "tar.gz"
      end

      # Unquote a string by stripping off any single or double quotes
      def u(string)
        string.gsub("'", '').gsub('"', '')
      end
    end
  end
end
