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
require "mocha/setup"
require "libdolt/git/archiver"

class StubRepository
  attr_reader :id, :full_repository_path, :path_segment
  def initialize(path_segment)
    @@counter ||= 0
    @id = (@@counter += 1)
    @full_repository_path = "/repos/#{path_segment}.git"
    @path_segment = path_segment
  end
end

describe Dolt::Git::Archiver do
  describe "archive" do
    before do
      @archiver = Dolt::Git::Archiver.new("/work", "/cache")
    end

    it "returns existing cached file" do
      File.stubs(:exists?).with("/cache/gts-mainline-master.tar.gz").returns(true)
      repo = StubRepository.new("gts/mainline")

      filename = @archiver.archive(repo, "master", :tar)
      assert_equal "/cache/gts-mainline-master.tar.gz", filename
    end

    it "generates tarball" do
      repo = StubRepository.new("gts/mainline")

      cmd = "sh -c 'git --git-dir /repos/gts/mainline.git archive --prefix='gts-mainline/' " +
        "--format=tar master | gzip -m > /work/gts-mainline-master.tar.gz'"
      Dolt::Git.expects(:shell).with(cmd).returns(Dolt::FakeProcess.new(0))
      FileUtils.stubs(:mv)

      @archiver.archive(repo, "master", :tar)
    end

    it "does not allow arbitrary commands" do
      repo = StubRepository.new("gts/mainline")

      cmd = "sh -c 'git --git-dir /repos/gts/mainline.git archive --prefix='gts-mainline/' " +
        "--format=tar master\\;\\ rm\\ -fr\\ / | gzip -m > /work/gts-mainline-master\\;\\ rm\\ -fr\\ -.tar.gz'"
      Dolt::Git.expects(:shell).with(cmd).returns(Dolt::FakeProcess.new(0))
      FileUtils.stubs(:mv)

      @archiver.archive(repo, "master; rm -fr /", :tar)
    end

    it "uses gzip format from string" do
      repo = StubRepository.new("gts/mainline")

      cmd = "sh -c 'git --git-dir /repos/gts/mainline.git archive --prefix='gts-mainline/' " +
        "--format=tar master | gzip -m > /work/gts-mainline-master.tar.gz'"
      Dolt::Git.expects(:shell).with(cmd).returns(Dolt::FakeProcess.new(0))
      FileUtils.stubs(:mv)

      @archiver.archive(repo, "master", "tar")
    end

    it "uses zip format from string" do
      repo = StubRepository.new("gts/mainline")

      cmd = "sh -c 'git --git-dir /repos/gts/mainline.git archive --prefix='gts-mainline/' " +
        "--format=zip master > /work/gts-mainline-master.zip'"
      Dolt::Git.expects(:shell).with(cmd).returns(Dolt::FakeProcess.new(0))
      FileUtils.stubs(:mv)

      @archiver.archive(repo, "master", "zip")
    end

    it "moves tarball when successfully generated" do
      FileUtils.expects(:mv).with("/work/gts-mainline-master.tar.gz",
                                  "/cache/gts-mainline-master.tar.gz")
      repo = StubRepository.new("gts/mainline")
      Dolt::Git.stubs(:open).returns(Dolt::FakeProcess.new(0))

      @archiver.archive(repo, "master", :tar)
    end

    it "does not move tarball when raising error" do
      FileUtils.expects(:mv).with("/work/gts-mainline-master.tar.gz",
                                  "/cache/gts-mainline-master.tar.gz").never
      repo = StubRepository.new("gts/mainline")
      Dolt::Git.expects(:shell).returns(Dolt::FakeProcess.new(1))

      assert_raises Exception do
        @archiver.archive(repo, "master", :tar)
      end
    end

    it "returns generated filename" do
      FileUtils.stubs(:mv)
      Dolt::Git.stubs(:open).returns(Dolt::FakeProcess.new(0))
      repo = StubRepository.new("gts/mainline")

      filename = @archiver.archive(repo, "master", :tar)
      assert_equal "/cache/gts-mainline-master.tar.gz", filename
    end
  end
end
