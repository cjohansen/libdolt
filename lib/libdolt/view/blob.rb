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
require "htmlentities"

module Dolt
  module View
    module Blob
      def binary?(content)
        !content[0...(content.length-1)].index("\000").nil?
      end

      def entityfy(content)
        @coder ||= HTMLEntities.new
        @coder.encode(content)
      end

      def format_blob(path, content, repo = nil, ref = nil)
        return format_binary_blob(path, content, repo, ref) if binary?(content)
        format_text_blob(path, content, repo, ref)
      end

      def format_binary_blob(path, content, repository = nil, ref = nil)
        link_binary_blob(path, content, repository, ref)
      end

      def link_binary_blob(path, content, repository = nil, ref = nil)
        <<-HTML
<p class="prettyprint">
The content you're attempting to browse appears to be binary.
<a href="#{raw_url(repository, ref, path)}">Download #{File.basename(path)}</a>.
</p>
        HTML
      end

      def format_text_blob(path, content, repository = nil, ref = nil)
        multiline(entityfy(content))
      end

      def format_whitespace(text)
        text
      end

      def multiline(blob, options = {})
        class_names = options[:class_names] || []
        class_names << "prettyprint" << "linenums"

        num = 0
        lines = blob.split("\n").inject("") do |html, line|
          num += 1
          # Empty elements causes annoying rendering artefacts
          # Forcing one space on each line affects copy-paste negatively
          # TODO: Don't force one space, find CSS fix
          line = format_whitespace(line).sub(/^$/, " ")
          "#{html}<li class=\"L#{num}\"><span class=\"line\">#{line}</span></li>"
        end

        "<pre class=\"#{class_names.join(' ')}\">" +
          "<ol class=\"linenums gts-lines\">#{lines}</ol></pre>"
      end
    end
  end
end
