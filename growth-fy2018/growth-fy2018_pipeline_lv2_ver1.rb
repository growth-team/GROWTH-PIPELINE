#!/usr/bin/env ruby
# coding: utf-8
# growth-fy2018 pipeline level-2 Version 1
# Created and maintained by Yuuki Wada
# Created on 20190212

require "json"
require "shellwords"
require "RubyFits"
include Math
include Fits
STDOUT.sync=true

puts ""
puts "  #######################################"
puts "  ## GROWTH-PIPELINE for growth-fy2018 ##"
puts "  ##  Level-2 FITS Process  Version 1  ##"
puts "  ##        February 12th, 2019        ##"
puts "  ## Yuuki Wada  (University of Tokyo) ##"
puts "  #######################################"
puts ""

if (ARGV[4]==nil) then
  puts "Usage: ruby growth-fy2018_pipeline_lv2_ver1.rb <data index> <ch0 true/false> <ch1> <ch2> <ch3>"
  puts ""
  exit 1
end

pipeline_version="growth-fy2018 Ver1"
pipeline_version_short="ver1"

fitsIndex=ARGV[0]
cal_info=[ARGV[1], ARGV[2], ARGV[3], ARGV[4]]
date=Time.now.strftime("%Y%m%d_%H%M%S")

energy_K=1460.8
energy_Tl=2614.5

#============================================
# Define objects
#============================================

def check_file_exist(fits_index, switch, i)
  if (switch!="true")&&(switch!="false") then
    puts "Please input true or false"
    exit 1
  end
  peak_file="#{fits_index}_work/peakList_ch#{i.to_s}.dat"
  if (switch=="true")&&(File.exists?(peak_file)==false) then
    puts "peak file does not exist"
    exit 1
  end
end

def peak_file_record(fits_index, switch, i, enabled_channel, peak_data_file)
  if switch=="true" then
    enabled_channel << i.to_i
    peak_data_file << "#{fits_index}_work/peakList_ch#{i.to_s}.dat"
  end
end

def extract_peak_file(peak_data_line, fits_name, peak_K, peak_Tl, i, j)
  peak_data_line[j][i].chomp!
  peak_data_split=peak_data_line[j][i].split("\t")
  fits_name[j]=peak_data_split[0]
  peak_K[j]=peak_data_split[3].to_f
  peak_Tl[j]=peak_data_split[5].to_f
end

def verify_peak_file(fits_name, i)
  if fits_name[0]!=fits_name[i] then
    puts "Peak File is not consistent"
    exit 1
  end
end

def calc_gps_column_num(gpsTimeString)
  for i in 0..999
    if gpsTimeString[i]==gpsTimeString[i+1] then
      gps_column_num=i-1
      break
    end
  end
  return gps_column_num
end

def calc_fpga_clock(columnNum, unixTime, timeTag)
  calcClock=0
  for i in 0..columnNum-2
    deltaTimeTag=timeTag[i+1].to_f-timeTag[i].to_f
    deltaUnixTime=(deltaTimeTag/1.0e8).round
    calcClock+=(deltaTimeTag/deltaUnixTime)
  end
  clock=calcClock/(columnNum-1)
  return clock
end

def energy_calibration(enabled_channel, adcIndex, phaMax, phaMin, energy_K, energy_Tl, peak_K, peak_Tl)
  if enabled_channel.include?(adcIndex)==true then
    index=enabled_channel.index(adcIndex)
    return energy_K+(energy_Tl-energy_K)*((phaMax-phaMin)-peak_K[index])/(peak_Tl[index]-peak_K[index])
  else
    return 0.0
  end
end

def gps_verification(gpsTimeString)
  parse=gpsTimeString[0].split("\s")
  if (parse[0]=="GP")||(parse[0]=="NULL") then
    return false
  else
    return true
  end
end

