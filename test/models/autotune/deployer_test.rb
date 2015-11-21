require 'test_helper'
require 'work_dir'

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
      assert_raises(NotImplementedError) { d.delete! }
      assert_raises(NotImplementedError) { d.move! }
    end

    test 'file deployer' do
      in_tmpdir do |path|
        p = autotune_projects(:example_one)
        d = Deployers::File.new(
          :base_url => '//example.com',
          :connect => "file://#{path}",
          :project => p)

        wd = WorkDir.repo(p.working_dir)
        FileUtils.mkdir_p(wd.expand 'build')
        open(wd.expand('build/index.html'), 'w') do |fp|
          fp.write('<h1>Hello World!</h1>')
        end
        open(wd.expand('build/app.css'), 'w') do |fp|
          fp.write('h1 { font-size: 100px }')
        end
        assert File.exist?(wd.expand 'build/index.html'), 'File should exist'
        assert File.exist?(wd.expand 'build/app.css'), 'File should exist'

        d.deploy(wd.expand 'build')

        assert File.exist?(File.join(path, p.slug, 'index.html')),
               'File should exist'
        assert File.exist?(File.join(path, p.slug, 'app.css')),
               'File should exist'

        open(wd.expand('thumb.svg'), 'w') do |fp|
          fp.write('<svg><circle /></svg>')
        end

        d.deploy_file(p.working_dir, 'thumb.svg')

        assert File.exist?(File.join(path, p.slug, 'thumb.svg')),
               'File should exist'

        p.slug = 'foo-bar'
        d.move!

        refute File.exist?(File.join(path, 'example-build-one', 'index.html')),
               'File should not exist'
        assert File.exist?(File.join(path, 'foo-bar', 'index.html')),
               'File should exist'

        d.delete!

        refute File.exist?(File.join(path, 'foo-bar', 'index.html')),
               'File should not exist'
      end
    end

    test 's3 url generation' do
      p = autotune_projects(:example_one)
      d = Deployers::S3.new(
        :base_url => '//example.com',
        :connect => 's3://test',
        :project => p)

      assert_equal d.url_for(''),
                   '//example.com/example-build-one/'
      assert_equal d.url_for(nil),
                   '//example.com/example-build-one/'
      assert_equal d.url_for('/'),
                   '//example.com/example-build-one/'
      assert_equal d.url_for('/foo'),
                   '//example.com/example-build-one/foo/'
      assert_equal d.url_for('foo'),
                   '//example.com/example-build-one/foo/'
      assert_equal d.url_for('/images/bar.jpg'),
                   '//example.com/example-build-one/images/bar.jpg'
      assert_equal d.url_for('images/bar.jpg'),
                   '//example.com/example-build-one/images/bar.jpg'
      assert_equal d.url_for('/images/foo.png'),
                   '//example.com/example-build-one/images/foo.png'
      assert_equal d.url_for('images/foo.png'),
                   '//example.com/example-build-one/images/foo.png'
    end

    def in_tmpdir
      path = File.expand_path "#{Dir.tmpdir}/#{Time.now.to_i}#{rand(1000)}/"
      yield path
    ensure
      FileUtils.rm_rf(path) if File.exist?(path)
    end
  end
end
