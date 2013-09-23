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
require "libdolt/view/syntax_highlight"
require "libdolt/view/markup"

module Dolt
  module View
    module SmartBlobRenderer
      include Dolt::View::Markup
      include Dolt::View::SyntaxHighlight

      def format_text_blob(path, content, repo = nil, ref = nil, options = {})
        begin
          return render_markup(path, content) if supported_markup_format?(path)
        rescue StandardError => err
          $stderr.puts("Failed rendering markup in #{path}, render syntax highlighted insted")
          $stderr.puts("Original error was: #{err}")
          $stderr.puts(err.backtrace)
        end

        highlight_multiline(path, content, options)
      end
    end
  end
end
