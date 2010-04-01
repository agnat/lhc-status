#!/usr/bin/env ruby

Debug = false

require 'open-uri'
require 'rubygems'
require 'RMagick'
require 'YAML'

include(Magick)

def process_screens screens
  screens.each do |screen_name, screen|
    puts screen['url']
    image = fetch_image screen['url']
    screen['fields'].each do |field, params|
      puts "   - #{field}"
      box = params['box']
      field_image = image.crop(*box)
      field_image.write "#{screen_name}_#{field}.png" if Debug
    end
  end
end

def fetch_image url
  png_blob = open "#{url}?#{rand(1e6)}" do |image|
    image.read
  end
  Image.from_blob(png_blob).first
end

def run_ocr image, options
  IO::popen "gocr #{options} -", 'r+' do |ocr|
    ocr.write(image.to_blob { self.format = 'pnm' })
    ocr.close_write
    ocr.read
  end
end

screen_config = YAML::load_file 'screens.yml'
process_screens screen_config

