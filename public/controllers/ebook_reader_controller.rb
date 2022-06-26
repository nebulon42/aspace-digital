require 'uri'

class EbookReaderController < ApplicationController
  def show
    render "reader/index"
  end

  def retrieve
    url = Base64.decode64(params[:url])
    data = open(url)
    headers['Access-Control-Allow-Origin'] = AppConfig[:public_url]
    send_data data.read, :type => data.content_type, :filename => URI(url).path.split('/').last
  end
end