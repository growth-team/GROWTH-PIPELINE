#!/usr/bin/env ruby
# growth-fy2016 pipeline level-2 Version 1
# Created and maintained by Yuuki Wada
# Created on 20170322

require "json"
require "shellwords"
require "RubyFits"
include Math
include Fits

puts ""
puts "  #######################################"
puts "  ## GROWTH-PIPELINE for growth-fy2016 ##"
puts "  ##  Level-2 FITS Process  Version 2  ##"
puts "  ##          April 23rd, 2017         ##"
puts "  ## Yuuki Wada  (University of Tokyo) ##"
puts "  #######################################"
puts ""

if (ARGV[1]==nil) then
  puts "Usage: ruby growth-fy2016_pipeline_lv2_ver2.rb <data index> <peak data> <calibrated channel> <threshold>"
  puts ""
  exit 1
end

pipeline_version="growth-fy2016 Version 2"
pipeline_version_short="ver2"

fitsIndex=ARGV[0]
peakFitData=ARGV[1]
calibrationCh=ARGV[2].to_i
thresholdChannel=ARGV[3].to_f
thresholdEnergy=0.0
date=Time.now.strftime("%Y%m%d_%H%M%S")

energy_K=1460.8  # keV
energy_Tl=2614.5 # keV


if File.exists?(peakFitData)==false then
  puts "peak file does not exist"
  exit 1
end

fitData=File.open(peakFitData, "r")
fitData.each do |fitDataLine|
  fitDataLine.chomp!
  line=fitDataLine.split("\t")
  peak_K=line[3].to_f
  peak_Tl=line[5].to_f
  energy=energy_K+(energy_Tl-energy_K)*(thresholdChannel-peak_K)/(peak_Tl-peak_K)
  if energy>thresholdEnergy then
    thresholdEnergy=energy
  end
end
puts thresholdEnergy

fitsFolderLv2="#{fitsIndex}_fits_lv2_#{pipeline_version_short}"
if File.exists?(fitsFolderLv2)==false then
  `mkdir #{fitsFolderLv2}`
end

