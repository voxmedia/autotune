require_dependency 'autotune/application_controller'

module Autotune
  # Handle receiving, processing and returning notification messages
  class MessagesController < ApplicationController
    def index
      if params[:since].to_f.to_s == params[:since]
        # float timestamp
        dt = Time.at(params[:since].to_f)
      elsif params[:since].to_i.to_s == params[:since]
        # integer timestamp
        dt = Time.at(params[:since].to_i)
      elsif params[:since].blank?
        # missing required parameter
        return render_error "Parameter 'since' is required", :bad_request
      else
        # Some other datetime value
        dt = DateTime.parse(params[:since])
      end

      add_date_header
      if params[:type]
        render :json => Autotune.messages(:since => dt, :type => params[:type])
      else
        render :json => Autotune.messages(:since => dt)
      end
    end

    def send_message
      Autotune.send_message(params[:type], params[:message])
      render_accepted
    end
  end
end
