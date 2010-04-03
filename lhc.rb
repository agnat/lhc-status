#!/usr/bin/env ruby

Debug = false

require 'open-uri'
require 'rubygems'
require 'RMagick'
require 'YAML'
require 'growl'

include(Magick)

def process_screens screens
  result = {}
  screens.each do |screen_name, screen|
    result[screen_name] = {}
    image = fetch_image screen['url']
    screen['fields'].each do |field, params|
      field_image = image.crop(*params['box'])
      if params['type'] == 'red_green_bool'
        result[screen_name][field] = red_green_bool field_image
      else
        text = run_ocr field_image, params['ocr_options']
        result[screen_name][field] = case params['type']
          when 'Time' then Time.parse(text)
          when 'Integer' then text.to_i
          when 'Float' then text.to_f
          when nil then text
          else eval(params['type']).new(text)
        end
      end
    end
  end
  result
end

def red_green_bool image
  pixel = image.pixel_color 0, 0
  pixel.green > pixel.red
end

def fetch_image url
  png_blob = open(url) { |image| image.read }
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
last_comment = ""
while true
  result = process_screens(screen_config)
  comment = result['lhc1']['comment']
  if last_comment != comment
    File.open('comments.log', 'a') do |file|
      file.puts "=== #{result['lhc1']['update_time']} ========================================"
      file.write comment
    end
    Growl.notify comment,
      :title => result['lhc1']['machine_status'],
      :icon  => "#{File.dirname $0 }/gfx/CERN.png"
    last_comment = comment
  end
  sleep 11
end

