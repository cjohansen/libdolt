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
if RUBY_VERSION > "1.9"
  require "simplecov"
  require "simplecov-rcov"
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter
  SimpleCov.start
end
require "bundler/setup"
require "minitest/autorun"
require "libdolt/view"
require "tiltout"
require "stringio"

Bundler.require(:default, :test)

# Ensure consistent timing
ENV["TZ"] = "UTC-2"

module Dolt
  def self.fixture_repo_path
    File.join(File.dirname(__FILE__), "fixtures/dolt-test-repo.git")
  end

  module Html
    def select(html, tag_name)
      html.scan(/<#{tag_name}[^>]*>.*?<\/#{tag_name}>/m)
    end
  end

  module ViewTest
    def prepare_renderer(options = {}, helpers = nil)
      root = File.join(File.dirname(__FILE__), "..", "views")
      renderer = Tiltout.new(root, options)
      renderer.helper(helpers || [Dolt::View::MultiRepository,
          Dolt::View::Urls,
          Dolt::View::Object,
          Dolt::View::Blob,
          Dolt::View::Tree,
          Dolt::View::Blame,
          Dolt::View::SyntaxHighlight,
          Dolt::View::Commit,
          Dolt::View::Gravatar,
          Dolt::View::Breadcrumb])
      renderer
    end
  end

  class FakeProcess
    attr_reader :stdin, :stdout, :stderr

    def initialize(status, stdin = nil, stdout = nil, stderr = nil)
      @status = status
      @stdin = stream(stdin)
      @stdout = stream(stdout)
      @stderr = stream(stderr)
    end

    def success?; @status == 0; end
    def exit_code; @status; end
    def exception; Exception.new; end

    private
    def stream(ios)
      return ios if !ios.nil? && !ios.is_a?(String)
      StringIO.new(ios || "")
    end
  end
end

module Stub
  class Blob
    def is_a?(type)
      type == Rugged::Blob
    end
  end

  class Tree
    def is_a?(type)
      type == Rugged::Tree
    end
  end
end

module Test
  class Router
    def tree_url(repo, ref, path)
      "/#{repo}/tree/#{ref}:#{path}"
    end

    def blob_url(repo, ref, path)
      "/#{repo}/blob/#{ref}:#{path}"
    end

    def tree_entry_url(repo, ref, path)
      "/#{repo}/source/#{ref}:#{path}"
    end

    def blame_url(repo, ref, path)
      "/#{repo}/blame/#{ref}:#{path}"
    end

    def history_url(repo, ref, path)
      "/#{repo}/history/#{ref}:#{path}"
    end

    def tree_history_url(repo, ref, path)
      "/#{repo}/tree_history/#{ref}:#{path}"
    end

    def raw_url(repo, ref, path)
      "/#{repo}/raw/#{ref}:#{path}"
    end

    def method_missing(name, *args, &block)
      @actions.send(name, *args, &block)
    end
  end

  class RedirectingRouter < Router
    def redirect_refs?; true; end
  end

  class Renderer
    attr_reader :data
    def initialize(body = ""); @body = body; end

    def render(action, data, options = {})
      @action = action
      @data = data
      "#{action}:#@body"
    end
  end

  class Lookup
    attr_reader :repo, :ref, :path

    def initialize(response)
      @response = response
    end

    def blob(repo, ref, path)
      respond(:blob, repo, ref, path)
    end

    def tree(repo, ref, path)
      respond(:tree, repo, ref, path)
    end

    def tree_entry(repo, ref, path)
      respond(:tree_entry, repo, ref, path)
    end

    def raw(repo, ref, path)
      respond(:raw, repo, ref, path)
    end

    def blame(repo, ref, path)
      respond(:blame, repo, ref, path)
    end

    def history(repo, ref, path, limit)
      respond(:history, repo, ref, path)
    end

    def refs(repo)
      respond(:refs, repo)
    end

    def tree_history(repo, ref, path, count)
      respond(:tree_history, repo, ref, path)
    end

    def respond(type, repo, ref = nil, path = nil)
      @repo = repo
      @ref = ref
      @path = path
      data = { :ref => ref, :repository => repo }
      data[type != :tree_entry ? type : (@response.class.to_s =~ /Tree/ ? :tree : :blob)] = @response
      data
    end

    def rev_parse_oid(repo, ref)
      "a" * 40
    end
  end
end