def calc_first_unixTime(unixTime, gpsTimeString)
  utcLag=3600.0*9.0
  switch=false
  for i in -600..600
    unixTimeUtc=Time.at(unixTime[0].to_f-utcLag+i.to_f).strftime("%H%M%S")
    if gpsTimeString[0][8..13]==unixTimeUtc then
      unixTimeFirst=unixTime[0].to_f+i.to_f+1.0
      switch=true
      break
    end
  end
  if switch==true then
    return unixTimeFirst
  else
    return false
  end
end

def gps_time_calibration(output, eventTimeTag, firstUnixTime, gpsUnixTime, gpsTimeTag, gpsNum, gpsIndex, clock)
  gpsIndexLength=gpsIndex.length-1
  if gpsIndexLength<gpsNum-1 then
    gpsTimeTagFirst=(gpsTimeTag[0].to_i)&0xFFFFFFFFFF
    gpsTimeTagNow=(gpsTimeTag[gpsIndexLength].to_i)&0xFFFFFFFFFF
    gpsTimeTagNext=(gpsTimeTag[gpsIndexLength+1].to_i)&0xFFFFFFFFFF
    deltaGpsTimeTagNextNow=gpsTimeTagNext-gpsTimeTagNow
    if deltaGpsTimeTagNextNow<0 then
      deltaGpsTimeTagNextNow+=2**40
    end
    deltaGpsTimeNextNow=((deltaGpsTimeTagNextNow.to_f)/1.0e8).round()
    clock=deltaGpsTimeTagNextNow.to_f/(deltaGpsTimeNextNow).to_f

    deltaGpsTimeTag=gpsTimeTagNow-gpsTimeTagFirst
    if deltaGpsTimeTag.to_f/clock<-60.0 then
      deltaGpsTimeTag+=2**40
    end
    
    unixTimeNow=firstUnixTime+((deltaGpsTimeTag.to_f/clock).round()).to_f
    unixTimeNext=unixTimeNow+deltaGpsTimeNextNow.to_f
    deltaTime=(eventTimeTag-gpsTimeTagNow).to_f/clock
    if (deltaTime>3600.0)  then
      deltaTime=(eventTimeTag-gpsTimeTagNow-2**40).to_f/clock
    elsif (deltaTime<-3600.0)  then
      deltaTime=(eventTimeTag-gpsTimeTagNow+2**40).to_f/clock
    end
    deltaTimeNext=(eventTimeTag-gpsTimeTagNext).to_f/clock
    if (deltaTimeNext>3600.0)  then
      deltaTimeNext=(eventTimeTag-gpsTimeTagNext-2**40).to_f/clock
    elsif (deltaTimeNext<-3600.0)  then
      deltaTimeNext=(eventTimeTag-gpsTimeTagNext+2**40).to_f/clock
    end
    if deltaTimeNext>0.0 then
      gpsIndex << 0
    end
    output[0]=unixTimeNow+deltaTime
    output[1]=deltaTime-(deltaTime.floor).to_f
  else
    gpsTimeTagFirst=(gpsTimeTag[0].to_i)&0xFFFFFFFFFF
    gpsTimeTagNow=(gpsTimeTag[gpsIndexLength].to_i)&0xFFFFFFFFFF
    gpsTimeTagPast=(gpsTimeTag[gpsIndexLength-1].to_i)&0xFFFFFFFFFF
    deltaGpsTimeTagNowPast=gpsTimeTagNow-gpsTimeTagPast
    if deltaGpsTimeTagNowPast<0 then
      deltaGpsTimeTagNowPast+=2**40
    end
    deltaGpsTimeNowPast=((deltaGpsTimeTagNowPast.to_f)/1.0e8).round()
    clock=deltaGpsTimeTagNowPast.to_f/(deltaGpsTimeNowPast).to_f

    deltaGpsTimeTag=gpsTimeTagNow-gpsTimeTagFirst
    if deltaGpsTimeTag.to_f/clock<-60.0 then
      deltaGpsTimeTag+=2**40
    end
    
    unixTimeNow=firstUnixTime+((deltaGpsTimeTag.to_f/clock).round()).to_f
    deltaTime=(eventTimeTag-gpsTimeTagNow).to_f/clock
    if (deltaTime>3600.0)  then
      deltaTime=(eventTimeTag-gpsTimeTagNow-2**40).to_f/clock
    elsif (deltaTime<-3600.0)  then
      deltaTime=(eventTimeTag-gpsTimeTagNow+2**40).to_f/clock
    end
    output[0]=unixTimeNow+deltaTime
    output[1]=deltaTime-(deltaTime.floor).to_f
  end
