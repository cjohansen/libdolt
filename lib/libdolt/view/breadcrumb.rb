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
    module Breadcrumb
      def breadcrumb(repository, ref, path)
        dirs = path.split("/")
        filename = dirs.pop
        dir_html = accumulate_dirs(dirs, repository, ref)
        url = tree_url(repository, ref)
        <<-HTML
          <ul class="breadcrumb">
            <li><a href="#{url}"><i class="icon icon-file"></i> /</a></li>
            #{dir_html}<li class="active">#{filename}</li>
          </ul>
        HTML
      end

      private
      def accumulate_dirs(dirs, repository, ref)
        accumulated = []
        divider = "<span class=\"divider\">/</span>"
        dir_html = dirs.inject("") do |html, dir|
          accumulated << dir
          url = tree_url(repository, ref, accumulated.join('/'))
          "#{html}<li><a href=\"#{url}\">#{dir}#{divider}</a></li>"
        end
      end
    end
  end
end
