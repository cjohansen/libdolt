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
require "github/markup"

module Dolt
  module View
    module Markup
      def render_markup(path, content)
        content = highlight_code_blocks(path, content)
        markup = GitHub::Markup.render(path, content)
        "<div class=\"gts-markup\">#{markup}</div>"
      end

      def supported_markup_format?(path)
        GitHub::Markup.can_render?(path)
      end

      def format_text_blob(path, code, repo = nil, ref = nil)
        render_markup(path, code)
      end

      def highlight_code_blocks(path, markup)
        return markup unless path =~ /\.(md|mkdn?|mdwn|mdown|markdown)$/
        can_highlight = respond_to?(:highlight)
        CodeBlockParser.parse(markup) do |lexer, code|
          code = can_highlight ? highlight(path, code, { :lexer => lexer }) : code
          l = can_highlight ? Pygments::Lexer.find(lexer) : nil
          "<pre class=\"#{l && l.aliases.first} prettyprint\">#{code}</pre>"
        end
      end
    end

    class CodeBlockParser
      attr_reader :lines

      def self.parse(markup, &block)
        new(markup).parse(&block)
      end

      def initialize(markup)
        @lines = markup.split("\n")
        @current_code_bock = nil
      end

      def parse(&block)
        result = []

        while line = @lines.shift
          if closes_code_block?(line)
            result << block.call(*close_active_code_block)
          elsif active_code_block?
            append_active_code_block(line)
          elsif starts_code_block?(line)
            start_code_block(line)
          else
            result << line
          end
        end

        result.join("\n")
      end

      def active_code_block?
        !@current_code_bock.nil?
      end

      def starts_code_block?(line)
        line.match(/^```.*/)
      end

      def closes_code_block?(line)
        active_code_block? && line == "```"
      end

      def start_code_block(line)
        m = line.match(/```([^\s]+)/)
        @current_code_bock = [m && m[1], []]
      end

      def append_active_code_block(line)
        @current_code_bock[1] << line
      end

      def close_active_code_block
        lexer = @current_code_bock[0]
        code = @current_code_bock[1].join("\n")
        @current_code_bock = nil
        [lexer, code]
      end
    end
  end
end
