# encoding: utf-8 -- Copyright (C) 2012 Gitorious AS
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
require "makeup/syntax_highlighter"

module Dolt
  module View
    module SyntaxHighlight
      def highlighter
        @highlighter ||= Makeup::SyntaxHighlighter.new
      end

      def highlight(path, code, options = {})
        highlighter.highlight(path, code, options).code
      end

      def highlight_multiline(path, code, options = {})
        return highlight(path, code, options) unless respond_to?(:multiline)
        res = highlighter.highlight(path, code, options)
        multiline(res.code, :class_names => [res.lexer])
      end

      def format_text_blob(path, code, repo = nil, ref = nil, options = {})
        highlight_multiline(path, code, options)
      end
    end
  end
end
