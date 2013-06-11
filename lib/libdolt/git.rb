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
require "open3"
require "libdolt/git/process"
require "shellwords"

module Dolt
  module Git
    def self.shell(command)
      stdin, stdout, stderr = Open3.popen3(command)
      Dolt::Git::Process.new(stdin, stdout, stderr, $?)
    end

    def self.git(git_dir, command)
      args = Shellwords.join(command.split(" "))
      shell("#{binary} --git-dir #{git_dir} #{args}")
    end

    def self.binary
      @binary ||= "git"
    end

    def self.binary=(path)
      @binary = path
    end

    def self.git_repo?(path)
      return true if path.split(".").last == "git"
      File.exists?(File.join(path, ".git"))
    end
  end
end
