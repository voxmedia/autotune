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
      self.slug =
        self.class.unique_slug(
          slug || text_for_slug.try(:parameterize), id)
    end

    class_methods do
      def unique_slug(slug, id = nil)
        return if slug.blank?

        # check to see if our slug already ends in a number
        if slug =~ /^(.*)-(\d{1,3})$/
          # if the slug ends in a number, they number may have been
          # added automatically. We need to discover if this is the
          # case and increment the number instead of adding a new
          # number suffix. Otherwise we end up with slugs that end
          # with `-1-1-1`.
          slug_part = Regexp.last_match[1]
          slug_num = Regexp.last_match[2].to_i

          # Grab all slugs that start like our slug. If our slug is
          # not in there, it's safe to use.
          slugs = similar_slugs(slug_part, id)
          return slug unless slugs.include?(slug)

          # Since we found our slug in the list of similar slugs,
          # we need to determine if the number is actually something
          # that was automatically added, or it it's actually part
          # of the slug.
          #
          # We'll do this by counting up from one and checking how
          # many other slugs we have that fall in the series.
          similar_count = (1..slug_num).reduce 0 do |m, i|
            "#{slug_part}-#{i}".in?(slugs) ? m + 1 : m
          end

          # If we have a large majority of the series from 1 to
          # the number we extracted from the slug, we'll assume
          # this number was automatically added.
          if similar_count.to_f / slug_num > 0.65
            slug = slug_part
          else
            slug_num = 0
          end
        else
          # Grab all slugs that start like our slug. If our slug is
          # not in there, it's safe to use.
          slugs = similar_slugs(slug, id)
          return slug unless slugs.include?(slug)

          # Start the slug num at 0
          slug_num = 0
        end

        # Loop continuously, incrementing slug_num until we
        # find an unused slug.
        loop do
          new_slug = "#{slug}-#{slug_num += 1}"
          break new_slug unless slugs.include? new_slug
        end
      end

      def similar_slugs(slug, id = nil)
        if id.nil?
          where(['slug LIKE ?', "#{slug}%"])
            .pluck(:slug)
        else
          where(['slug LIKE ? AND id != ?', "#{slug}%", id])
            .pluck(:slug)
        end
      end
    end
  end
end
