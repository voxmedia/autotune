require 'logger'
require 'stringio'

module Autotune
  class Log < ActiveRecord::Base
    belongs_to :blueprint
    belongs_to :project

    default_scope { order('created_at DESC') }
    validates :content, :created_at, :blueprint, :time, :label, :success,
              :presence => true

    delegate :error, :warning, :debug, :fatal, :info, :unknown,
             :to => :logger

    after_initialize :if => :new_record? do
      self.created_at = Time.zone.now
      @buffer = StringIO.new
      @logger = Logger.new(@buffer)
      @logger.formatter = proc do |severity, datetime, _progname, msg|
        "#{duration(datetime)}µs\t#{severity}\t#{msg}\n"
      end
      @logger
    end

    before_validation :if => :new_record? do
      self.blueprint = project.blueprint if project.present?
      self.time = duration
      self.content = @buffer.string
    end

    after_save do
      @logger.close if @logger
      @logger = nil
      @buffer = nil
    end

    def logger
      raise 'Log entries cannot be changed after creation' if persisted?
      @logger
    end

    private

    def duration(til = nil)
      til ||= Time.zone.now
      ((til.to_f - created_at.to_f) * (10**6)).to_i
    end
  end
end
