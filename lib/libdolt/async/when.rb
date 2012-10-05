require "eventmachine"

module When
  class Promise
    def initialize(deferred = EM::DefaultDeferrable.new)
      @deferred = deferred
    end

    def callback(&block)
      @deferred.callback(&block)
      self
    end

    def errback(&block)
      @deferred.errback(&block)
      self
    end
  end

  class Resolver
    def initialize(deferred = EM::DefaultDeferrable.new)
      @deferred = deferred
      @resolved = false
    end

    def resolve(*args)
      mark_resolved
      @deferred.succeed(*args)
    end

    def reject(*args)
      mark_resolved
      @deferred.fail(*args)
    end

    def resolved?
      @resolved
    end

    private
    def mark_resolved
      raise StandardError.new("Already resolved") if @resolved
      @resolved = true
    end
  end

  class Deferred
    attr_reader :resolver, :promise

    def initialize
      deferred = EM::DefaultDeferrable.new
      @resolver = Resolver.new(deferred)
      @promise = Promise.new(deferred)
    end

    def resolve(*args)
      @resolver.resolve(*args)
    end

    def reject(*args)
      @resolver.reject(*args)
    end

    def callback(&block)
      @promise.callback(&block)
    end

    def errback(&block)
      @promise.errback(&block)
    end

    def resolved?
      @resolver.resolved?
    end

    def self.resolved(value)
      d = self.new
      d.resolve(value)
      d
    end

    def self.rejected(value)
      d = self.new
      d.reject(value)
      d
    end
  end

  def self.deferred(val)
    return val if val.respond_to?(:callback) && val.respond_to?(:errback)
    Deferred.resolved(val).promise
  end

  def self.all(promises)
    raise(ArgumentError, "expected enumerable promises") if !promises.is_a?(Enumerable)
    resolved = 0
    results = []
    d = Deferred.new

    attempt_resolution = lambda do |err, res|
      break if d.resolved?
      if err.nil?
        d.resolve(res) if promises.length == resolved
      else
        d.reject(err)
      end
    end

    wait_for_all(promises) do |err, result, index|
      resolved += 1
      results[index] = result
      attempt_resolution.call(err, results)
    end

    attempt_resolution.call(nil, results) if promises.length == 0
    d.promise
  end

  private
  def self.wait_for_all(promises, &block)
    promises.each_with_index do |p, i|
      p.callback do |result|
        block.call(nil, result, i)
      end
      p.errback { |e| block.call(e, nil, i) }
    end
  end
end
