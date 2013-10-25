require "rake/testtask"
require "ci/reporter/rake/minitest"
begin
  require "bundler/gem_tasks"
rescue LoadError => e
  # The bundler package in RHEL 6's ruby193 SCL will break when attempting to
  # load vendored thor. Tested on ruby193-rubygem-bundler-1.1.4-3.el6.noarch.
  if e.message != 'cannot load such file -- thor'
    raise
  end
end


Rake::TestTask.new("test") do |test|
  test.libs << "test"
  test.pattern = "test/**/*_test.rb"
  test.verbose = true
end

if RUBY_VERSION < "1.9"
  require "rcov/rcovtask"
  Rcov::RcovTask.new do |t|
    t.libs << "test"
    t.test_files = FileList["test/**/*_test.rb"]
    t.rcov_opts += %w{--exclude gems,ruby/1.}
  end
end

task :default => :test
