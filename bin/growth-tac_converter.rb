#!/usr/bin/env ruby
# coding: utf-8
# growth-tac fits file convertor
# Created and maintained by Yuuki Wada
# Created on 20190423

require "shellwords"
require "RubyFits"
require "time"
include Math
include Fits
STDOUT.sync=true

puts ""
puts "  ########################################"
puts "  ##     GROWTH-TAC FITS CONVERTOR      ##"
puts "  ##          April 23rd, 2019          ##"
puts "  ##  Yuuki Wada (University of Tokyo)  ##"
puts "  ########################################"
puts ""

if (ARGV[1]==nil) then
  puts "Usage: growth-tac_pipeline.rb <input file> <output folder>"
  puts "Example: growth-tac_pipeline.rb ~/work/raw_data/TAC_001/001_20190131_00.csv ~/work/growth/data/converted"
  puts "File name must not be changed from the original name."
  puts ""
  exit 1
end

input_file=ARGV[0]
output_dir=ARGV[1]

#============================================
# Define objects
#============================================

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
TFORM#=K
TTYPE#=timeTag
TFORM#=I
TTYPE#=phaMax
TFORM#=I
TTYPE#=phaMin
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

def extract_timeTag(line)
  lineParse=line.split(",")
  min=lineParse[0].to_f
  sec=lineParse[1].to_f
  precise=lineParse[2].to_f/10000.0

  timeTag=((min*3600+sec+precise)*1.0e8).to_i
  return timeTag
end

def extract_preciseTime(line)
  lineParse=line.split(",")
  precise=lineParse[2].to_f/10000.0
  return precise
end

def extract_file_name(name)
  name_parse=name.split("/")
  file=name_parse[name_parse.length-1]
  return file
end

#============================================
# Main
#============================================

make_directory(output_dir)

input_file_name=extract_file_name(input_file)
detID=input_file_name[0..2]
date=input_file_name[4..11]
year=input_file_name[4..7]
month=input_file_name[8..9]
day=input_file_name[10..11]
hour=input_file_name[13..14]
output_file="#{output_dir}/#{input_file_name[0..14]}.fits"

if File.exist?(input_file) then
  hdu=setupFits()
  primaryHDU=hdu[0]
  eventHDU=hdu[1]
  File.open(input_file, "r") do |csv|
    csv_data=csv.readlines()
    eventHDU.resize(csv_data.length)
    csv_data.each.with_index do |line, i|
      eventHDU["boardIndexAndChannel"][i]=0
      eventHDU["timeTag"][i]=extract_timeTag(line)
      eventHDU["phaMax"][i]=extract_phaMax(line)
      eventHDU["phaMin"][i]=0
      eventHDU["unixTime"][i]=extract_unixTime(date, hour, line)
      eventHDU["preciseTime"][i]=extract_preciseTime(line)
    end
  end
  fitsFileOutput=FitsFile.new
  fitsFileOutput.append primaryHDU
  fitsFileOutput.append eventHDU
  fitsFileOutput.saveAs(output_file)
  `gzip --force #{output_file}`
end
