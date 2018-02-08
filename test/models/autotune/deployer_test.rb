require 'test_helper'
require 'autoshell'

module Autotune
  # test taggy stuff
  class DeployerTest < ActiveSupport::TestCase
    fixtures 'autotune/projects', 'autotune/blueprints'

    test 'init deployer' do
      p = autotune_projects(:example_one)
      d = Deployer.new(
        :base_url => '//example.com',
        :connect => 'foo://test',
        :project => p)

      assert_equal '//example.com', d.base_url
      assert_equal 'foo://test', d.connect
      assert_equal p, d.project
    end

    test 'urls' do
      p = autotune_projects(:example_one)
      d = Deployer.new(
        :base_url => '//example.com',
        :connect => 'foo://test',
        :project => p)

      assert_equal '//example.com/example-build-one', d.project_url
      assert_equal '//example.com/example-build-one', d.project_asset_url
      assert_equal '/example-build-one', d.deploy_path
      assert_equal '/example-build-one', d.asset_deploy_path

      d = Deployer.new(
        :base_url => '//example.com/one',
        :connect => 'foo://test/one',
        :project => p)

      assert_equal '//example.com/one/example-build-one', d.project_url
      assert_equal '//example.com/one/example-build-one', d.project_asset_url
      assert_equal '/one/example-build-one', d.deploy_path
      assert_equal '/one/example-build-one', d.asset_deploy_path
    end

    test 'url generation' do
      p = autotune_projects(:example_one)
      d = Deployer.new(
        :base_url => '//example.com',
        :connect => 'foo://test',
        :project => p)

      assert_equal '//example.com/example-build-one',
                   d.url_for('')
      assert_equal '//example.com/example-build-one',
                   d.url_for(nil)
      assert_equal '//example.com/example-build-one',
                   d.url_for('/')
      assert_equal '//example.com/example-build-one/foo',
                   d.url_for('/foo')
      assert_equal '//example.com/example-build-one/foo',
                   d.url_for('foo')
      assert_equal '//example.com/example-build-one/index.html',
                   d.url_for('/index.html')
      assert_equal '//example.com/example-build-one/index.html',
                   d.url_for('index.html')
      assert_equal '//example.com/example-build-one/images/bar.jpg',
                   d.url_for('/images/bar.jpg')
      assert_equal '//example.com/example-build-one/images/bar.jpg',
                   d.url_for('images/bar.jpg')
      assert_equal '//example.com/example-build-one/images/foo.png',
                   d.url_for('/images/foo.png')
      assert_equal '//example.com/example-build-one/images/foo.png',
                   d.url_for('images/foo.png')
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
    end

    test 'file deployer' do
      in_tmpdir do |path|
        p = autotune_projects(:example_one)
        d = Deployers::File.new(
          :base_url => '//example.com',
          :connect => "file://#{path}",
          :project => p)

        wd = Autoshell.new(p.working_dir)
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

        d.delete!

        refute File.exist?(File.join(path, p.slug, 'index.html')),
               'File should not exist'
        refute File.exist?(File.join(path, p.slug, 'app.css')),
               'File should not exist'
        refute File.exist?(File.join(path, p.slug, 'thumb.svg')),
               'File should not exist'
      end
    end

    test 's3 url generation' do
      p = autotune_projects(:example_one)
      d = Deployers::S3.new(
        :base_url => '//example.com',
        :connect => 's3://test',
        :project => p)

      assert_equal '//example.com/example-build-one/',
                   d.url_for('')
      assert_equal '//example.com/example-build-one/',
                   d.url_for(nil)
      assert_equal '//example.com/example-build-one/',
                   d.url_for('/')
      assert_equal '//example.com/example-build-one/foo/',
                   d.url_for('/foo')
      assert_equal '//example.com/example-build-one/foo/',
                   d.url_for('foo')
      assert_equal '//example.com/example-build-one/index.html',
                   d.url_for('index.html')
      assert_equal '//example.com/example-build-one/index.html',
                   d.url_for('/index.html')
      assert_equal '//example.com/example-build-one/images/bar.jpg',
                   d.url_for('/images/bar.jpg')
      assert_equal '//example.com/example-build-one/images/bar.jpg',
                   d.url_for('images/bar.jpg')
      assert_equal '//example.com/example-build-one/images/foo.png',
                   d.url_for('/images/foo.png')
      assert_equal '//example.com/example-build-one/images/foo.png',
                   d.url_for('images/foo.png')
    end

    test 's3' do
      skip unless ENV['TEST_BUCKET'] &&
                  ENV['AWS_ACCESS_KEY_ID'] &&
                  ENV['AWS_SECRET_ACCESS_KEY']

      p = autotune_projects(:example_one)
      d = Deployers::S3.new(
        :base_url => "//s3.amazonaws.com/#{ENV['TEST_BUCKET']}/at-temp",
        :connect => "s3://#{ENV['TEST_BUCKET']}/at-temp",
        :project => p)

      wd = Autoshell.new(p.working_dir)
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
      sleep 5

      url = URI.parse('http:' + d.url_for('index.html'))
      req = Net::HTTP.new(url.host, url.port)
      res = req.request_head(url.path)
      assert_equal 200, res.code.to_i, "#{res.code} #{url}"

      url = URI.parse('http:' + d.url_for('app.css'))
      res = req.request_head(url.path)
      assert_equal 200, res.code.to_i, "#{res.code} #{url}"

      open(wd.expand('thumb.svg'), 'w') do |fp|
        fp.write('<svg><circle /></svg>')
      end
      assert File.exist?(wd.expand 'thumb.svg'), 'File should exist'

      d.deploy_file(p.working_dir, 'thumb.svg')
      sleep 5

      url = URI.parse('http:' + d.url_for('thumb.svg'))
      res = req.request_head(url.path)
      assert_equal 200, res.code.to_i, "#{res.code} #{url}"

      d.delete!
      sleep 5

      url = URI.parse('http:' + d.url_for('index.html'))
      res = req.request_head(url.path)
      assert_equal 403, res.code.to_i, "#{res.code} #{url}"
      url = URI.parse('http:' + d.url_for('app.css'))
      res = req.request_head(url.path)
      assert_equal 403, res.code.to_i, "#{res.code} #{url}"
      url = URI.parse('http:' + d.url_for('thumb.svg'))
      res = req.request_head(url.path)
      assert_equal 403, res.code.to_i, "#{res.code} #{url}"
    end

    def in_tmpdir
      path = File.expand_path "#{Dir.tmpdir}/#{Time.now.to_i}#{rand(1000)}/"
      yield path
    ensure
      FileUtils.rm_rf(path) if File.exist?(path)
    end
  end
end
