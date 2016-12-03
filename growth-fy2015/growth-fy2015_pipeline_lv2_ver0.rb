#!/usr/local/bin/ruby
require "json"
require "shellwords"
require "RubyFits"
include Math
include Fits

if (ARGV[1]==nil) then
  puts "Usage: ruby growth-fy2015_decideThreshold.rb <peak data> <threshold>"
  exit 1
end

fitsIndex=ARGV[0]
peakFitData=ARGV[1]
thresholdChannel=ARGV[2].to_f
thresholdEnergy=0.0
date=Time.now.strftime("%Y%m%d_%H%M%S")

fitData=File.open(peakFitData, "r")
fitData.each do |fitDataLine|
  fitDataLine.chomp!
  line=fitDataLine.split"\t"
  peak_K=line[3].to_f
  peak_Tl=line[5].to_f
  energy=1460.0+(2160.0-1460.0)*(thresholdChannel-peak_K)/(peak_Tl-peak_K)
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
  fits=FitsFile.new(fitsFile)
  eventHDU=fits.hdu("EVENTS")
  eventFpgaTag=eventHDU["timeTag"]
  phaMax=eventHDU["phaMax"]
  columnNum=eventHDU.nRows
  eventHDU.setHeader("PIPELINE", "level-2")
  eventHDU.setHeader("PIPELINE_LEVEL-2_DATE", date)
  eventHDU.setHeader("LOW_ENERGY_THRESHOLD", thresholdEnergy.to_s)
  eventHDU.setHeader("PEAK_K", line[3])
  eventHDU.setHeader("PEAK_TL", line[5])
  timeHDU=fits.hdu("GPS")
  timeFpgaTag=timeHDU["fpgaTimeTag"]
  unixTime=timeHDU["unixTime"]
  timeTagFirst=eventFpgaTag[0].to_i
  unixTimeFirst=unixTime[0].to_f
  eventUnixTime=FitsTableColumn.new
  eventUnixTime.initializeWithNameAndFormat("UNIXTIME","D")
  energy=FitsTableColumn.new
  energy.initializeWithNameAndFormat("ENERGY","D")
  energyLow=FitsTableColumn.new
  energyLow.initializeWithNameAndFormat("ENERGY_LOW","D")
  energyHigh=FitsTableColumn.new
  energyHigh.initializeWithNameAndFormat("ENERGY_HIGH","D")
  eventUnixTime.resize(128)
  energy.resize(columnNum)
  energyLow.resize(columnNum)
  energyHigh.resize(columnNum)
  eventHDU.appendColumn(eventUnixTime)
  eventHDU.appendColumn(energy)
  eventHDU.appendColumn(energyLow)
  eventHDU.appendColumn(energyHigh)
  unixTimeWrite=eventHDU["UNIXTIME"]
  energyWrite=eventHDU["ENERGY"]
  energyLowWrite=eventHDU["ENERGY_LOW"]
  energyHighWrite=eventHDU["ENERGY_HIGH"]
  for i in 0..columnNum-1
    if timeTagFirst>eventFpgaTag[i].to_i then
      unixTimeWrite[i]=unixTimeFirst+(eventFpgaTag[i].to_i-timeTagFirst+2**40).to_f/1.0e8
    else
      unixTimeWrite[i]=unixTimeFirst+(eventFpgaTag[i].to_i-timeTagFirst).to_f/1.0e8
    end
    energyWrite[i]=1460.0+(2610.0-1460.0)*(phaMax[i].to_f-peak_K.to_f)/(peak_Tl.to_f-peak_K.to_f)
    energyLowWrite[i]=1460.0+(2610.0-1460.0)*(phaMax[i].to_f-0.5-peak_K.to_f)/(peak_Tl.to_f-peak_K.to_f)
    energyHighWrite[i]=1460.0+(2610.0-1460.0)*(phaMax[i].to_f+0.5-peak_K.to_f)/(peak_Tl.to_f-peak_K.to_f)
  end
  fits.saveAs(newFitsFile)
end


    
