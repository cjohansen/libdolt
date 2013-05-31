# encoding: utf-8
#--
#   Copyright (C) 2013 Gitorious AS
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
require "fileutils"
describe Dolt::DiskRepoResolver do
  before do
    @root = FileUtils.mkdir_p("/tmp/libdolt-tests/")
    FileUtils.mkdir_p(File.join(@root, "single/.git"))
    @resolver = Dolt::DiskRepoResolver.new(@root)
  end

  after do
    FileUtils.rm_f("/tmp/libdolt-tests")
  end

  it "resolves non-bare repositories" do
    assert @resolver.git_repo?("single")
  end

  it "resolves bare repositories" do
    assert @resolver.git_repo?("multi.git")
  end

  it "fails too" do
    refute @resolver.git_repo?("nope")
  end
end
