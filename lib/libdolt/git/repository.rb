# encoding: utf-8
#--
#   Copyright (C) 2012 Gitorious AS
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
require "em_rugged/repository"
require "em_pessimistic/deferrable_child_process"
require "libdolt/git/blame"
require "libdolt/git/commit"
require "libdolt/git/submodule"
require "libdolt/git/tree"
require "when"

module Dolt
  module Git
    class Repository < EMRugged::Repository
      def submodules(ref)
        d = When.defer
        gm = rev_parse("#{ref}:.gitmodules")
        gm.callback do |config|
          d.resolve(Dolt::Git::Submodule.parse_config(config.content))
        end
        # Fails if .gitmodules cannot be found, which means no submodules
        gm.errback { |err| d.resolve([]) }
        d
      end

      def tree_entry(ref, path)
        When.defer do |d|
          rp = rev_parse("#{ref}:#{path}")
          rp.callback { |object| annotate_tree(d, ref, path, object) }
          rp.errback { |err| d.reject(err) }
        end
      end

      def tree(ref, path)
        When.defer do |d|
          rp = rev_parse("#{ref}:#{path}")
          rp.callback do |object|
            if !object.is_a?(Rugged::Tree)
              next d.reject(StandardError.new("Not a tree"))
            end
            annotate_tree(d, ref, path, object)
          end
          rp.errback { |err| d.reject(err) }
        end
      end

      def blame(ref, path)
        deferred_method("blame -l -t -p #{ref} -- #{path}") do |output, s|
          Dolt::Git::Blame.parse_porcelain(output)
        end
      end

      def log(ref, path, limit)
        entry_history(ref, path, limit)
      end

      def tree_history(ref, path, limit = 1)
        d = When.defer
        rp = rev_parse("#{ref}:#{path}")
        rp.errback { |err| d.reject(err) }
        rp.callback do |tree|
          if tree.class != Rugged::Tree
            message = "#{ref}:#{path} is not a tree (#{tree.class.to_s})"
            break d.reject(Exception.new(message))
          end

          building = build_history(path || "./", ref, tree, limit)
          building.callback { |history| d.resolve(history) }
          building.errback { |err| d.reject(err) }
        end
        d
      end

      private
      def entry_history(ref, entry, limit)
        deferred_method("log -n #{limit} #{ref} -- #{entry}") do |out, s|
          Dolt::Git::Commit.parse_log(out)
        end
      end

      def build_history(path, ref, entries, limit)
        d = When.defer
        resolve = lambda { |p| path == "" ? p : File.join(path, p) }
        progress = When.all(entries.map do |e|
                              entry_history(ref, resolve.call(e[:name]), limit)
                            end)
        progress.errback { |e| d.reject(e) }
        progress.callback do |history|
          d.resolve(entries.map { |e| e.merge({ :history => history.shift }) })
        end
        d
      end

      def annotate_tree(d, ref, path, object)
        if object.class.to_s.match(/Blob/) || !object.find { |e| e[:type].nil? }
          return d.resolve(object)
        end

        annotate_submodules(d, ref, path, object)
      end

      def annotate_submodules(deferrable, ref, path, tree)
        submodules(ref).callback do |submodules|
          entries = tree.entries.map do |entry|
            if entry[:type].nil?
              mod = path == "" ? entry[:name] : File.join(path, entry[:name])
              meta = submodules.find { |s| s[:path] == mod }
              if meta
                entry[:type] = :submodule
                entry[:url] = meta[:url]
              end
            end
            entry
          end

          deferrable.resolve(Dolt::Git::Tree.new(tree.oid, entries))
        end
      end

      def deferred_method(cmd, &block)
        d = When.defer
        cmd = git(cmd)
        p = EMPessimistic::DeferrableChildProcess.open(cmd)

        p.callback do |output, status|
          d.resolve(block.call(output, status))
        end

        p.errback do |stderr, status|
          d.reject(stderr)
        end

        d
      end

      def git(cmd)
        "git --git-dir #{path} #{cmd}"
      end
    end
  end
end
