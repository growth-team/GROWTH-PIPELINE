#!/usr/bin/env ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if ARGV[4]==nil then
  puts "Usage: ruby makeLongLightCurve.rb <fits file list> <adc channel> <bin size (sec)> <lower channel> <upper channel> <output file>"
  exit 1
end

fitsListAddress=ARGV[0]
adcChannel=ARGV[1].to_i
binWidth=ARGV[2].to_f
energyLimitsLow=ARGV[3].to_f
energyLimitsHigh=ARGV[4].to_f

#observationTime=1800.0
#fpgaClock=1.0e8
#binNum=(observationTime/binWidth).to_i+1

fitsList=File.open(fitsListAddress, "r")
fitsFile=fitsList.readlines
fitsFileNum=fitsFile.length-1

fitsFirst=Fits::FitsFile.new(fitsFile[0].chomp!)
startUnixTime=fitsFirst["EVENTS"]["unixTime"][0]

fitsLast=Fits::FitsFile.new(fitsFile[fitsFileNum].chomp!)
fitsLastNRows=fitsLast["EVENTS"].getNRows()-1
endUnixTime=fitsLast["EVENTS"]["unixTime"][fitsLastNRows]

observationDuration=endUnixTime-startUnixTime
binNum=(observationDuration/binWidth).to_i+1
startTime=startUnixTime
endTime=startUnixTime+binWidth*binNum.to_f

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
hist.GetXaxis.SetTitle("Date (JST)")
hist.GetXaxis.SetTitleOffset(1.2)
hist.GetXaxis.CenterTitle
hist.GetYaxis.SetTitle("Count Rate (count/sec)")
hist.GetYaxis.CenterTitle
hist.GetYaxis.SetTitleOffset(1.35)
gStyle.SetTimeOffset(-788918400)
gStyle.SetNdivisions(505)
hist.SetStats(0)
hist.GetXaxis().SetTimeDisplay(1)
hist.GetXaxis().SetTimeFormat("%H:%M")
#hist.SetLineColor(2)
hist.Draw("e1")
c0.Update()

if ARGV[5]!=nil then
  outputFile=ARGV[5]
  Root::TFile.open(outputFile, "recreate") do |output|
    hist.Write("hist")
  end
  #  c0.SaveAs(outputFile)
else
  run_app()  
end
#hist.GetYaxis.SetRangeUser(0, 70)
#hist.GetXaxis.SetRangeUser(0, 80000)
#output=File.open("longLightCurveLaw.dat", "w+")
#i=0
#countSec.each do
#  line=time[i].to_s+"\t"+errorTime[i].to_s+"\t"+countSec[i].to_s+"\t"+errorCountSec[i].to_s+"\n"
#  output.write(line)
#  i+=1
#end

