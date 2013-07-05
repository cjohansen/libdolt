require "rake/testtask"
require "ci/reporter/rake/minitest"
require "bundler/gem_tasks"

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
