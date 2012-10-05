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
require "makeup/markup"
require "makeup/syntax_highlighter"

module Dolt
  module View
    module Markup
      def render_markup(path, content)
        "<div class=\"gts-markup\">#{markuper.render(path, content)}</div>"
      end

      def supported_markup_format?(path)
        Makeup::Markup.can_render?(path)
      end

      def format_text_blob(path, code, repo = nil, ref = nil)
        render_markup(path, code)
      end

      private
      def markuper
        return @markuper if @markuper
        highlighter = Makeup::SyntaxHighlighter.new
        @markuper = Makeup::Markup.new(:highlighter => highlighter)
      end
    end
  end
end
