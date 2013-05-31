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

# Need consistent Time formatting in JSON
require "time"
class Time; def to_json(*args); "\"#{iso8601}\""; end; end

module Dolt
  class RepoActions
    def initialize(repo_resolver, archiver = nil)
      @repo_resolver = repo_resolver
      @archiver = archiver
    end

    def blob(repo, ref, path)
      repo_action(repo, ref, path, :blob, :rev_parse, "#{ref}:#{path}")
    end

    def tree(repo, ref, path)
      repo_action(repo, ref, path, :tree, :tree, ref, path)
    end

    def tree_entry(repo, ref, path)
      repository = resolve_repository(repo)
      result = repository.tree_entry(ref, path)
      key = result.class.to_s.match(/Blob/) ? :blob : :tree
      tpl_data(repository, ref, path, { key => result, :type => key })
    end

    def blame(repo, ref, path)
      repo_action(repo, ref, path, :blame, :blame, ref, path)
    end

    def history(repo, ref, path, count)
      repo_action(repo, ref, path, :commits, :log, ref, path, count)
    end

    def refs(repo)
      repository = resolve_repository(repo)
      names = repository.refs.map(&:name)
      {
        :tags => expand_refs(repository, names, :tags),
        :heads => expand_refs(repository, names, :heads)
      }.merge(repository.to_hash)
    end

    def tree_history(repo, ref, path, count)
      repo_action(repo, ref, path, :tree, :tree_history, ref, path, count)
    end

    def archive(repo, ref, format)
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

    def rev_parse_oid(repo, ref)
      resolve_repository(repo).rev_parse_oid(ref)
    end

    private
    def repo_resolver; @repo_resolver; end

    def repo_action(repo, ref, path, data, method, *args)
      repository = resolve_repository(repo)

      tpl_data(repository, ref, path, {
          data => repository.send(method, *args)
        })
    end

    def tpl_data(repo, ref, path, locals = {})
      { :path => path,
        :ref => ref }.merge(repo.to_hash).merge(locals)
    end

    def expand_refs(repository, names, type)
      names.select { |n| n =~ /#{type}/ }.map do |n|
        [n.sub(/^refs\/#{type}\//, ""), repository.rev_parse_oid(n)]
      end
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
