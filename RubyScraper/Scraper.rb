require 'nokogiri'
require 'httparty'
require 'byebug'
require 'pry'
require 'rest-client'

class Scraper

    attr_reader :url, :make, :model

    def initialize (make, model)
        @make = make.capitalize
        @model = model.capitalize
        @url = "https://www.dupontregistry.com/autos/results/#{make}/#{model}/for-sale".sub(" ", "--")
    end 

    def parse_url(url)
        unparsed_page = HTTParty.get(url)
        if unparsed_page.body.nil? || unparsed_page.code.nil?
            print("error")
            return
        end
        Nokogiri::HTML(unparsed_page)
    end 

    def scrape 
        parsed_page = parse_url(@url)
        cars = parsed_page.css('div.searchResults')

        per_page = cars.count
        total_listings = parsed_page.css('#mainContentPlaceholder_vehicleCountWithin').text.to_i
        total_pages = self.get_number_of_pages(total_listings, per_page)

        first_page = create_car_hash(cars)
        all_other = build_full_cars(total_pages)
        first_page + all_other.flatten

        binding.pry
    end 

    def create_car_hash(car_obj)

        car_obj.map { |car|

        price = "Call for price"
        year = "Unknown"

        unless car.css('.cost').children[1].nil?
            price = car.css('.cost').children[1].text.sub(",","").to_i
        end

        unless car.css('a').children[0].nil?
            year = car.css('a').children[0].text[0..4].strip.to_i
        end

        { 
            name: @make,
            model: @model,
            year: year,
            price: price,
            link: "https://www.dupontregistry.com/#{car.css('a').attr('href').value}" }
        }
    end 

    def get_all_page_urls(array_of_ints)
        array_of_ints.map { |number| 
        @url + "/pagenum=#{number}" }
    end 

    def get_number_of_pages(listings, cars_per_page)
        a = listings % cars_per_page
        if a == 0
            listings / cars_per_page
        else 
            listings / cars_per_page + 1
        end 
    end 

    def build_full_cars(number_of_pages)
        a = [*2..number_of_pages]
        all_page_urls = get_all_page_urls(a)

        all_page_urls.map { |url| 
        pu = parse_url(url)
        cars = pu.css('div.searchResults')
        create_car_hash(cars) }
    end

    binding.pry

end