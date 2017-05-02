#!/usr/bin/env ruby
require "RubyFits"
require "RubyROOT"
require "date"
require "Time"
include Math
include Root
include RootApp

if ARGV[6]==nil then
  puts "Usage: ruby makeLongLightCurveDate.rb <start date> <end date> <adc channel> <bin size (sec)> <lower energy> <upper energy> <output directory>"
  puts "Example: ruby makeLongLightCurveDate.rb 20161001 20170331 0 1 3.0 30.0 ./daily_lightcurve"
  exit 1
end

startDate=ARGV[0]
endDate=ARGV[1]
adcChannel=ARGV[2].to_i
binWidth=ARGV[3].to_f
energyLimitsLow=ARGV[4].to_f
energyLimitsHigh=ARGV[5].to_f
outputDir=ARGV[6]

if File.exists?(outputDir)==false then
  `mkdir -p #{outputDir}`
end

startDateObject=Date.strptime(startDate, "%Y%m%d")
index=0
while 1==1 do
  downloadDate=startDateObject+index
  dateString=downloadDate.strftime("%Y%m%d")
  downloadDate_yesterday=startDateObject+index-1
  dateStringYesterday=downloadDate_yesterday.strftime("%Y%m%d")
  downloadDate_tommorow=startDateObject+index+1
  dateStringTommorow=downloadDate_tommorow.strftime("%Y%m%d")
  
  puts dateString
  fitsListAddress="#{dateString}_fitsList.dat"
  if File.exists?(fitsListAddress)==true then
    `rm gitsListAddress`
  end
    
  if File.exists?("#{dateStringYesterday}_233*.fits.gz")==true then
    `ls #{dateStringYesterday}_233*.fits.gz > #{fitsListAddress}`
  elsif File.exists?("#{dateStringYesterday}_234*.fits.gz")==true then
    `ls #{dateStringYesterday}_234*.fits.gz > #{fitsListAddress}`
  elsif File.exists?("#{dateStringYesterday}_235*.fits.gz")==true then
    `ls #{dateStringYesterday}_235*.fits.gz > #{fitsListAddress}`
  end
  if File.exists?("#{dateString}*.fits.gz")==true then
    `ls #{dateString}*.fits.gz >> #{fitsListAddress}`
  end
  if File.exists?("#{dateStringTommorow}_000*.fits.gz")==true then
    `ls #{dateStringTommorow}_000*.fits.gz >> #{fitsListAddress}`
  elsif File.exists?("#{dateStringTommorow}_001*.fits.gz")==true then
    `ls #{dateStringTommorow}_001*.fits.gz >> #{fitsListAddress}`
  elsif File.exists?("#{dateStringTommorow}_002*.fits.gz")==true then
    `ls #{dateStringTommorow}_002*.fits.gz >> #{fitsListAddress}`
  end

  if File.exists?(fitsListAddress)==true then
    fitsList=File.open(fitsListAddress, "r")
    fitsFile=fitsList.readlines
    fitsFileNum=fitsFile.length-1
=begin
    fitsFirst=Fits::FitsFile.new(fitsFile[0].chomp!)
    startUnixTime=fitsFirst["EVENTS"]["unixTime"][0].to_f
    puts startUnixTime
    
    fitsLast=Fits::FitsFile.new(fitsFile[fitsFileNum].chomp!)
    fitsLastNRows=fitsLast["EVENTS"].getNRows()-1
    endUnixTime=fitsLast["EVENTS"]["unixTime"][fitsLastNRows].to_f
    puts endUnixTime
    
    observationDuration=endUnixTime-startUnixTime
    puts observationDuration
    binNum=(observationDuration/binWidth).to_i+1
    startTime=startUnixTime.to_f
    puts startTime.to_f
    puts binWidth*binNum.to_f
    endTime=startTime+binWidth*binNum.to_f
    
    puts endTime.to_f
=end
    startTime=(Time.parse("#{dateString}_000000").to_i).to_f
    endTime=startTime+3600.0
    binNum=(3600.0/binWidth).to_i
    
    hist=Root::TH1D.create("", "", binNum, startTime, endTime)
    
    fitsFile.each_with_index do |fitsName, index|
      fits=Fits::FitsFile.new(fitsName)
      eventHDU=fits["EVENTS"]
      adcIndex=eventHDU["boardIndexAndChannel"]
      eventNum=eventHDU.getNRows()-1
      energyWidth_header="BINW_CH#{adcChannel}"
      energyWidth=eventHDU.header(energyWidth_header).to_f
      energyThreshold_header="ETH_CH#{adcChannel}"
      energyThreshold=eventHDU.header(energyThreshold_header).to_f/1000.0
      for i in 0..eventNum
        if adcIndex[i].to_i==adcChannel then
          unixTime=eventHDU["unixTime"][i].to_f
          energyRaw=eventHDU["energy"][i].to_f
          energy=(energyRaw+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
          if (energy>=energyLimitsLow)&&(energy<energyLimitsHigh)&&(energy>=energyThreshold) then
            hist.Fill(unixTime)
          end
        end
      end
      message="#{(index+1).to_s}/#{(fitsFileNum+1).to_s} completed"
      puts message
    end
    
    c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
    hist.SetTitle("")
    scaleFactor=1.0/binWidth
    hist.Sumw2()
    hist.Scale(scaleFactor)
    hist.GetXaxis().SetTitle("Date (JST)")
    hist.GetXaxis().SetTitleOffset(1.2)
    hist.GetXaxis().CenterTitle()
    hist.GetYaxis().SetTitle("Count Rate (count/sec)")
    hist.GetYaxis().CenterTitle()
    hist.GetYaxis().SetTitleOffset(1.35)
#    gStyle.SetTimeOffset(-788918400)
    gStyle.SetNdivisions(505)
    hist.SetStats(0)
    hist.GetXaxis().SetTimeDisplay(1)
    hist.GetXaxis().SetTimeFormat("%H:%M")
    hist.Draw("e1")
    c0.Update()
    outputFile="#{outputDir}/#{dateString}_lightcurve.png"
    c0.SaveAs(outputFile)
  end
  `rm #{fitsListAddress}`
  index+=1
  if downloadDate.strftime("%Y%m%d")==endDate then
    break
  end
end
