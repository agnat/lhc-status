#!/usr/bin/env ruby

Debug = false

require 'open-uri'
require 'rubygems'
require 'RMagick'
require 'YAML'

include(Magick)

def process_screens screens
  result = {}
  screens.each do |screen_name, screen|
    puts screen['url']
    result[screen_name] = {}
    image = fetch_image screen['url']
    screen['fields'].each do |field, params|
      box = params['box']
      field_image = image.crop(*box)
      field_image.write "#{screen_name}_#{field}.png" if Debug
      text = run_ocr(field_image, params['ocr_options'])
      result[screen_name][field] = case params['type']
        when 'Time' then Time.parse(text)
        when 'Integer' then text.to_i
        when 'Float' then text.to_f
        when nil then text
        else eval(params['type']).new(text)
      end
    end
  end
  result
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
puts process_screens(screen_config).inspect

