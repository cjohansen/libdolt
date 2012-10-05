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
  module Git
    class Tree
      attr_reader :oid, :entries
      include Enumerable

      def initialize(oid, entries)
        @oid = oid
        @entries = entries
      end

      def each(&block)
        entries.each(&block)
      end

      # From Rugged::Tree
      def inspect
        data = "#<Dolt::Git::Tree:#{object_id} {oid: #{oid}}>\n"
        self.each { |e| data << "  <\"#{e[:name]}\" #{e[:oid]}>\n" }
        data
      end
    end
  end
end
