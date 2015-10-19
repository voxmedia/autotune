require 'logger'
require 'stringio'

module Autotune
  class Log < ActiveRecord::Base
    belongs_to :blueprint
    belongs_to :project

    default_scope { order('created_at DESC') }
    validates :content, :created_at, :blueprint, :time, :name, :success,
              :presence => true

    attr_reader :logger

    after_initialize :if => :new_record? do
      @created_at = Time.zone.now
      @buffer = StringIO.new
      @logger = Logger.new(@buffer)
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        "#{duration(datetime)}ms\t#{severity}\t#{msg}\n"
      end
      @logger
    end

    before_validation :if => :new_record? do
      self.time = duration
      self.content = @buffer.string
    end

    after_save do
      @logger.close
      @buffer.close
      @logger = nil
      @buffer = nil
    end

    private

    def duration(til = Time.zone.now)
      ((til - @created_at) * 1000).to_i
    end
  end
end
