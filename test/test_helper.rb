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
require "bundler/setup"
require "minitest/autorun"
require "em/minitest/spec"
require "eventmachine"
require "libdolt/view"
require "tiltout"

Bundler.require(:default, :test)

module Dolt
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
end