fitData=File.open(peakFitData, "r")
fitData.each_line do |fitDataLine|
  fitDataLine.chomp!
  line=fitDataLine.split("\t")
  fitsFile=line[0]
  fitsFileParse=fitsFile.split("/")
  puts fitsFileParse[3]
  newFitsFile="#{fitsFolderLv2}/#{fitsFileParse[3]}"
  peak_K=line[3]
  peak_Tl=line[5]
  bin_width=(energy_Tl-energy_K)/(line[5].to_f-line[3].to_f)
  fits=FitsFile.new(fitsFile)
  eventHDU=fits.hdu("EVENTS")
  timeHDU=fits.hdu("GPS")
  columnNum=eventHDU.nRows
  phaMax=eventHDU["phaMax"]
  adcIndex=eventHDU["boardIndexAndChannel"]
  eventFpgaTag=eventHDU["timeTag"]
  unixTime=timeHDU["unixTime"]
  gpsTimeTag=timeHDU["fpgaTimeTag"]
  gpsTime=timeHDU["gpsTime"]
  timeTagFirst=eventFpgaTag[0]
  gpsTimeStart=gpsTime[0]
  unixTimeJst=Time.at(unixTime[0]).strftime("%Y%m%d%H%M%S")
  gpsVerification=1
  if gpsTime[0..3]!="GP80" then
    for i in 0..100
      unixTimeUtc=Time.at(unixTime[0]-60.0*60.0*9.0-i.to_f+50.0).strftime("%H%M%S")
      if gpsTimeStart[8..13]==unixTimeUtc then
        unixTimeJst=Time.at(unixTime[0]-i.to_f+50.0)
        gpsVerification=0
        break
      end
    end
  end
  if gpsVerification==1 then
    unixTimeJst=Time.at(unixTime[0]).to_f
    puts "GPS signal was not detected."
  end
  # puts gpsVerification
  # puts unixTimeJst.to_f
  gpsTimeTagModified=gpsTimeTag[0]&0xFFFFFFFFFF
  timeTagDiff=(eventFpgaTag[0]-gpsTimeTagModified)/1.0e8
  if timeTagDiff>900.0 then
    timeTagDiff=(eventFpgaTag[0]-2**40-gpsTimeTagModified)/1.0e8
  elsif timeTagDiff<-900.0 then
    timeTagDiff=(eventFpgaTag[0]+2**40-gpsTimeTagModified)/1.0e8
  end
  unixTimeFirst=unixTimeJst.to_f+timeTagDiff
  eventUnixTime=FitsTableColumn.new
  eventUnixTime.initializeWithNameAndFormat("unixTime","D")
  eventUnixTime.setUnit("sec")
  energy=FitsTableColumn.new
  energy.initializeWithNameAndFormat("energy","E")
  energy.setUnit("keV")
  eventUnixTime.resize(columnNum)
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
    if calibrationCh==adcIndex[i].to_i then
      energyWrite[i]=energy_K+(energy_Tl-energy_K)*(phaMax[i].to_f-peak_K.to_f)/(peak_Tl.to_f-peak_K.to_f)
    else
      energyWrite[i]=0.0
    end
  end
  eventHDU.addHeader("PIPELINE", "level-2", "present pipeline process level")
  eventHDU.addHeader("PL2_DATE", "#{date}", "pipeline level-2 processing date")
  eventHDU.addHeader("PL2_VER", "#{pipeline_version}", "pipeline level-2 version")
  if gpsVerification==0 then
    eventHDU.addHeader("TIME_CAL", "2", "method of time calibration")
  else
    eventHDU.addHeader("TIME_CAL", "1", "method of time calibration")
  end
  eventHDU.appendComment("TIME_CAL: method of time calibration 0:from file name, 1:from UNIXTIME, 2:from GPS time")
  if calibrationCh==0 then
    eventHDU.addHeader("CAL_CH0", "YES", "Channel 0 are calibrated or not.")
    eventHDU.addHeader("CAL_CH1", "NO", "Channel 1 are calibrated or not.")

    eventHDU.setHeader("CTH_CH0", sprintf("%.2f", thresholdChannel))
    eventHDU.appendComment("CTH_CH0: lower threshold of Channel 0 in Channel (channel)")
    eventHDU.setHeader("ETH_CH0", sprintf("%.2f", thresholdEnergy))
    eventHDU.appendComment("ETH_CH0: lower threshold of Channel 0 in Energy (keV)")
    eventHDU.addHeader("LNK_CH0", sprintf("%.2f", line[3]), "40K peak mean in Channel 0 (adc channel)")
    eventHDU.addHeader("LNTL_CH0", sprintf("%.2f", line[5]), "208Tl peak mean in Channel 0 (adc channel)")
    eventHDU.addHeader("BINW_CH0", sprintf("%.2f", bin_width), "Bin width of Channel 0 in Energy (keV)")

    eventHDU.setHeader("CTH_CH1", "NONE")
    eventHDU.appendComment("CTH_CH1: lower threshold of Channel 1 in Channel (channel)")
    eventHDU.setHeader("ETH_CH1", "NONE")
    eventHDU.appendComment("ETH_CH1: lower threshold of Channel 1 in Energy (keV)")
    eventHDU.addHeader("LNK_CH1", "NONE", "40K peak mean in Channel 1 (adc channel)")
    eventHDU.addHeader("LNTL_CH1", "NONE", "208Tl peak mean in Channel 1 (adc channel)")
    eventHDU.addHeader("BINW_CH1", "NONE", "Bin width of Channel 1 in Energy (keV)")
  elsif calibrationCh==1 then
    eventHDU.addHeader("CAL_CH0", "NO", "Channel 0 are calibrated or not.")
    eventHDU.addHeader("CAL_CH1", "YES", "Channel 1 are calibrated or not.")

    eventHDU.setHeader("CTH_CH0", "NONE")
    eventHDU.appendComment("CTH_CH0: lower threshold of Channel 0 in Channel (channel)")
    eventHDU.setHeader("ETH_CH0", "NONE")
    eventHDU.appendComment("ETH_CH0: lower threshold of Channel 0 in Energy (keV)")
    eventHDU.addHeader("LNK_CH0", "NONE", "40K peak mean in Channel 0 (adc channel)")
    eventHDU.addHeader("LNTL_CH0", "NONE", "208Tl peak mean in Channel 0 (adc channel)")
    eventHDU.addHeader("BINW_CH0", "NONE", "Bin width of Channel 0 in Energy (keV)")

    eventHDU.setHeader("CTH_CH1", sprintf("%.2f", thresholdChannel))
    eventHDU.appendComment("CTH_CH1: lower threshold of Channel 1 in Channel (channel)")
    eventHDU.setHeader("ETH_CH1", sprintf("%.2f", thresholdEnergy))
    eventHDU.appendComment("ETH_CH1: lower threshold of Channel 1 in Energy (keV)")
    eventHDU.addHeader("LNK_CH1", sprintf("%.2f", line[3]), "40K peak mean in Channel 1 (adc channel)")
    eventHDU.addHeader("LNTL_CH1", sprintf("%.2f", line[5]), "208Tl peak mean in Channel 1 (adc channel)")
    eventHDU.addHeader("BINW_CH1", sprintf("%.2f", bin_width), "Bin width of Channel 1 in Energy (keV)")
  else
    eventHDU.addHeader("CAL_CH0", "NO", "Channel 0 are calibrated or not.")
    eventHDU.addHeader("CAL_CH1", "NO", "Channel 1 are calibrated or not.")

    eventHDU.setHeader("CTH_CH0", "NONE")
    eventHDU.appendComment("CTH_CH0: lower threshold of Channel 0 in Channel (channel)")
    eventHDU.setHeader("ETH_CH0", "NONE")
    eventHDU.appendComment("ETH_CH0: lower threshold of Channel 0 in Energy (keV)")
    eventHDU.addHeader("LNK_CH0", "NONE", "40K peak mean in Channel 0 (adc channel)")
    eventHDU.addHeader("LNTL_CH0", "NONE", "208Tl peak mean in Channel 0 (adc channel)")
    eventHDU.addHeader("BINW_CH0", "NONE", "Bin width of Channel 0 in Energy (keV)")

    eventHDU.setHeader("CTH_CH1", "NONE")
    eventHDU.appendComment("CTH_CH1: lower threshold of Channel 1 in Channel (channel)")
    eventHDU.setHeader("ETH_CH1", "NONE")
    eventHDU.appendComment("ETH_CH1: lower threshold of Channel 1 in Energy (keV)")
    eventHDU.addHeader("LNK_CH1", "NONE", "40K peak mean in Channel 1 (adc channel)")
    eventHDU.addHeader("LNTL_CH1", "NONE", "208Tl peak mean in Channel 1 (adc channel)")
    eventHDU.addHeader("BINW_CH1", "NONE", "Bin width of Channel 1 in Energy (keV)")
  end
  fits.saveAs(newFitsFile)

end