end    

def non_gps_time_calibration(output, eventTimeTag, gpsUnixTime, gpsTimeTag, clock)
  firstUnixTime=gpsUnixTime[0].to_f
  gpsTimeTagNow=(gpsTimeTag[0].to_i)&0xFFFFFFFFFF
  deltaTime=(eventTimeTag-gpsTimeTagNow).to_f/clock
  if (deltaTime>3600.0)  then
    deltaTime=(eventTimeTag-gpsTimeTagNow-2**40).to_f/clock
  elsif (deltaTime<-3600.0)  then
    deltaTime=(eventTimeTag-gpsTimeTagNow+2**40).to_f/clock
  end
  output[0]=firstUnixTime+deltaTime
  output[1]=deltaTime-(deltaTime.floor).to_f
end

def write_header(eventHDU, channel, enabled_channel, peak_K, peak_Tl, bin_width)
  if enabled_channel.include?(channel)==true then
    index=enabled_channel.index(channel)
    eventHDU.addHeader("CAL_CH#{channel.to_s}", "YES", "Channel #{channel.to_s} are calibrated or not.")
    eventHDU.addHeader("LNK_CH#{channel.to_s}", sprintf("%.2f", peak_K[index]), "40K peak mean in Channel #{channel.to_s} (adc channel)")
    eventHDU.addHeader("LNTL_CH#{channel.to_s}", sprintf("%.2f", peak_Tl[index]), "208Tl peak mean in Channel #{channel.to_s} (adc channel)")
    eventHDU.addHeader("BINW_CH#{channel.to_s}", sprintf("%.2f", bin_width[index]), "Bin width of Channel #{channel.to_s} in Energy (keV)")
  else
    eventHDU.addHeader("CAL_CH#{channel.to_s}", "NO", "Channel #{channel.to_s} are calibrated or not.")
    eventHDU.addHeader("LNK_CH#{channel.to_s}", "NONE", "40K peak mean in Channel #{channel.to_s} (adc channel)")
    eventHDU.addHeader("LNTL_CH#{channel.to_s}", "NONE", "208Tl peak mean in Channel #{channel.to_s} (adc channel)")
    eventHDU.addHeader("BINW_CH#{channel.to_s}", "NONE", "Bin width of Channel #{channel.to_s} in Energy (keV)")
  end
end

#============================================
# Define Array
#============================================

enabled_channel=Array.new
peak_data_file=Array.new
peak_data=Array.new
peak_data_line=Array.new
fits_name=Array.new
peak_K=Array.new
peak_Tl=Array.new
bin_width=Array.new
time_output=Array.new

#============================================
# Main
#============================================

cal_info.each_with_index do |switch, i|
  check_file_exist(fitsIndex, switch, i)
  peak_file_record(fitsIndex, switch, i, enabled_channel, peak_data_file)
end

input_channel_num=enabled_channel.length

fitsFolderLv1="#{fitsIndex}_fits_lv1"
fitsFolderLv2="#{fitsIndex}_fits_lv2"
if File.exists?(fitsFolderLv2)==false then
  `mkdir #{fitsFolderLv2}`
end

enabled_channel.each_with_index do |channel, i|
  peak_data[i]=File.open(peak_data_file[i], "r")
  peak_data_line[i]=peak_data[i].readlines()
end

