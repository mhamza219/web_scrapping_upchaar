require 'httparty'
require 'nokogiri'

class AmazonProductScraper
  def initialize(url)
    @url = url
  end

  def scrape
    response = HTTParty.get(@url, headers: { 'User-Agent' => 'Mozilla/5.0' })
    doc = Nokogiri::HTML(response.body)

    name = doc.at_css('#productTitle')&.text&.strip

    # MRP (original price)
    mrp = doc.at_css('.a-text-price .a-offscreen')&.text&.strip

    # Actual price (price to pay)
    actual_price =
      doc.at_css('.a-price.aok-align-center.priceToPay .a-offscreen')&.text&.strip ||
      doc.at_css('.aok-offscreen')&.text&.strip

    # Discount (percentage)
    discount = doc.at_css('.savingsPercentage')&.text&.strip
    if discount.blank?
      # Try to extract from .aok-offscreen text (e.g., "with 64 percent savings")
      offscreen_text = doc.at_css('.aok-offscreen')&.text&.strip
      if offscreen_text && offscreen_text.match(/(\d+\s*percent\s*savings)/i)
        discount = offscreen_text.match(/(\d+\s*percent\s*savings)/i)[1]
      end
    end

    # Fallback price (for compatibility)
    price = actual_price ||
      doc.at_css('#priceblock_ourprice')&.text&.strip ||
      doc.at_css('#priceblock_dealprice')&.text&.strip ||
      doc.at_css('#priceblock_saleprice')&.text&.strip ||
      doc.at_css('.a-price .a-offscreen')&.text&.strip ||
      doc.at_css('.a-price-whole')&.text&.strip
    if price.blank?
      symbol = doc.at_css('.a-price-symbol')&.text&.strip
      whole = doc.at_css('.a-price-whole')&.text&.strip
      price = "#{symbol}#{whole}" if symbol && whole
    end

    tax =
      doc.at_css('#taxInclusiveMessage')&.text&.strip ||
      doc.at_css('.taxInclusiveMessage')&.text&.strip ||
      doc.at_css('.a-size-base.a-color-secondary')&.text&.strip

    if name.blank? && price.blank? && tax.blank? && mrp.blank? && actual_price.blank? && discount.blank?
      return { error: 'No product data found. Here is a snippet of the HTML for debugging:', html_snippet: response.body[0..500] }
    end

    {
      name: name,
      mrp: mrp,
      actual_price: actual_price,
      discount: discount,
      price: price,
      tax: tax
    }
  rescue => e
    { error: "Failed to scrape product: #{e.message}" }
  end
end 