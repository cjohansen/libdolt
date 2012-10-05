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
require "mime/types"

module Dolt
  module View
    module BinaryBlobEmbedder
      def image?(path, content)
        MIME::Types.type_for(path).any? { |mt| mt.media_type == "image" }
      end

      def format_binary_blob(path, content, repository, ref)
        if !image?(path, content)
          return link_binary_blob(path, content, repository, ref)
        end

        url = raw_url(repository, ref, path)
        <<-HTML
<p class="prettyprint">
  <a href="#{url}"><img src="#{url}" alt="#{path}"></a>
</p>
        HTML
      end
    end
  end
end
