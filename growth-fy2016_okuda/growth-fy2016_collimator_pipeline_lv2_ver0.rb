#!/usr/local/bin/ruby
# growth-fy2016 pipeline level-2 Version 0
# Created and maintained by Yuuki Wada
# Created on 20161213

require "json"
require "shellwords"
require "RubyFits"
include Math
include Fits

puts ""
puts "  #######################################"
puts "  ## GROWTH-PIPELINE for growth-fy2016 ##"
puts "  ##  Level-2 FITS Process  Version 0  ##"
puts "  ##         January 17th, 2017        ##"
puts "  ## Yuuki Wada  (University of Tokyo) ##"
puts "  #######################################"
puts ""

if (ARGV[5]==nil) then
  puts "Usage: ruby growth-fy2016_collimator_pipeline_lv2_ver0.rb <data index> <threshold ch0> <threshold ch1> <threshold ch2> <threshold ch3> <peak data ch0> <peak data ch1> <peak data ch2> <peak data ch3>"
  exit 1
end

pipeline_version="growth-fy2016 Collimator Version 0"
pipeline_version_short="collimator_ver0"

fitsIndex=ARGV[0]
thresholdChannel_ch0=ARGV[1].to_f
thresholdChannel_ch1=ARGV[2].to_f
thresholdChannel_ch2=ARGV[3].to_f
thresholdChannel_ch3=ARGV[4].to_f
peakFitData_ch0=ARGV[5]
peakFitData_ch1=ARGV[6]
peakFitData_ch2=ARGV[7]
peakFitData_ch3=ARGV[8]
thresholdEnergy_ch0=0.0
thresholdEnergy_ch1=0.0
thresholdEnergy_ch2=0.0
thresholdEnergy_ch3=0.0
date=Time.now.strftime("%Y%m%d_%H%M%S")

energy_K=1460.8  # keV
energy_Tl=2614.5 # keV

if File.exists?(peakFitData_ch0)==false then
  puts "peak file does not exist"
  exit 1
elsif File.exists?(peakFitData_ch1)==false then
  puts "peak file does not exist"
  exit 1
elsif File.exists?(peakFitData_ch2)==false then
  puts "peak file does not exist"
  exit 1
elsif File.exists?(peakFitData_ch3)==false then
  puts "peak file does not exist"
  exit 1
end

fitData_ch0=File.open(peakFitData_ch0, "r")
fitData_ch0.each do |fitDataLine|
  fitDataLine.chomp!
  line=fitDataLine.split("\t")
  peak_K=line[3].to_f
  peak_Tl=line[5].to_f
  energy=energy_K+(energy_Tl-energy_K)*(thresholdChannel_ch0-peak_K)/(peak_Tl-peak_K)
  if energy>thresholdEnergy_ch0 then
    thresholdEnergy_ch0=energy
  end
end
fitData_ch1=File.open(peakFitData_ch1, "r")
fitData_ch1.each do |fitDataLine|
  fitDataLine.chomp!
  line=fitDataLine.split("\t")
  peak_K=line[3].to_f
  peak_Tl=line[5].to_f
  energy=energy_K+(energy_Tl-energy_K)*(thresholdChannel_ch1-peak_K)/(peak_Tl-peak_K)
  if energy>thresholdEnergy_ch1 then
    thresholdEnergy_ch1=energy
  end
end
fitData_ch2=File.open(peakFitData_ch2, "r")
fitData_ch2.each do |fitDataLine|
  fitDataLine.chomp!
  line=fitDataLine.split("\t")
  peak_K=line[3].to_f
  peak_Tl=line[5].to_f
  energy=energy_K+(energy_Tl-energy_K)*(thresholdChannel_ch2-peak_K)/(peak_Tl-peak_K)
  if energy>thresholdEnergy_ch2 then
    thresholdEnergy_ch2=energy
  end
end
fitData_ch3=File.open(peakFitData_ch3, "r")
fitData_ch3.each do |fitDataLine|
  fitDataLine.chomp!
  line=fitDataLine.split("\t")
  peak_K=line[3].to_f
  peak_Tl=line[5].to_f
  energy=energy_K+(energy_Tl-energy_K)*(thresholdChannel_ch3-peak_K)/(peak_Tl-peak_K)
  if energy>thresholdEnergy_ch3 then
    thresholdEnergy_ch3=energy
  end
