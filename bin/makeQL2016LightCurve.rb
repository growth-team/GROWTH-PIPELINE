#!/usr/bin/env ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

fpgaClock=1e8

if (ARGV[0]==nil)||(ARGV[1]==nil)||(ARGV[2]==nil)||(ARGV[3]==nil)||(ARGV[4]==nil) then
  puts "Usage: ruby makeNormalLightCutve2016.rb <input file> <channel> <bin width (sec)> <low channel> <high channel>"
  exit -1
end

fitsFile=ARGV[0]
channel=ARGV[1].to_i
binWidth=ARGV[2].to_f
phaLimitsLow=ARGV[3].to_i
phaLimitsUp=ARGV[4].to_i

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
puts "#{observationTime} sec observation"

# Fill histogram
binNum=(observationTime/binWidth).to_i+1
binStart=0.0
binEnd=binWidth*binNum.to_f/60.0
hist=Root::TH1F.create("h0", "h0", binNum, binStart, binEnd)

timeTagPast=timeTagStart
counterLoop=0

for i in 0..eventNum
  timeTag=eventHDU["timeTag"][i].to_i
  phaMax=eventHDU["phaMax"][i].to_i
  if channel==eventHDU["boardIndexAndChannel"][i].to_i
    if (timeTag>=timeTagPast)&&(phaMax>=phaLimitsLow)&&(phaMax<phaLimitsUp) then
      second=(timeTag-timeTagStart+(2**40)*counterLoop).to_f/fpgaClock.to_f
      hist.Fill(second/60.0)
      timeTagPast=timeTag
    elsif (timeTag<timeTagPast)&&(phaMax>=phaLimitsLow)&&(phaMax<phaLimitsUp) then
      counterLoop+=1
      second=(timeTag-timeTagStart+(2**40)*counterLoop).to_f/fpgaClock.to_f
      hist.Fill(second/60.0)
      timeTagPast=timeTag
    end
  end
end
c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
hist.Scale(1.0/binWidth)
hist.SetTitle("Count Rate")
hist.GetXaxis().SetTitle("Time (Second)")
hist.GetXaxis().SetTitleOffset(1.2)
hist.GetXaxis().CenterTitle()
hist.GetYaxis().SetTitle("Count Rate (count/sec)")
hist.GetYaxis().CenterTitle()
hist.GetYaxis().SetTitleOffset(1.35)
hist.SetStats(0)
hist.Draw("e")
c0.Update()
run_app
