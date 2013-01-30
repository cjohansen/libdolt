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

class StubProcessStatus
  attr_reader :exitstatus
  def initialize(code)
    @exitstatus = code
  end
end

describe Dolt::Git::Archiver do
  include EM::MiniTest::Spec

  describe "archive" do
    before do
      @archiver = Dolt::Git::Archiver.new("/work", "/cache")
    end

    it "resolves with existing cached file" do
      File.stubs(:exists?).with("/cache/gts-mainline-master.tar.gz").returns(true)
      repo = StubRepository.new("gts/mainline")

      @archiver.archive(repo, "master", :tar).then do |filename|
        assert_equal "/cache/gts-mainline-master.tar.gz", filename
        done!
      end
      wait!
    end

    it "generates tarball" do
      repo = StubRepository.new("gts/mainline")

      cmd = "sh -c 'git --git-dir /repos/gts/mainline.git archive --prefix='gts-mainline/' " +
        "--format=tar master | gzip -m > /work/gts-mainline-master.tar.gz'"
      d = EM::DefaultDeferrable.new
      EMPessimistic::DeferrableChildProcess.expects(:open).with(cmd).returns(d)

      @archiver.archive(repo, "master", :tar)
    end

    it "does not allow arbitrary commands" do
      repo = StubRepository.new("gts/mainline")

      cmd = "sh -c 'git --git-dir /repos/gts/mainline.git archive --prefix='gts-mainline/' " +
        "--format=tar master\\;\\ rm\\ -fr\\ / | gzip -m > /work/gts-mainline-master\\;\\ rm\\ -fr\\ -.tar.gz'"
      d = EM::DefaultDeferrable.new
      EMPessimistic::DeferrableChildProcess.expects(:open).with(cmd).returns(d)

      @archiver.archive(repo, "master; rm -fr /", :tar)
    end

    it "uses gzip format from string" do
      repo = StubRepository.new("gts/mainline")

      cmd = "sh -c 'git --git-dir /repos/gts/mainline.git archive --prefix='gts-mainline/' " +
        "--format=tar master | gzip -m > /work/gts-mainline-master.tar.gz'"
      d = EM::DefaultDeferrable.new
      EMPessimistic::DeferrableChildProcess.expects(:open).with(cmd).returns(d)

      @archiver.archive(repo, "master", "tar")
    end

    it "uses zip format from string" do
      repo = StubRepository.new("gts/mainline")

      cmd = "sh -c 'git --git-dir /repos/gts/mainline.git archive --prefix='gts-mainline/' " +
        "--format=zip master > /work/gts-mainline-master.zip'"
      d = EM::DefaultDeferrable.new
      EMPessimistic::DeferrableChildProcess.expects(:open).with(cmd).returns(d)

      @archiver.archive(repo, "master", "zip")
    end

    it "moves tarball when successfully generated" do
      FileUtils.expects(:mv).with("/work/gts-mainline-master.tar.gz",
                                  "/cache/gts-mainline-master.tar.gz")
      repo = StubRepository.new("gts/mainline")
      d = EM::DefaultDeferrable.new
      EMPessimistic::DeferrableChildProcess.expects(:open).returns(d)
      d.succeed("", StubProcessStatus.new(0))

      @archiver.archive(repo, "master", :tar)
    end

    it "does not move tarball when raising error" do
      FileUtils.expects(:mv).with("/work/gts-mainline-master.tar.gz",
                                  "/cache/gts-mainline-master.tar.gz").never
      repo = StubRepository.new("gts/mainline")
      d = EM::DefaultDeferrable.new
      EMPessimistic::DeferrableChildProcess.expects(:open).returns(d)
      d.fail("", StubProcessStatus.new(1))

      @archiver.archive(repo, "master", :tar)
    end

    it "resolves promise with generated filename" do
      FileUtils.stubs(:mv)
      repo = StubRepository.new("gts/mainline")
      d = EM::DefaultDeferrable.new
      EMPessimistic::DeferrableChildProcess.expects(:open).returns(d)
      d.succeed("", StubProcessStatus.new(0))

      @archiver.archive(repo, "master", :tar).then do |filename|
        assert_equal "/cache/gts-mainline-master.tar.gz", filename
        done!
      end
      wait!
    end

    it "rejects promise when failing to archive" do
      repo = StubRepository.new("gts/mainline")
      d = EM::DefaultDeferrable.new
      EMPessimistic::DeferrableChildProcess.expects(:open).returns(d)
      d.fail("It done failed", StubProcessStatus.new(1))

      @archiver.archive(repo, "master", :tar).errback do |err|
        assert_match "It done failed", err.message
        done!
      end
      wait!
    end

    it "does not spawn multiple identical processes" do
      FileUtils.stubs(:mv)
      repo = StubRepository.new("gts/mainline")
      d = EM::DefaultDeferrable.new
      EMPessimistic::DeferrableChildProcess.expects(:open).once.returns(d)
      callbacks = 0
      blk = lambda do |filename|
        assert_equal "/cache/gts-mainline-master.tar.gz", filename
        callbacks += 1
        done! if callbacks == 2
      end

      @archiver.archive(repo, "master", :tar).then(&blk)
      @archiver.archive(repo, "master", :tar).then(&blk)

      wait!
      d.succeed("", StubProcessStatus.new(0))
    end

    it "spawns new process when format is different" do
      FileUtils.stubs(:mv)
      repo = StubRepository.new("gts/mainline")
      d = EM::DefaultDeferrable.new
      EMPessimistic::DeferrableChildProcess.expects(:open).twice.returns(d)
      callbacks = 0

      @archiver.archive(repo, "master", :tar).then do |filename|
        assert_equal "/cache/gts-mainline-master.tar.gz", filename
        callbacks += 1
        done! if callbacks == 2
      end

      @archiver.archive(repo, "master", :zip).then do |filename|
        assert_equal "/cache/gts-mainline-master.zip", filename
        callbacks += 1
        done! if callbacks == 2
      end

      wait!
      d.succeed("", StubProcessStatus.new(0))
    end
  end
end
