# encoding: utf-8
#--
#   Copyright (C) 2012-2013 Gitorious AS
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
require "eventmachine"

# Need consistent Time formatting in JSON
require "time"
class Time; def to_json(*args); "\"#{iso8601}\""; end; end

module Dolt
  class RepoActions
    def initialize(repo_resolver, archiver = nil)
      @repo_resolver = repo_resolver
      @archiver = archiver
    end

    def blob(repo, ref, path, &block)
      repo_action(repo, ref, path, :blob, :rev_parse, "#{ref}:#{path}", &block)
    end

    def tree(repo, ref, path, &block)
      repo_action(repo, ref, path, :tree, :tree, ref, path, &block)
    end

    def tree_entry(repo, ref, path, &block)
      repository = resolve_repository(repo)
      d = repository.tree_entry(ref, path)
      d.callback do |result|
        key = result.class.to_s.match(/Blob/) ? :blob : :tree
        block.call(nil, tpl_data(repository, ref, path, { key => result, :type => key }))
      end
      d.errback { |err| block.call(err, nil) }
    end

    def blame(repo, ref, path, &block)
      repo_action(repo, ref, path, :blame, :blame, ref, path, &block)
    end

    def history(repo, ref, path, count, &block)
      repo_action(repo, ref, path, :commits, :log, ref, path, count, &block)
    end

    def refs(repo, &block)
      repository = resolve_repository(repo)
      d = repository.refs
      d.callback do |refs|
        names = refs.map(&:name)
        block.call(nil, {
                     :tags => expand_refs(repository, names, :tags),
                     :heads => expand_refs(repository, names, :heads)
                   }.merge(repository.to_hash))
      end
      d.errback { |err| block.call(err, nil) }
    end

    def tree_history(repo, ref, path, count, &block)
      repo_action(repo, ref, path, :tree, :tree_history, ref, path, count, &block)
    end

    def archive(repo, ref, format, &block)
      repository = resolve_repository(repo)
      d = @archiver.archive(repository, ref, format)
      d.callback { |filename| block.call(nil, filename) }
      d.errback { |err| block.call(err, nil) }
    end

    def repositories
      repo_resolver.all
    end

    def resolve_repository(repo)
      ResolvedRepository.new(repo, repo_resolver.resolve(repo))
    end

    private
    def repo_resolver; @repo_resolver; end

    def repo_action(repo, ref, path, data, method, *args, &block)
      repository = resolve_repository(repo)
      d = repository.send(method, *args)
      d.callback do |result|
        block.call(nil, tpl_data(repository, ref, path, { data => result }))
      end
      d.errback { |err| block.call(err, nil) }
    end

    def tpl_data(repo, ref, path, locals = {})
      { :path => path,
        :ref => ref }.merge(repo.to_hash).merge(locals)
    end

    def expand_refs(repository, names, type)
      names.select { |n| n =~ /#{type}/ }.map do |n|
        [n.sub(/^refs\/#{type}\//, ""), repository.rev_parse_oid_sync(n)]
      end
    end

    def u(str)
      # Temporarily swap the + out with a magic byte, so
      # filenames/branches with +'s won't get unescaped to a space
      CGI.unescape(str.gsub("+", "\001")).gsub("\001", '+')
    end
  end

  class ResolvedRepository
    def initialize(slug, repository)
      @repository = repository
      @data = { :repository_slug => slug }
      @data[:repository_meta] = repository.meta if repository.respond_to?(:meta)
    end

    def to_hash
      @data
    end

    def method_missing(method, *args, &block)
      @repository.send(method, *args, &block)
    end
  end
end
