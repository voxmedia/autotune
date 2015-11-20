require 'test_helper'

module Autotune
  # test taggy stuff
  class DeployerTest < ActiveSupport::TestCase
    fixtures 'autotune/projects'

    test 'init deployer' do
      p = autotune_projects(:example_one)
      d = Deployer.new(
        :base_url => '//example.com',
        :connect => 'foo://test',
        :project => p)

      assert_equal d.base_url, '//example.com'
      assert_equal d.connect, 'foo://test'
      assert_equal d.project, p
    end

    test 'urls' do
      p = autotune_projects(:example_one)
      d = Deployer.new(
        :base_url => '//example.com',
        :connect => 'foo://test',
        :project => p)

      assert_equal d.project_url, '//example.com/example-build-one'
      assert_equal d.project_asset_url, '//example.com/example-build-one'
      assert_equal d.deploy_path, '/example-build-one'
    end

    test 'url generation' do
      p = autotune_projects(:example_one)
      d = Deployer.new(
        :base_url => '//example.com',
        :connect => 'foo://test',
        :project => p)

      assert_equal d.url_for(''),
                   '//example.com/example-build-one'
      assert_equal d.url_for(nil),
                   '//example.com/example-build-one'
      assert_equal d.url_for('/'),
                   '//example.com/example-build-one'
      assert_equal d.url_for('/foo'),
                   '//example.com/example-build-one/foo'
      assert_equal d.url_for('foo'),
                   '//example.com/example-build-one/foo'
      assert_equal d.url_for('/images/bar.jpg'),
                   '//example.com/example-build-one/images/bar.jpg'
      assert_equal d.url_for('images/bar.jpg'),
                   '//example.com/example-build-one/images/bar.jpg'
      assert_equal d.url_for('/images/foo.png'),
                   '//example.com/example-build-one/images/foo.png'
      assert_equal d.url_for('images/foo.png'),
                   '//example.com/example-build-one/images/foo.png'
    end

    test 'hooks' do
      p = autotune_projects(:example_one)
      d = Deployer.new(
        :base_url => '//example.com',
        :connect => 'foo://test',
        :project => p)

      build = {}
      env = {}
      d.before_build(build, env)

      assert build['base_url'], '//example.com/example-build-one'
      assert build['asset_base_url'], '//example.com/example-build-one'

      assert_raises(NotImplementedError) { d.deploy('/tmp/foo') }
      assert_raises(NotImplementedError) { d.deploy_file('/tmp/foo', 'bar.jpg') }
      assert_raises(NotImplementedError) { d.after_delete }
      assert_raises(NotImplementedError) { d.after_move }
    end

    test 'files' do
      skip
      in_tmpdir do |path|
        p = autotune_projects(:example_one)
        d = Deployers::File.new(
          :base_url => '//example.com',
          :connect => "file://#{path}",
          :project => p)
      end
    end

    test 's3' do
      skip
    end

    def in_tmpdir
      path = File.expand_path "#{Dir.tmpdir}/#{Time.now.to_i}#{rand(1000)}/"
      yield path
    ensure
      FileUtils.rm_rf(path) if File.exist?(path)
    end
  end
end
