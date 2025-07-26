class AmazonProductsController < ApplicationController
  def new
  end

  def create
    url = params[:url]
    if url.present?
      scraper = AmazonProductScraper.new(url)
      @result = scraper.scrape
    else
      @result = { error: 'Please provide a valid Amazon product URL.' }
    end

    respond_to do |format|
      format.html { render :new }
      format.turbo_stream { render :new }
    end
  end
end 