for i in 0..peak_data_line[0].length-1
  for j in 0..input_channel_num-1
    extract_peak_file(peak_data_line, fits_name, peak_K, peak_Tl, i, j)
    bin_width[j]=(energy_Tl-energy_K)/(peak_Tl[j]-peak_K[j])
    verify_peak_file(fits_name, j)
  end
  newFitsFile="#{fitsFolderLv2}/#{fits_name[0]}"
  inputFitsFile="#{fitsFolderLv1}/#{fits_name[0]}"
  puts newFitsFile
  fits=FitsFile.new(inputFitsFile)
  eventHDU=fits.hdu("EVENTS")
  timeHDU=fits.hdu("GPS")
  eventColumnNum=eventHDU.nRows
  phaMax=eventHDU["phaMax"]
  phaMin=eventHDU["phaMin"]
  adcIndex=eventHDU["boardIndexAndChannel"]
  eventTimeTag=eventHDU["timeTag"]
  unixTime=timeHDU["unixTime"]
  gpsTimeTag=timeHDU["fpgaTimeTag"]
  gpsTimeString=timeHDU["gpsTime"]
  gpsColumnNum=calc_gps_column_num(gpsTimeTag)

  eventUnixTime=FitsTableColumn.new
  eventUnixTime.initializeWithNameAndFormat("unixTime","D")
  eventUnixTime.setUnit("sec")
  eventPreciseTime=FitsTableColumn.new
  eventPreciseTime.initializeWithNameAndFormat("preciseTime","E")
  eventPreciseTime.setUnit("sec")
  energy=FitsTableColumn.new
  energy.initializeWithNameAndFormat("energy","E")
  energy.setUnit("keV")
  eventUnixTime.resize(eventColumnNum)
  eventPreciseTime.resize(eventColumnNum)
  energy.resize(eventColumnNum)
  eventHDU.appendColumn(eventUnixTime)
  eventHDU.appendColumn(eventPreciseTime)
  eventHDU.appendColumn(energy)
  unixTimeWrite=eventHDU["unixTime"]
  preciseTimeWrite=eventHDU["preciseTime"]
  energyWrite=eventHDU["energy"]
  gps_index=Array.new(1, 0)

  gps_status=gps_verification(gpsTimeString)
  if gpsColumnNum<5 then
    gps_status=false
  end
  
  if gps_status==true then
    fpga_clock=calc_fpga_clock(gpsColumnNum, unixTime, gpsTimeTag)
    first_unixTime=calc_first_unixTime(unixTime, gpsTimeString)
    if first_unixTime==false then
      fpga_clock=1.0e8
      gps_status=false
    end
  else
    fpga_clock=1.0e8
  end

  if gps_status==true then
    puts "GPS signals are used for timing calibration."
  end
  
  for n in 0..eventColumnNum-1
    energyWrite[n]=energy_calibration(enabled_channel, adcIndex[n].to_i, phaMax[n].to_f, phaMin[n].to_f, energy_K, energy_Tl, peak_K, peak_Tl)
    if gps_status==true then
      gps_time_calibration(time_output, eventTimeTag[n].to_i, first_unixTime, unixTime, gpsTimeTag, gpsColumnNum, gps_index, fpga_clock)
    else
      non_gps_time_calibration(time_output, eventTimeTag[n].to_i, unixTime, gpsTimeTag, fpga_clock)
    end
    unixTimeWrite[n]=time_output[0]
    preciseTimeWrite[n]=time_output[1]
  end 
  
  eventHDU.addHeader("PIPELINE", "level-2", "present pipeline process level")
  eventHDU.addHeader("PL2_DATE", "#{date}", "pipeline level-2 processing date")
  eventHDU.addHeader("PL2_VER", "#{pipeline_version}", "pipeline level-2 version")
  if gps_status==true then
    eventHDU.addHeader("TIME_CAL", "2", "method of time calibration")
  else
    eventHDU.addHeader("TIME_CAL", "1", "method of time calibration")
  end
  eventHDU.appendComment("TIME_CAL: method of time calibration 0:from file name, 1:from UNIXTIME, 2:from GPS time")

  for n in 0..3
    write_header(eventHDU, n, enabled_channel, peak_K, peak_Tl, bin_width)
  end
  
  fits.saveAs(newFitsFile)
end
