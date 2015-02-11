class Authorization < ActiveRecord::Base
  belongs_to :user
  serialize :info, Hash
  serialize :credentials, Hash
  serialize :extra, Hash

  validates :user, :provider, :uid, :presence => true

  def provider_name
    provider.split("_").first.to_s.titleize
  end
end
