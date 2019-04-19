#!/usr/bin/env ruby
# coding: utf-8
# growth-tac fits file convertor  pipeline Version 1
# Created and maintained by Yuuki Wada
# Created on 20190418

require "json"
require "shellwords"
require "RubyFits"
require "time"
include Math
include Fits
STDOUT.sync=true

puts ""
puts "  #######################################"
puts "  ##     GROWTH-TAC FITS CONVERTOR     ##"
puts "  ##         April 18th, 2019          ##"
puts "  ## Yuuki Wada  (University of Tokyo) ##"
puts "  #######################################"
puts ""

if (ARGV[4]==nil) then
  puts "Usage: growth-tac_pipeline.rb <ID> <input folder> <output folder> <start date> <end date>"
  puts "Example: growth-tac_pipeline.rb 1 ~/work/raw_data/TAC_1 ~/work/growth/data/processed 1 20181001 20190320"
  puts ""
  exit 1
end

pipeline_version="growth-tac fits convertor Ver1"
pipeline_version_short="ver1"

detID=ARGV[0].to_i
input_dir=ARGV[1]
output_dir=ARGV[2]
start_date=ARGV[3]
end_date=ARGV[4]
date=Time.now.strftime("%Y%m%d_%H%M%S")

energy_K=1460.8
energy_Tl=2614.5

#============================================
# Define objects
#============================================

def extractDateList(start_date, end_date)
  obj_start=Date.new(start_date[0..3].to_i, start_date[4..5].to_i, start_date[6..7].to_i)
  obj_end=Date.new(end_date[0..3].to_i, end_date[4..5].to_i, end_date[6..7].to_i)
  date_num=(obj_end-obj_start+1).to_i
  date_array=Array.new
  date_num.times do |i|
    date_now=obj_start+i
    date_array << date_now.strftime("%Y%m%d")
  end
  date_array
end

def make_directory(dir)
  if !File.exist?(dir) then
    `mkdir -p #{dir}`
  end
end

def setupFits()
  template=<<EOS
XTENSION=BINTABLE
EXTNAME=EVENTS
TFORM#=B
TTYPE#=boardIndexAndChannel
TFORM#=I
TTYPE#=phaMax
TFORM#=D
TTYPE#=unixTime
TFORM#=E
TTYPE#=preciseTime
EOS
  hdu=FitsFile.constructFromTemplateString(template)
  return hdu
end

def extract_phaMax(line)
  lineParse=line.split(",")
  return lineParse[3].to_f
end

def extract_unixTime(date, hour, line)
  lineParse=line.split(",")
  min=lineParse[0].to_i
  sec=lineParse[1].to_i
  precise=lineParse[2].to_f/10000.0

  unixTimeInt="#{date} #{sprintf("%02d", hour)}#{sprintf("%02d", min)}#{sprintf("%02d", sec)}"
  unixTime=(Time.parse(unixTimeInt).to_i).to_f+precise
  return unixTime
end

def extract_preciseTime(line)
  lineParse=line.split(",")
  precise=lineParse[2].to_f/10000.0
  return precise
end

#============================================
# Main
#============================================

output_fits_dir="#{output_dir}/GROWTH-TAC#{sprintf("%03d", detID)}/fits_lv1"
make_directory(output_fits_dir)
dateList=extractDateList(start_date, end_date)
dateList.each do |date|
  puts date
  year=date[0..3]
  month=date[4..5]
  day=date[6..7]
  for hour in 0..23
    input_file="#{input_dir}/#{year}/#{month}/#{day}/#{sprintf("%03d", detID)}_#{date}_#{sprintf("%02d", hour)}.csv"
    output_file="#{output_fits_dir}/#{date}_#{sprintf("%02d", hour)}0000.fits"

    if File.exist?(input_file) then
      hdu=setupFits()
      primaryHDU=hdu[0]
      eventHDU=hdu[1]
      File.open(input_file, "r") do |csv|
        csv_data=csv.readlines()
        eventHDU.resize(csv_data.length)
        csv_data.each.with_index do |line, i|
          eventHDU["boardIndexAndChannel"][i]=0
          eventHDU["phaMax"][i]=extract_phaMax(line)
          eventHDU["unixTime"][i]=extract_unixTime(date, hour, line)
          eventHDU["preciseTime"][i]=extract_preciseTime(line)
        end
      end
      fitsFileOutput=FitsFile.new
      fitsFileOutput.append primaryHDU
      fitsFileOutput.append eventHDU
      fitsFileOutput.saveAs(output_file)
      `gzip #{output_File}`
    end
  end
end
