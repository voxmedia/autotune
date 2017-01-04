module Autotune
  # Template tags!
  module ApplicationHelper
    def config
      {
        :env => Rails.env,
        :designer_groups => current_user.nil? ? [] : current_user.designer_groups.as_json,
        :available_themes => current_user.nil? ? [] :
                current_user.author_themes.as_json(:only => [:slug, :title, :id], :methods => [:group_name, :twitter_handle]),
        :user => current_user.as_json,
        :blueprint_options => Blueprint.all.as_json(:only => [:title, :slug]) + [{:title => 'Bespoke', :slug => 'bespoke'}],
        :statuses => Autotune::STATUSES,
        :project_pub_statuses => Autotune::PROJECT_PUB_STATUSES,
        :blueprint_types => Autotune::BLUEPRINT_TYPES,
        :theme_statuses => Autotune::THEME_STATUSES,
        :editable_slug_types => Autotune::EDITABLE_SLUG_BLUEPRINT_TYPES,
        :spinner => ActionController::Base.helpers.asset_path('autotune/spinner.gif'),
        :faq_url => Autotune.configuration.faq_url,
        :theme_meta_data => Autotune.configuration.theme_meta_data,
        :date => Time.zone.now.strftime('%a, %e %b %Y %H:%M:%S %Z')
      }
    end
  end
end
