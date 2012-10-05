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
require "test_helper"
require "libdolt/git/blame"

describe Dolt::Git::Blame do
  include EM::MiniTest::Spec

  describe "parse" do
    before do
      @blame = <<-GIT
906d67b4f3e5de7364ba9b57d174d8998d53ced6 1 1 17
author Christian Johansen
author-mail <christian@cjohansen.no>
author-time 1347282459
author-tz +0200
committer Christian Johansen
committer-mail <christian@cjohansen.no>
committer-time 1347282459
committer-tz +0200
summary Working Moron server for viewing blobs
filename lib/moron/view.rb
 # encoding: utf-8
906d67b4f3e5de7364ba9b57d174d8998d53ced6 2 2
 #--
906d67b4f3e5de7364ba9b57d174d8998d53ced6 3 3
 #   Copyright (C) 2012 Gitorious AS
906d67b4f3e5de7364ba9b57d174d8998d53ced6 4 4
 #
906d67b4f3e5de7364ba9b57d174d8998d53ced6 5 5
 #   This program is free software: you can redistribute it and/or modify
906d67b4f3e5de7364ba9b57d174d8998d53ced6 6 6
 #   it under the terms of the GNU Affero General Public License as published by
906d67b4f3e5de7364ba9b57d174d8998d53ced6 7 7
 #   the Free Software Foundation, either version 3 of the License, or
906d67b4f3e5de7364ba9b57d174d8998d53ced6 8 8
 #   (at your option) any later version.
906d67b4f3e5de7364ba9b57d174d8998d53ced6 9 9
 #
906d67b4f3e5de7364ba9b57d174d8998d53ced6 10 10
 #   This program is distributed in the hope that it will be useful,
906d67b4f3e5de7364ba9b57d174d8998d53ced6 11 11
 #   but WITHOUT ANY WARRANTY; without even the implied warranty of
906d67b4f3e5de7364ba9b57d174d8998d53ced6 12 12
 #   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
906d67b4f3e5de7364ba9b57d174d8998d53ced6 13 13
 #   GNU Affero General Public License for more details.
906d67b4f3e5de7364ba9b57d174d8998d53ced6 14 14
 #
906d67b4f3e5de7364ba9b57d174d8998d53ced6 15 15
 #   You should have received a copy of the GNU Affero General Public License
906d67b4f3e5de7364ba9b57d174d8998d53ced6 16 16
 #   along with this program.  If not, see <http://www.gnu.org/licenses/>.
906d67b4f3e5de7364ba9b57d174d8998d53ced6 17 17
 #++
906d67b4f3e5de7364ba9b57d174d8998d53ced6 20 18 1

beb65bee5619c651532179b19421363ead2c2a44 19 19 1
author Christian Johansen
author-mail <christian@gitorious.com>
author-time 1348128947
author-tz +0200
committer Christian Johansen
committer-mail <christian@gitorious.com>
committer-time 1348128947
committer-tz +0200
summary Helpers are modules again
previous 05f0137175fe341545587a544315cd4a6cc2c824 lib/dolt/view.rb
filename lib/dolt/view.rb
 dir = File.join(File.dirname(__FILE__), "view")
906d67b4f3e5de7364ba9b57d174d8998d53ced6 30 20 1

beb65bee5619c651532179b19421363ead2c2a44 21 21 2
 Dir.entries(dir).select { |f| f =~ /\.rb$/ }.map do |file|
beb65bee5619c651532179b19421363ead2c2a44 22 22
   require(File.join(dir, file))
906d67b4f3e5de7364ba9b57d174d8998d53ced6 58 23 1
 end
      GIT

      @blame = Dolt::Git::Blame.parse_porcelain(@blame)
    end

    it "has chunks" do
      assert_equal 5, @blame.chunks.length
    end

    it "has chunk with commit meta data" do
      chunk = @blame.chunks.first
      author = chunk[:author]
      committer = chunk[:committer]

      assert_equal "906d67b4f3e5de7364ba9b57d174d8998d53ced6", chunk[:oid]
      assert_equal "Christian Johansen", author[:name]
      assert_equal "christian@cjohansen.no", author[:mail]
      assert_equal "2012-09-10 17:07:39", author[:time].strftime("%Y-%m-%d %H:%M:%S")
      assert_equal "Christian Johansen", committer[:name]
      assert_equal "christian@cjohansen.no", committer[:mail]
      assert_equal "2012-09-10 17:07:39", committer[:time].strftime("%Y-%m-%d %H:%M:%S")
      assert_equal "Working Moron server for viewing blobs", chunk[:summary]
    end

    it "has chunk with lines" do
      chunk = @blame.chunks.first
      assert_equal 18, chunk[:lines].length
      assert_equal "#   Copyright (C) 2012 Gitorious AS", chunk[:lines][2]
    end

    it "repeats commit meta" do
      assert_equal @blame.chunks[2][:committer], @blame.chunks[0][:committer]
    end
  end
end
