# Omniauth authorization data
class Authorization < ActiveRecord::Base
  belongs_to :user
  serialize :info, Hash
  serialize :credentials, Hash
  serialize :extra, Hash

  validates :user, :provider, :uid, :presence => true
  validates :provider, :uniqueness => { :scope => :user_id }

  def provider_name
    provider.split('_').first.to_s.titleize
  end
end
