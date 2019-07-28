#!/usr/bin/env ruby
# coding: utf-8
# growth-tac fits file convertor  pipeline Version 1
# Created and maintained by Yuuki Wada
# Created on 20190418

require "json"
require "shellwords"
require "RubyFits"
require "RubyROOT"
require "time"
include Math
include Root
include RootApp
include Fits
STDOUT.sync=true

puts ""
puts "  ########################################"
puts "  ##  GROWTH-TAC FITS CONVERTOR & QLER  ##"
puts "  ##          April 18th, 2019          ##"
puts "  ##  Yuuki Wada (University of Tokyo)  ##"
puts "  ########################################"
puts ""

if (ARGV[8]==nil) then
  puts "Usage: growth-tac_pipeline.rb <ID> <input folder> <output folder> <ql output folder> <start date> <end date> <academic year> <lower threshold> <upper threshold>"
  puts "Example: growth-tac_pipeline.rb 1 ~/work/raw_data/TAC_001 ~/work/growth/data/processed ~/work/ql 20181001 20190320 2018 30 1024"
  puts ""
  exit 1
end

pipeline_version="growth-tac fits convertor Ver1"
pipeline_version_short="ver1"

detID=ARGV[0].to_i
input_dir=ARGV[1]
output_dir=ARGV[2]
ql_dir=ARGV[3]
start_date=ARGV[4]
end_date=ARGV[5]
academic_year=ARGV[6]
if ARGV[7].to_i<20 then
  lowth=20
else
  lowth=ARGV[7].to_i
end
uppth=ARGV[8].to_i
process_date=Time.now.strftime("%Y%m%d_%H%M%S")

lc_width=[1.0, 10.0]
lc_binNum=[25*3600/lc_width[0].to_i, 25*3600/lc_width[1].to_i]

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

def resetHist(h0, h1, h2)
  h0.Reset()
  h1.Reset()
  h2.Reset()
end

def plotSetting(hist, xtitle, ytitle)
  hist.SetTitle("")
  hist.GetXaxis().SetTitle(xtitle)
  hist.GetYaxis().SetTitle(ytitle)
  hist.SetStats(0)
end

def saveHistPic(outputFileDir, date, spec, lc0, lc1, c0)
  plotSetting(spec, "channel", "Count s^{-1} ch^{-1}")
  plotSetting(lc0, "Hour", "Count s^{-1}")
  plotSetting(lc1, "Hour", "Count s^{-1}")
  lc1.Scale(0.1)
  spec.Draw("h")
  c0.SetLogy(1)
  c0.Update()
  c0.SaveAs("#{outputFileDir}/spec/#{date}_ch0_spec.png")
  lc0.Draw("h")
  c0.SetLogy(0)
  c0.Update()
  c0.SaveAs("#{outputFileDir}/lc_1sec/#{date}_ch0_lc_1sec.png")
  lc1.Draw("h")
  c0.SetLogy(0)
  c0.Update()
  c0.SaveAs("#{outputFileDir}/lc_10sec/#{date}_ch0_lc_10sec.png")
end

def fill_hist(hour, line, lowth, uppth, hist, spec, lc0, lc1)
  lineParse=line.split(",")
  min=lineParse[0].to_f
  sec=lineParse[1].to_f
  precise=lineParse[2].to_f/10000.0
  phaMax=lineParse[3].to_f
  
  time=min*60.0+sec+precise
  timeHour=hour.to_f+(min*60.0+sec+precise)/3600.0

  spec.Fill(phaMax)
  hist.Fill(time, phaMax)
  if (phaMax>lowth)&&(phaMax<uppth) then
    lc0.Fill(timeHour)
    lc1.Fill(timeHour)
  end
end

def caldb_address(id, academic_year)
  caldb_origin=`echo $GROWTHCALDB`
  caldb="#{caldb_origin.chomp!}/FY#{academic_year}_winter/growth-tac#{sprintf("%03d", id)}.json"
  if File.exists?(caldb)==false then
    puts "CALDB file in not found!"
    puts "1. Do you execute in the correct directory?"
    puts "2. Do you copy the CALDB files in your computer?"
    puts "3. Is PATH of GROWTHCALDB correctly set up in your .bashrc?"
    exit 1
  end
  return caldb
