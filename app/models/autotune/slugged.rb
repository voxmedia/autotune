module Autotune
  # Handle stuff around having a slug on a model
  module Slugged
    extend ActiveSupport::Concern

    included do
      before_validation :ensure_unique_slug
      validates :slug,
                :presence => true,
                :uniqueness => true,
                :format => { :with => /\A[0-9a-z\-_]+\z/ }
    end

    def text_for_slug
      return title if respond_to? :title
      return name if respond_to? :name
      raise 'The Slugged concern requires a method called title, name or text_for_slug'
    end

    def ensure_unique_slug
      self.slug ||= self.class.unique_slug(text_for_slug.try(:parameterize))
    end

    module ClassMethods
      def unique_slug(slug)
        return if slug.blank?

        similar_slugs = where(['slug LIKE ?', "#{slug}%"]).pluck(:slug)
        return slug if similar_slugs.empty? || !similar_slugs.include?(slug)

        i = 0
        loop do
          new_slug = "#{slug}-#{i += 1}"
          break new_slug unless similar_slugs.include? new_slug
        end
      end
    end
  end
end
