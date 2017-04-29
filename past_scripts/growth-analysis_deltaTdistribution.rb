#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if (ARGV[3]==nil) then
  puts "Usage: ruby growth-analysis_deltaTdistribution.rb <input file> <channel> <event start> <event end>"
  exit 1
end

energyMin=0.8
energyMax=14.5
binNum=40

eventFitsFile=ARGV[0]
adcChannel=ARGV[1].to_i
eventStart=ARGV[2].to_f
eventEnd=ARGV[3].to_f

fitsEvent=Fits::FitsFile.new(eventFitsFile)
eventHDU=fitsEvent["EVENTS"]
eventNum=eventHDU.getNRows()-1
adcIndex=eventHDU["boardIndexAndChannel"]
energyRaw=eventHDU["energy"]
timeTag=eventHDU["timeTag"]
unixTime=eventHDU["unixTime"]
unixTimeStart=eventHDU["unixTime"][0].to_f
unixTimeLast=eventHDU["unixTime"][eventNum].to_f
observationTime=unixTimeLast-unixTimeStart
energyWidth_header="BINW_CH#{adcChannel}"
lowEnergy_header="ETH_CH#{adcChannel}"
energyWidth=eventHDU.header(energyWidth_header).to_f
lowEnergy=eventHDU.header(lowEnergy_header).to_f/1000.0

hist=Root::TH1D.create("hist", "hist", 300, 0.0, 0.1)

for i in 1..eventNum
  if adcIndex[i].to_i==adcChannel then
    triggerTime=unixTime[i].to_f-unixTimeStart
    #energy=(energyRaw[i].to_f+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
    if (triggerTime>=eventStart)&&(triggerTime<=eventEnd) then
      deltaTimeTag=timeTag[i].to_i-timeTag[i-1].to_i
      if deltaTimeTag>=0 then
        deltaTime=deltaTimeTag.to_f/1.0e8
        hist.Fill(deltaTime)
      elsif
        deltaTime=(2**40+deltaTimeTag.to_f)/1.0e8
        hist.Fill(deltaTime)
      end
    end
  end
end

hist.SetTitle("")
hist.GetXaxis.SetTitle("")
hist.GetXaxis.SetTitleOffset(1.2)
hist.GetXaxis.CenterTitle
hist.GetYaxis.SetTitle("")
hist.GetYaxis.CenterTitle
hist.GetYaxis.SetTitleOffset(1.35)
hist.GetYaxis.SetRangeUser(0.5, 1e4)
hist.GetXaxis.SetRangeUser(0, 0.1)
c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
hist.Draw()
c0.SetLogy()
c0.Update

run_app()