end

#============================================
# Main
#============================================

output_fits_dir="#{output_dir}/GROWTH-TAC#{sprintf("%03d", detID)}/fits_lv1"
make_directory(output_fits_dir)
ql_daughter=["lc_1sec", "lc_10sec", "hist_2d", "spec"]
ql_daughter.each do |daughter|
  output_ql_dir="#{ql_dir}/GROWTH-TAC#{sprintf("%03d", detID)}/#{daughter}"
  make_directory(output_ql_dir)
end

caldbFile=caldb_address(detID, academic_year)

caldb_comment=Array.new
caldb_comment[0]="detector ID"
caldb_comment[1]="observation site"
caldb_comment[2]="scintillator ID of Channel 0"
caldb_comment[3]="scintillator ID of Channel 1"
caldb_comment[4]="scintillator ID of Channel 2"
caldb_comment[5]="scintillator ID of Channel 3"
caldb_comment[6]="installation date"
caldb_comment[7]="removal date"

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)

hist=Root::TH2F.create("hist", "hist", 3600, 0.0, 3600.0, 1024, -0.5, 1023.5)
spec=Root::TH1F.create("spec", "spec", 1024, -0.5, 1023.5)
lc0=Root::TH1F.create("lc0", "lc0", lc_binNum[0], 0.0, 25.0)
lc1=Root::TH1F.create("lc1", "lc1", lc_binNum[1], 0.0, 25.0)

caldbInput=File.open(caldbFile)
jsonLoad=JSON.load(caldbInput)

caldb=jsonLoad["detectorInfo"]
caldb_key=Array.new
caldb_value=Array.new

for i in 0..7
  caldb_key[i]=(caldb[i].keys)
  caldb_value[i]=(caldb[i].values)
end

dateList=extractDateList(start_date, end_date)
dateList.each do |date|
  puts date
  resetHist(spec, lc0, lc1)
  year=date[0..3]
  month=date[4..5]
  day=date[6..7]
  for hour in 0..23
    input_file="#{input_dir}/#{year}/#{month}/#{day}/#{sprintf("%03d", detID)}_#{date}_#{sprintf("%02d", hour)}.csv"
    output_file="#{output_fits_dir}/#{date}_#{sprintf("%02d", hour)}0000.fits"
    hist.Reset()

    if File.exist?(input_file) then
      hdu=setupFits()
      primaryHDU=hdu[0]
      eventHDU=hdu[1]
      eventHDU.addHeader("PIPELINE", "level-1", "present pipeline process level")
      eventHDU.addHeader("PL1_DATE", "#{process_date}", "pipeline level-1 processing date")
      eventHDU.addHeader("PL1_VER", "#{pipeline_version}", "pipeline level-1 version")
      for i in 0..7
        fits_key=caldb_key[i].join("")
        fits_value=caldb_value[i].join("")
        fits_comment=caldb_comment[i]
        eventHDU.addHeader(fits_key, fits_value, fits_comment)
      end
      File.open(input_file, "r") do |csv|
        csv_data=csv.readlines()
        eventHDU.resize(csv_data.length)
        csv_data.each.with_index do |line, i|
          fill_hist(hour, line, lowth, uppth, hist, spec, lc0, lc1)
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
      hist_output="#{ql_dir}/GROWTH-TAC#{sprintf("%03d", detID)}/hist_2d/#{date}_#{sprintf("%02d", hour)}0000_ch0_2d.root"
      Root::TFile.open(hist_output, "RECREATE") do |rootFile|
        hist.Write("hist")
      end
    end
  end
  saveHistPic("#{ql_dir}/GROWTH-TAC#{sprintf("%03d", detID)}", date, spec, lc0, lc1, c0)
end
