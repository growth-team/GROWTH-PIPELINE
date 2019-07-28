#!/usr/bin/env ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

fpgaClock=1e8

if (ARGV[0]==nil)||(ARGV[1]==nil)||(ARGV[2]==nil) then
  puts "Usage: ruby makeNormalLightCutve2016.rb <input file> <channel> <center time (min)>"
  exit -1
end

fitsFile=ARGV[0]
channel=ARGV[1].to_i
centerTime=60.0*ARGV[2].to_f
widthTime=10.0

fits=Fits::FitsFile.new(fitsFile)
primaryHDU=fits["Primary"]
eventHDU=fits["EVENTS"]
eventNum=(eventHDU.getNRows()).to_i-1
timeTagStart=eventHDU["timeTag"][0].to_i
timeTagEnd=eventHDU["timeTag"][eventNum].to_i

# Calulate observation duration
timeTagPast=timeTagStart
counterLoop=0
for i in 0..(eventNum.to_i)
  timeTag=eventHDU["timeTag"][i].to_i
  eventChannel=eventHDU["boardIndexAndChannel"][i].to_i
  if (channel==eventChannel) then
    if (timeTag<timeTagPast) then
      counterLoop+=1
    end
    timeTagPast=timeTag
  end
end

observationTime=((timeTagEnd-timeTagStart+(2**40)*counterLoop)/fpgaClock).round(1)
obsTimeString=observationTime.to_s+"sec observation"
puts obsTimeString

# Fill histogram
phaMaxArray=Array.new
phaMinArray=Array.new
time=Array.new
timeTagPast=timeTagStart
counterLoop=0
for i in 0..eventNum
  timeTag=eventHDU["timeTag"][i].to_i
  phaMax=eventHDU["phaMax"][i].to_i
  phaMin=eventHDU["phaMin"][i].to_i
  if channel==eventHDU["boardIndexAndChannel"][i].to_i
    if (timeTag>=timeTagPast) then
      second=(timeTag-timeTagStart+(2**40)*counterLoop).to_f/fpgaClock.to_f
      if (second>=centerTime-widthTime)&&(second<=centerTime+widthTime) then
        time << second-centerTime
        phaMaxArray << phaMax.to_f
        phaMinArray << phaMin.to_f
      end
      timeTagPast=timeTag
    elsif (timeTag<timeTagPast) then
      counterLoop+=1
      second=(timeTag-timeTagStart+(2**40)*counterLoop).to_f/fpgaClock.to_f
      if (second>=centerTime-widthTime)&&(second<=centerTime+widthTime) then
        time << second-centerTime
        phaMaxArray << phaMax.to_f
        phaMinArray << phaMin.to_f
      end
      timeTagPast=timeTag
    end
  end
end

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
hist=Root::TH1F.create("h0", "h0", 1000, -1.0*widthTime, widthTime)

hist.SetTitle("")
hist.GetXaxis().SetTitle("Time (second)")
hist.GetXaxis().SetTitleOffset(1.2)
hist.GetXaxis().CenterTitle
hist.GetYaxis().SetTitle("ADC")
hist.GetYaxis().CenterTitle
hist.GetYaxis().SetTitleOffset(1.35)
hist.GetYaxis().SetRangeUser(0, 4096)
hist.SetStats(0)
hist.Draw("")
histMax=Root::TGraphErrors.create(time,phaMaxArray)
histMin=Root::TGraphErrors.create(time,phaMinArray)
histMax.SetMarkerStyle(6)
histMin.SetMarkerStyle(6)
histMin.SetMarkerColor(2)
histMax.Draw("p")
histMin.Draw("p")
c0.Update()
run_app
