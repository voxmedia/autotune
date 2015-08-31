module Autotune
  # Adds simple search functionality to models
  module Searchable
    extend ActiveSupport::Concern

    # New class methods
    module ClassMethods
      # Do a rudementary keyword search across fields specified by
      # the `search_fields` directive
      #
      # @param text [String] string of keywords
      # @return [ActiveRecord::Relation] matching model instances
      def search(text, model_sym)
        return nil if text.nil? || text.empty?
        return nil unless defined? @@search_fields && @@search_fields.any?
        words = text.to_s.strip.split.uniq
        words.reduce(self) do |combined_scope, word|
          search_fields(model_sym)
          query_tmpl = @@search_fields.map { |item| "#{item} LIKE ?" }
          combined_scope.where(
            [query_tmpl.join(' OR ')] +
            ["%#{word}%"] * @@search_fields.length)
        end
      end

      # Set the fields to search across when `search` is used
      #
      # @param [Symbol] field names
      def search_fields(*args)
        @@search_fields = args.map { |a| a.to_sym }
      end
    end
  end
end
