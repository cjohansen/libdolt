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

module Dolt
  module View
    module Blame
      def blame_annotations(blame)
        blame.chunks.inject([]) do |blames, chunk|
          blames << chunk
          (chunk[:lines].length - 1).times { blames << nil }
          blames
        end
      end

      def blame_lines(path, blame)
        lines = blame.chunks.inject([]) do |lines, chunk|
          lines.concat(chunk[:lines])
        end

        return lines unless respond_to?(:highlight)
        highlight(path, lines.join("\n")).split("\n")
      end

      def blame_annotation_cell(annotation)
        class_name = "gts-blame-annotation" + (annotation.nil? ? "" : " gts-annotated")
        return "<td class=\"#{class_name}\"></td>" if annotation.nil?

        <<-HTML
          <td class="#{class_name}">
            <span class="gts-commit-oid" data-gts-commit-oid="#{annotation[:oid]}">#{annotation[:oid][0..6]}</span>
            #{annotation[:committer][:time].strftime("%Y-%m-%d")}
            #{annotation[:committer][:name]}
          </td>
        HTML
      end

      def blame_code_cell(line)
        "<td class=\"gts-code\"><code>#{line}</code></td>"
      end
    end
  end
end