end
puts thresholdEnergy_ch0

fitsFolderLv2="#{fitsIndex}_fits_lv2_#{pipeline_version_short}"
if File.exists?(fitsFolderLv2)==false then
  `mkdir #{fitsFolderLv2}`
end

fitData_ch0=File.open(peakFitData_ch0, "r")
fitData_ch1=File.open(peakFitData_ch1, "r")
fitData_ch2=File.open(peakFitData_ch2, "r")
fitData_ch3=File.open(peakFitData_ch3, "r")
fitDataLine_ch0=fitData_ch0.readlines
fitDataLine_ch1=fitData_ch1.readlines
fitDataLine_ch2=fitData_ch2.readlines
fitDataLine_ch3=fitData_ch3.readlines

fitDataLine_ch0.each_with_index do |line_ch0, index|
  line_ch1=fitDataLine_ch1[index]
  line_ch2=fitDataLine_ch2[index]
  line_ch3=fitDataLine_ch3[index]
  line_ch0.chomp!
  line_ch1.chomp!
  line_ch2.chomp!
  line_ch3.chomp!
  lineParse_ch0=line_ch0.split("\t")
  lineParse_ch1=line_ch1.split("\t")
  lineParse_ch2=line_ch2.split("\t")
  lineParse_ch3=line_ch3.split("\t")
  if (lineParse_ch0[0]!=lineParse_ch1[0])||(lineParse_ch0[0]!=lineParse_ch2[0])||(lineParse_ch0[0]!=lineParse_ch3[0]) then
    exit 1
  end
  fitsFile=lineParse_ch0[0]
  fitsFileParse=fitsFile.split("/")
  puts fitsFileParse[1]
  newFitsFile="#{fitsFolderLv2}/#{fitsFileParse[1]}"
  peak_K_ch0=lineParse_ch0[3].to_f
  peak_K_ch1=lineParse_ch1[3].to_f
  peak_K_ch2=lineParse_ch2[3].to_f
  peak_K_ch3=lineParse_ch3[3].to_f
  peak_Tl_ch0=lineParse_ch0[5].to_f
  peak_Tl_ch1=lineParse_ch1[5].to_f
  peak_Tl_ch2=lineParse_ch2[5].to_f
  peak_Tl_ch3=lineParse_ch3[5].to_f
  bin_width_ch0=(energy_Tl-energy_K)/(peak_Tl_ch0-peak_K_ch0)
  bin_width_ch1=(energy_Tl-energy_K)/(peak_Tl_ch1-peak_K_ch1)
  bin_width_ch2=(energy_Tl-energy_K)/(peak_Tl_ch2-peak_K_ch2)
  bin_width_ch3=(energy_Tl-energy_K)/(peak_Tl_ch3-peak_K_ch3)
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
    for i in 0..10
      unixTimeUtc=Time.at(unixTime[0]-60.0*60.0*9.0-i.to_f+5.0).strftime("%H%M%S")
      if gpsTimeStart[8..13]==unixTimeUtc then
        unixTimeJst=Time.at(unixTime[0]-i.to_f+5.0)
        gpsVerification=0
        break
      end
    end
  end
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
    
    if adcIndex[i].to_i==0 then
      energyWrite[i]=energy_K+(energy_Tl-energy_K)*(phaMax[i].to_f-peak_K_ch0)/(peak_Tl_ch0-peak_K_ch0)
    elsif adcIndex[i].to_i==1 then
            energyWrite[i]=energy_K+(energy_Tl-energy_K)*(phaMax[i].to_f-peak_K_ch1)/(peak_Tl_ch1-peak_K_ch1)
    elsif adcIndex[i].to_i==2 then
            energyWrite[i]=energy_K+(energy_Tl-energy_K)*(phaMax[i].to_f-peak_K_ch2)/(peak_Tl_ch2-peak_K_ch2)
    elsif adcIndex[i].to_i==3 then
            energyWrite[i]=energy_K+(energy_Tl-energy_K)*(phaMax[i].to_f-peak_K_ch3)/(peak_Tl_ch3-peak_K_ch3)
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
  eventHDU.addHeader("CAL_CH0", "YES", "Channel 0 are calibrated or not.")
  eventHDU.addHeader("CAL_CH1", "YES", "Channel 1 are calibrated or not.")
  eventHDU.addHeader("CAL_CH2", "YES", "Channel 2 are calibrated or not.")
  eventHDU.addHeader("CAL_CH3", "YES", "Channel 3 are calibrated or not.")

  eventHDU.setHeader("CTH_CH0", sprintf("%.2f", thresholdChannel_ch0))
  eventHDU.appendComment("CTH_CH0: lower threshold of Channel 0 in Channel (channel)")
  eventHDU.setHeader("ETH_CH0", sprintf("%.2f", thresholdEnergy_ch0))
  eventHDU.appendComment("ETH_CH0: lower threshold of Channel 0 in Energy (keV)")
  eventHDU.addHeader("LNK_CH0", sprintf("%.2f", lineParse_ch0[3]), "40K peak mean in Channel 0 (adc channel)")
  eventHDU.addHeader("LNTL_CH0", sprintf("%.2f", lineParse_ch0[5]), "208Tl peak mean in Channel 0 (adc channel)")
  eventHDU.addHeader("BINW_CH0", sprintf("%.2f", bin_width_ch0), "Bin width of Channel 0 in Energy (keV)")

  eventHDU.setHeader("CTH_CH1", sprintf("%.2f", thresholdChannel_ch2))
  eventHDU.appendComment("CTH_CH1: lower threshold of Channel 1 in Channel (channel)")
  eventHDU.setHeader("ETH_CH1", sprintf("%.2f", thresholdEnergy_ch1))
  eventHDU.appendComment("ETH_CH1: lower threshold of Channel 1 in Energy (keV)")
  eventHDU.addHeader("LNK_CH1", sprintf("%.2f", lineParse_ch1[3]), "40K peak mean in Channel 1 (adc channel)")
  eventHDU.addHeader("LNTL_CH1", sprintf("%.2f", lineParse_ch1[5]), "208Tl peak mean in Channel 1 (adc channel)")
  eventHDU.addHeader("BINW_CH1", sprintf("%.2f", bin_width_ch1), "Bin width of Channel 1 in Energy (keV)")
  
  eventHDU.setHeader("CTH_CH2", sprintf("%.2f", thresholdChannel_ch2))
  eventHDU.appendComment("CTH_CH2: lower threshold of Channel 2 in Channel (channel)")
  eventHDU.setHeader("ETH_CH2", sprintf("%.2f", thresholdEnergy_ch2))
  eventHDU.appendComment("ETH_CH2: lower threshold of Channel 2 in Energy (keV)")
  eventHDU.addHeader("LNK_CH2", sprintf("%.2f", lineParse_ch2[3]), "40K peak mean in Channel 2 (adc channel)")
  eventHDU.addHeader("LNTL_CH2", sprintf("%.2f", lineParse_ch2[5]), "208Tl peak mean in Channel 2 (adc channel)")
  eventHDU.addHeader("BINW_CH2", sprintf("%.2f", bin_width_ch2), "Bin width of Channel 2 in Energy (keV)")

  eventHDU.setHeader("CTH_CH3", sprintf("%.2f", thresholdChannel_ch3))
  eventHDU.appendComment("CTH_CH3: lower threshold of Channel 3 in Channel (channel)")
  eventHDU.setHeader("ETH_CH3", sprintf("%.2f", thresholdEnergy_ch3))
  eventHDU.appendComment("ETH_CH3: lower threshold of Channel 3 in Energy (keV)")
  eventHDU.addHeader("LNK_CH3", sprintf("%.2f", lineParse_ch3[3]), "40K peak mean in Channel 3 (adc channel)")
  eventHDU.addHeader("LNTL_CH3", sprintf("%.2f", lineParse_ch3[5]), "208Tl peak mean in Channel 3 (adc channel)")
  eventHDU.addHeader("BINW_CH3", sprintf("%.2f", bin_width_ch3), "Bin width of Channel 3 in Energy (keV)")
  
  fits.saveAs(newFitsFile)
end
