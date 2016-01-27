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
      def search(text)
        where(search_sql(text))
      end

      # Generate the sql for active record
      #
      # @param text [String] string of keywords
      # @return [Array] ActiveRecord where params
      def search_sql(text)
        return '' if text.nil? || text.empty? || search_fields.blank?
        words = text.to_s.strip.split.uniq

        query_list = words.map do |word|
          ["%#{word}%"] * search_fields.length
        end

        [search_field_sql(words.length)] + query_list.flatten
      end

      # Set the fields to search across when `search` is used
      #
      # @param [Symbol] field names
      def search_fields(*args)
        return @search_fields if args.length == 0
        @search_fields = args.map(&:to_sym)
      end

      private

      def search_field_sql(num_of_keywords = 1)
        sql = search_fields.map { |item| "#{item} LIKE ?" }.join(' OR ')
        '(' + ([sql] * num_of_keywords).join(') AND (') + ')'
      end
    end
  end
end
