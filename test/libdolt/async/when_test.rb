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
require "libdolt/async/when"

describe When do
  include EM::MiniTest::Spec

  describe ".all" do
    it "returns deferrable" do
      d = When.all([When.deferred(42)])
      assert d.respond_to?(:callback)
      assert d.respond_to?(:errback)
    end

    it "resolves immediately if no promises" do
      d = When.all([])
      d.callback do |results|
        assert_equal [], results
        done!
      end
      wait!
    end

    it "resolves when single deferrable resolves" do
      deferred = When::Deferred.new
      d = When.all([deferred.promise])
      resolved = false
      d.callback { |results| resolved = true }

      assert !resolved
      deferred.resolve(42)
      assert resolved
    end

    it "resolves when all deferrables are resolved" do
      deferreds = [When::Deferred.new, When::Deferred.new, When::Deferred.new]
      d = When.all(deferreds.map(&:promise))
      resolved = false
      d.callback { |results| resolved = true }

      assert !resolved
      deferreds[0].resolve(42)
      assert !resolved
      deferreds[1].resolve(13)
      assert !resolved
      deferreds[2].resolve(3)
      assert resolved
    end

    it "rejects when single deferrable rejects" do
      deferred = When::Deferred.new
      d = When.all([deferred.promise])
      rejected = false
      d.errback { |results| rejected = true }

      assert !rejected
      deferred.reject(StandardError.new)
      assert rejected
    end

    it "rejects on first rejection" do
      deferreds = [When::Deferred.new, When::Deferred.new, When::Deferred.new]
      d = When.all(deferreds.map(&:promise))
      rejected = false
      d.errback { |results| rejected = true }

      deferreds[0].resolve(42)
      deferreds[2].reject(StandardError.new)
      deferreds[1].resolve(13)

      assert rejected
    end

    it "proxies resolution vaule in array" do
      deferred = When::Deferred.new
      d = When.all([deferred.promise])
      results = nil
      d.callback { |res| results = res }

      deferred.resolve(42)
      assert_equal [42], results
    end

    it "orders results like input" do
      deferred1 = When::Deferred.new
      deferred2 = When::Deferred.new
      d = When.all([deferred1.promise, deferred2.promise])
      results = nil
      d.callback { |res| results = res }

      deferred2.resolve(42)
      deferred1.resolve(13)
      assert_equal [13, 42], results
    end
  end
end
