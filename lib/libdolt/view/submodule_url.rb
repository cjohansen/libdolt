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

module Dolt
  module View
    module SubmoduleUrl
      def self.for(submodule)
        url = submodule[:url]
        commit = submodule[:oid]

        parsers.map { |p| p.browse_url(url, commit) }.compact.first
      end

      def self.parsers
        @parsers ||= [GitoriousOrg.new, GitHub.new, BitBucket.new, GenericParser.new]
      end

      def self.parsers=(value)
        @parsers = value
      end

      module Parser
        def browse_url(url, commit)
          mountpoints.each do |mountpoint|
            path = parse_mountpoint(mountpoint, url)
            return generate_url(*path, commit) if path
          end
          return nil
        end

        private

        def parse_mountpoint(mountpoint, url)
          base_url = mountpoint.base_url
          return nil unless url.include?(base_url)
          parts = url.gsub(base_url, '').gsub(/\.git$/, '').split("/")
          return parts[-2..-1]
        end
      end

      class HttpMountPoint
        attr_reader :host, :protocol

        def initialize(host, protocol = 'http')
          @host = host
          @protocol = protocol
        end

        def base_url
          "#{protocol}://#{host}/"
        end
      end

      class GitMountPoint
        attr_reader :host

        def initialize(host)
          @host = host
        end

        def base_url
          "git://#{host}/"
        end
      end

      class GitSshMountPoint
        attr_reader :user, :host

        def initialize(user, host)
          @user = user
          @host = host
        end

        def base_url
          "#{user}@#{host}:"
        end
      end

      class BitBucket
        include Parser

        def mountpoints
          [HttpMountPoint.new("bitbucket.org", "https"), GitSshMountPoint.new("git", "bitbucket.org")]
        end

        def generate_url(project, repository, commit)
          "https://bitbucket.org/#{project}/#{repository}/src/#{commit}"
        end
      end

      class GitHub
        include Parser

        def mountpoints
          [GitMountPoint.new("github.com"), HttpMountPoint.new("github.com", "https"), GitSshMountPoint.new("git", "github.com")]
        end

        def generate_url(project, repository, commit)
          "https://github.com/#{project}/#{repository}/tree/#{commit}"
        end
      end

      class GitoriousOrg
        include Parser

        def mountpoints
          [GitMountPoint.new("gitorious.org"),
           HttpMountPoint.new("git.gitorious.org", "http"),
           HttpMountPoint.new("git.gitorious.org", "https"),
           GitSshMountPoint.new("git", "gitorious.org")]
        end

        def generate_url(project, repository, commit)
          "https://gitorious.org/#{project}/#{repository}/source/#{commit}"
        end
      end

      class GenericParser
        def browse_url(url, commit)
          url
        end
      end
    end
  end
end
