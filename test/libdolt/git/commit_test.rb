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
require "libdolt/git/commit"

describe Dolt::Git::Commit do
  include EM::MiniTest::Spec

  describe "parse" do
    before do
      @log = <<-GIT
commit dc0846b6c98a3f6db1172629329b70ada80598bb
Author: Christian Johansen <christian@gitorious.com>
Date:   Thu Sep 20 15:55:52 2012 +0200

    Add rough blame

commit 222eef3679553c9da2897144e03a5844f6e77586
Author: Christian Johansen <christian@gitorious.com>
Date:   Wed Sep 19 12:27:54 2012 +0200

    Rewrite template/views. Use EMRugged for Git.

      - Not complete, still some failing tests
      - View helpers need to change

commit 06293404488d9cc72e70eb2ae25aa609af73dada
Author: Christian Johansen <christian@gitorious.com>
Date:   Tue Sep 11 20:03:14 2012 +0200

    Rename FileSystemRepositoryResolver to DiskRepoResolver

commit 7a3d69a2327bb9575bb520fe30c6abb3bbd0b719
Author: Christian Johansen <christian@gitorious.com>
Date:   Tue Sep 11 19:57:22 2012 +0200

    One more rename: "Dolt" is shorter, better

commit eabcd577e921d01aeaf777d2daac565f88ab174c
Author: Christian Johansen <christian@gitorious.com>
Date:   Tue Sep 11 15:25:50 2012 +0200

    Moron was taken, going with Addlepate

      GIT

      @commits = Dolt::Git::Commit.parse_log(@log)
    end

    it "has commits" do
      assert_equal 5, @commits.length
    end

    it "has commit oids" do
      assert_equal "dc0846b6c98a3f6db1172629329b70ada80598bb", @commits[0][:oid]
      assert_equal "222eef3679553c9da2897144e03a5844f6e77586", @commits[1][:oid]
      assert_equal "06293404488d9cc72e70eb2ae25aa609af73dada", @commits[2][:oid]
      assert_equal "7a3d69a2327bb9575bb520fe30c6abb3bbd0b719", @commits[3][:oid]
      assert_equal "eabcd577e921d01aeaf777d2daac565f88ab174c", @commits[4][:oid]
    end

    it "has author" do
      expected = {
        :name => "Christian Johansen",
        :email => "christian@gitorious.com"
      }
      assert_equal expected, @commits.first[:author]
    end

    it "has commit date" do
      assert_equal "2012-09-11", @commits.last[:date].strftime("%Y-%m-%d")
    end
  end
end
