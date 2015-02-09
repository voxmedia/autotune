module Slugged
  extend ActiveSupport::Concern

  included do
    before_validation :ensure_unique_slug
    validates :slug, :presence => true, :uniqueness => true, :format => { :with => /\A[0-9a-z\-]+\z/ }
  end

  private

  def ensure_unique_slug
    self.slug ||= text_for_slug.gsub('&nbsp;', ' ').parameterize
    return if similar_slugs.empty? || !similar_slugs.include?(self.slug)
    i = 0
    self.slug = loop do
      new_slug = "#{self.slug}-#{i += 1}"
      break new_slug unless similar_slugs.include? new_slug
    end
  end

  def similar_slugs
    @_similar_slugs ||= begin
      if id
        q = ["slug LIKE ? AND id != ?", "#{self.slug}%", id]
      else
        q = ["slug LIKE ?", "#{self.slug}%"]
      end
      self.class.where(q).map { |e| e.slug }
    end
  end

  def text_for_slug
    return title if respond_to? :title
    return name if respond_to? :name
    raise 'The Slugged concern requires a method called title, name or text_for_slug'
  end
end
