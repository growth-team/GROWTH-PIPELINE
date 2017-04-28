#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if ARGV[6]==nil then
  puts "Usage: ruby scanEventSignificance.rb <fits file list> <adc channel> <bin size (sec)> <lower energy> <upper energy> <bgd mean> <bgd sigma> <output file>"
  exit 1
end

fitsListAddress=ARGV[0]
adcChannel=ARGV[1].to_i
binWidth=ARGV[2].to_f
energyLimitsLow=ARGV[3].to_f
energyLimitsHigh=ARGV[4].to_f
bgdMean=ARGV[5].to_f
bgdSigma=ARGV[6].to_f

outputAll=File.open("scanResult_all_significance.dat", "w")
outputSig=File.open("scanResult_high_significance.dat", "w")


  end
end
run_app()

fitsList=File.open(fitsListAddress, "r")
fitsFile=fitsList.readlines
fitsFileNum=fitsFile.length-1
fitsFile.each_with_index do |fitsName, index|
  fits=Fits::FitsFile.new(fitsName)
  eventHDU=fits["EVENTS"]
  adcIndex=eventHDU["boardIndexAndChannel"]
  unixTime=eventHDU["unixTime"]
  eventNum=eventHDU.getNRows()-1
  energyWidth_header="BINW_CH#{adcChannel}"
  energyWidth=eventHDU.header(energyWidth_header).to_f
  energyThreshold_header="ETH_CH#{adcChannel}"
  energyThreshold=eventHDU.header(energyThreshold_header).to_f/1000.0

  obsDuration=unixTime[eventNum].to_f-unixTime[0].to_f
  binNum=(obsDuration/binWidth).to_i
  startTime=unixTime[0].to_f
  endTime=startTime+binWidth*binNum.to_f
  
  hist=Root::TH1D.create("", "", binNum, startTime, endTime)

  for i in 0..eventNum
    if adcIndex[i].to_i==adcChannel then
      unixTimeEvent=unixTime[i].to_f
      energyRaw=eventHDU["energy"][i].to_f
      energy=(energyRaw+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
      if (energy>=energyLimitsLow)&&(energy<energyLimitsHigh)&&(energy>=energyThreshold)&&(unixTimeEvent>=startTime)&&(unixTimeEvent<=endTime) then
        hist.Fill(unixTimeEvent)
      end
    end
  end
  scaleFactor=1.0/binWidth
  hist.Scale(scaleFactor)

  maxSignificance=0
  for i in 1..binNum
    binCount=hist.GetBinContent(i)
    significance=(binCount-bgdMean)/bgdSigma
    if significance>maxSignificance then
      maxSignificance=significance
    end
    #if significance>3.0 then
    #  puts "#{fitsName} has #{significance.to_s} sigma bin."
    #end
  end
  message="#{(index+1).to_s}/#{(fitsFileNum+1).to_s} completed"
  puts message
  string=fitsName+"\t"+maxSignificance.to_s
  outputAll.puts(string)
  if maxSignificance>3.0 then
    outputSig.puts(string)
  end    
end
outputAll.close()
outputSig.close()

=begin
c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
countRateHist.Draw()
c0.Update()
if ARGV[5]!=nil then
  outputFile=ARGV[5]
  Root::TFile.open(outputFile, "recreate") do |output|
    countRateHist.Write("countRateHist")
  end
end
run_app()
=end
