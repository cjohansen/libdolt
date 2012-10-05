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
require "em/deferrable"
require "libdolt/git/blame"
require "libdolt/git/commit"
require "libdolt/git/submodule"
require "libdolt/git/tree"
require "libdolt/async/when"

module Dolt
  module Git
    class Repository < EMRugged::Repository
      def submodules(ref)
        d = EventMachine::DefaultDeferrable.new
        gm = rev_parse("#{ref}:.gitmodules")
        gm.callback do |config|
          d.succeed(Dolt::Git::Submodule.parse_config(config.content))
        end
        # Fails if .gitmodules cannot be found, which means no submodules
        gm.errback { |err| d.succeed([]) }
        d
      end

      def tree(ref, path)
        d = EventMachine::DefaultDeferrable.new
        rp = rev_parse("#{ref}:#{path}")
        rp.callback do |tree|
          break d.fail(StandardError.new("Not a tree")) unless tree.is_a?(Rugged::Tree)
          break d.succeed(tree) if !tree.find { |e| e[:type].nil? }
          annotate_submodules(ref, path, d, tree)
        end
        rp.errback { |err| d.fail(err) }
        d
      end

      def blame(ref, path)
        deferred_method("blame -l -t -p #{ref} #{path}") do |output, s|
          Dolt::Git::Blame.parse_porcelain(output)
        end
      end

      def log(ref, path, limit)
        entry_history(ref, path, limit)
      end

      def tree_history(ref, path, limit = 1)
        d = EventMachine::DefaultDeferrable.new
        rp = rev_parse("#{ref}:#{path}")
        rp.errback { |err| d.fail(err) }
        rp.callback do |tree|
          if tree.class != Rugged::Tree
            message = "#{ref}:#{path} is not a tree (#{tree.class.to_s})"
            break d.fail(Exception.new(message))
          end

          building = build_history(path || "./", ref, tree, limit)
          building.callback { |history| d.succeed(history) }
          building.errback { |err| d.fail(err) }
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
        d = EventMachine::DefaultDeferrable.new
        resolve = lambda { |p| path == "" ? p : File.join(path, p) }
        progress = When.all(entries.map do |e|
                              entry_history(ref, resolve.call(e[:name]), limit)
                            end)
        progress.errback { |e| d.fail(e) }
        progress.callback do |history|
          d.succeed(entries.map { |e| e.merge({ :history => history.shift }) })
        end
        d
      end

      def annotate_submodules(ref, path, deferrable, tree)
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

          deferrable.succeed(Dolt::Git::Tree.new(tree.oid, entries))
        end
      end

      def deferred_method(cmd, &block)
        d = EventMachine::DefaultDeferrable.new
        cmd = git(cmd)
        p = EMPessimistic::DeferrableChildProcess.open(cmd)

        p.callback do |output, status|
          d.succeed(block.call(output, status))
        end

        p.errback do |stderr, status|
          d.fail(stderr)
        end

        d
      end

      def git(cmd)
        "git --git-dir #{subject.path} #{cmd}"
      end
    end
  end
end
