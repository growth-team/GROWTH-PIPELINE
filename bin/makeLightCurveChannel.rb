#!/usr/bin/env ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if ARGV[4]==nil then
  puts "Usage: ruby makeLightCurveEnergy.rb <fits file> <adc channel> <bin size (sec)> <lower channel> <upper channel>"
  exit 1
end

fitsFileAddress=ARGV[0]
adcChannel=ARGV[1].to_i
binWidth=ARGV[2].to_f
energyLimitsLow=ARGV[3].to_i
energyLimitsHigh=ARGV[4].to_i

fits=Fits::FitsFile.new(fitsFileAddress)
eventHDU=fits["EVENTS"]
adcIndex=eventHDU["boardIndexAndChannel"]
phaMax=eventHDU["phaMax"]
unixTime=eventHDU["unixTime"]
eventNum=eventHDU.getNRows()-1

obsStartTime=unixTime[0].to_f
obsEndTime=unixTime[eventNum].to_f
observationTime=obsEndTime-obsStartTime
binNum=(observationTime/binWidth).to_i

binStart=obsStartTime
binEnd=binStart+binWidth*binNum.to_f

hist=Root::TH1D.create("", "", binNum, binStart, binEnd)

for i in 0..eventNum
  if (adcChannel==adcIndex[i].to_i)&&(unixTime[i].to_f>=binStart)&&(unixTime[i].to_f<=binEnd)&&(phaMax[i].to_i>=energyLimitsLow)&&(phaMax[i].to_i<energyLimitsHigh) then
    hist.Fill(unixTime[i].to_f)
  end
end

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
scaleFactor=1.0/binWidth
hist.Sumw2()
hist.Scale(scaleFactor)
hist.SetTitle("Count Rate")
hist.GetXaxis.SetTitle("Date (JST)")
hist.GetXaxis.SetTitleOffset(1.2)
hist.GetXaxis.CenterTitle
hist.GetXaxis.SetRangeUser(binStart, binEnd)
hist.GetYaxis.SetTitle("Count Rate (count/sec)")
hist.GetYaxis.CenterTitle
hist.GetYaxis.SetTitleOffset(1.35)
hist.SetStats(0)
gStyle.SetTimeOffset(-788918400)
gStyle.SetNdivisions(505)
hist.GetXaxis().SetTimeDisplay(1)
hist.GetXaxis().SetTimeFormat("%H:%M:%S")

hist.Draw("e")
c0.Update()
run_app()
