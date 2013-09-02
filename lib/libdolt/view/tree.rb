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
    module Tree
      def object_path(root, object)
        return object if object[:type] == :submodule
        File.join(root, object[:name]).sub(/^\//, "")
      end

      def object_url(repository, ref, path, object)
        send(:"#{object[:type]}_url", repository, ref, object_path(path, object))
      end

      def tree_entries(tree)
        sort(tree.entries.select { |e| [:tree, :submodule].index(e[:type]) }) +
          sort(tree.entries.select { |e| e[:type] == :blob })
      end

      def tree_context(repo, ref, levels)
        return "" if levels.length == 1 && levels[0].length == 1
        total = 4 + levels.length
        colspan = total
        (levels.map do |level|
          html = <<-HTML
            <tr>
              #{'<td></td>' * (total - colspan)}
              <td colspan="#{colspan}">
                #{tree_context_level_links(repo, ref, level)}
              </td>
            </tr>
          HTML
          colspan -= 1
          html
        end).join
      end

      def tree_context_level_links(repo, ref, level)
        extra = "<i class=\"icon icon-folder-open\"></i>"

        (level.map do |path|
           dir = File.dirname(path)
           dir = "" if dir == "."
           file = path == "" ? "/" : File.basename(path)
           url = object_url(repo, ref, dir, { :type => :tree, :name => file })
           html = "<a href=\"#{url}\">#{extra} #{file}</a>"
           extra = extra == "" || extra == "/" ? "/" : ""
           html
        end).join(" ")
      end

      def partition_path(path, maxdepth = nil)
        path = path.sub(/^\.?\//, "")
        result = [[""]]
        return result if path == ""
        parts = path.split("/")
        maxdepth ||= parts.length
        fill_first = [parts.length, [1, parts.length - maxdepth + 1].max].min
        fill_first.times { result[0] << parts.shift }
        result << [parts.shift] while parts.length > 0
        result
      end

      def accumulate_path(pieces)
        acc = []
        pieces.map do |piece|
          piece.map do |p|
            next p if p == ""
            acc << p
            File.join(acc)
          end
        end
      end

      def tree_table_padding_width(partitioned)
        partitioned.length == 1 ? partitioned[0].length - 1 : partitioned.length
      end

      def tree_table_padding_td(partitioned)
        "<td></td>" * tree_table_padding_width(partitioned)
      end

      private
      def sort(entries)
        entries.sort_by { |e| e[:name] }
      end
    end
  end
end
