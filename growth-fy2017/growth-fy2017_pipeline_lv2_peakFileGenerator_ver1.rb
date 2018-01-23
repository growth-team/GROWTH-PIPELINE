#!/usr/bin/env ruby

require "RubyFits"
include Math
include Fits

if (ARGV[3]==nil) then
  puts "Usage: ruby growth-fy2017_pipeline_lv2_peakFileGenerator_ver1.rb <fits index> <channel> <mean of peak> <energy of peak (MeV)>"
  exit 1
end

fitsHead=ARGV[0]
channel=ARGV[1].to_i
peak_chan=ARGV[2].to_f
peak_energy=ARGV[3].to_f
fitsListAddress="#{fitsHead}_work/fitslist.dat"
outputFile="#{fitsHead}_work/peakList_ch#{channel.to_s}.dat"

fitsFileNameAddress=Array.new
unixTime=Array.new
errorUnixTime=Array.new
meanGraphK=Array.new
meanGraphTl=Array.new

energy_K=1460.8  # keV
energy_Tl=2614.5 # keV

fitsList=File.open(fitsListAddress, "r")
fitsList.each_line.with_index do |fitsName, fitsIndex|
  fitsName.chomp!
  fitsFileNameAddress[fitsIndex]=fitsName
  fits=Fits::FitsFile.new("#{fitsHead}_fits_lv1/#{fitsName}")
  timeHDU=fits["GPS"]
  eventHDU=fits["EVENTS"]
  eventNum=eventHDU.getNRows()
  
  fpgaTimeTagStart=eventHDU["timeTag"][0].to_i
  fpgaTimeTagLast=eventHDU["timeTag"][eventNum-1].to_i
  fpgaTimeTagDiff=fpgaTimeTagLast-fpgaTimeTagStart
  if fpgaTimeTagDiff<0 then
    fpgaTimeTagDiff+=2**40-1
  end
  observationTime=fpgaTimeTagDiff.to_f/(1.0e8)
  unixTime[fitsIndex]=timeHDU["unixTime"][0].to_f+observationTime/2.0
  errorUnixTime[fitsIndex]=observationTime/2.0
    
  meanGraphK[fitsIndex]=peak_chan*energy_K/(peak_energy*1000.0)
  meanGraphTl[fitsIndex]=peak_chan*energy_Tl/(peak_energy*1000.0)
  puts fitsName
end

fitsList.close()

File.open(outputFile, "w") do |output|
  for i in 0..fitsFileNameAddress.length-1
    string=fitsFileNameAddress[i].to_s+"\t"+unixTime[i].to_s+"\t"+errorUnixTime[i].to_s+"\t"+meanGraphK[i].to_s+"\t"+"0.0"+"\t"+meanGraphTl[i].to_s+"\t"+"0.0"
    output.puts(string)
  end
end
