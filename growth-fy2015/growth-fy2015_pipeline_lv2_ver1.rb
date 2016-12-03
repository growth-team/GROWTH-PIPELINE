#!/usr/local/bin/ruby
# growth-fy2015 pipeline level-2 Version 1
# Created snd maintained by Yuuki Wada
# Created on 20161203

require "json"
require "shellwords"
require "RubyFits"
include Math
include Fits

if (ARGV[1]==nil) then
  puts "Usage: ruby growth-fy2015_pipeline_lv2_ver1.rb <peak data> <threshold>"
  exit 1
end

fitsIndex=ARGV[0]
peakFitData=ARGV[1]
thresholdChannel=ARGV[2].to_f
thresholdEnergy=0.0
date=Time.now.strftime("%Y%m%d_%H%M%S")

energy_K=1460.8  # keV
energy_Tl=2614.5 # keV

pipeline_version="Version 1"

if File.exists?(peakFitData)==false then
  puts "peak file does not exist"
  exit 1
end

fitData=File.open(peakFitData, "r")
fitData.each do |fitDataLine|
  fitDataLine.chomp!
  line=fitDataLine.split"\t"
  peak_K=line[3].to_f
  peak_Tl=line[5].to_f
  energy=energy_K+(energy_Tl-energy_K)*(thresholdChannel-peak_K)/(peak_Tl-peak_K)
  if energy>thresholdEnergy then
    thresholdEnergy=energy
  end
end
puts thresholdEnergy

fitsFolderLv2="../#{fitsIndex}_fits_lv2"
if File.exists?(fitsFolderLv2)==false then
  `mkdir #{fitsFolderLv2}`
end

fitData=File.open(peakFitData, "r")
fitData.each_line do |fitDataLine|
  fitDataLine.chomp!
  line=fitDataLine.split"\t"
  fitsFile=line[0]
  fitsFileParse=fitsFile.split("/")
  newFitsFile="#{fitsFolderLv2}/#{fitsFileParse[2]}"
  peak_K=line[3]
  peak_Tl=line[5]
  bin_width=(energy_Tl-energy_K)/(line[5].to_f-line[3].to_f)
  fits=FitsFile.new(fitsFile)
  eventHDU=fits.hdu("EVENTS")
  eventFpgaTag=eventHDU["timeTag"]
  phaMax=eventHDU["phaMax"]
  columnNum=eventHDU.nRows
  eventHDU.addHeader("PIPELINE", "level-2", "present pipeline process level")
  eventHDU.addHeader("PL2_DATE", "#{date}", "pipeline level-2 processing date")
  eventHDU.addHeader("PL2_VER", "#{pipeline_version}", "pipeline level-2 version")
  eventHDU.addHeader("TIME_CAL", "1", "method of time calibration 0:from file name, 1:from unix time in GPS HDU, 2:from GPS time in GPS HDU")
  eventHDU.addHeader("ENER_TH", sprintf("%.2f", thresholdEnergy), "lower threshold (keV)")
  eventHDU.addHeader("PEAK_K", sprintf("%.2f", line[3]), "40K peak mean (adc channel)")
  eventHDU.addHeader("PEAK_TL", sprintf("%.2f", line[5]), "208Tl peak mean (adc channel)")
  eventHDU.addHeader("BINWIDTH", sprintf("%.2f", bin_width), "energy width corresponding to adc bin width (keV)")
  timeHDU=fits.hdu("GPS")
  timeFpgaTag=timeHDU["fpgaTimeTag"]
  unixTime=timeHDU["unixTime"]
  timeTagFirst=eventFpgaTag[0].to_i
  unixTimeFirst=unixTime[0].to_f
  eventUnixTime=FitsTableColumn.new
  eventUnixTime.initializeWithNameAndFormat("unixTime","D")
  energy=FitsTableColumn.new
  energy.initializeWithNameAndFormat("energy","F")
  eventUnixTime.resize(128)
  energy.resize(columnNum)
  eventHDU.appendColumn(eventUnixTime)
  eventHDU.appendColumn(energy)
  unixTimeWrite=eventHDU["unixTime"]
  energyWrite=eventHDU["energy"]
  for i in 0..columnNum-1
    if timeTagFirst>eventFpgaTag[i].to_i then
      unixTimeWrite[i]=unixTimeFirst+(eventFpgaTag[i].to_i-timeTagFirst+2**40).to_f/1.0e8
    else
      unixTimeWrite[i]=unixTimeFirst+(eventFpgaTag[i].to_i-timeTagFirst).to_f/1.0e8
    end
    energyWrite[i]=energy_K+(energy_Tl-energy_K)*(phaMax[i].to_f-peak_K.to_f)/(peak_Tl.to_f-peak_K.to_f)
  end
  fits.saveAs(newFitsFile)
end
