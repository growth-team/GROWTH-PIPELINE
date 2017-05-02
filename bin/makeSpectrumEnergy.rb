#!/usr/bin/env ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if (ARGV[1]==nil) then
  puts "Usage: ruby makeSpectrum.rb <input file> <channel>"
  exit 1
end

energyMax=15.0
binNum=500

fitsFile=ARGV[0]
adcChannel=ARGV[1].to_i
fits=Fits::FitsFile.new(fitsFile)
eventHDU=fits["EVENTS"]
eventNum=eventHDU.getNRows()-1
adcIndex=eventHDU["boardIndexAndChannel"]
energyRaw=eventHDU["energy"]
unixTimeStart=eventHDU["unixTime"][0].to_f
unixTimeLast=eventHDU["unixTime"][eventNum].to_f
observationTime=unixTimeLast-unixTimeStart
energyWidth_header="BINW_CH#{adcChannel}"
lowEnergy_header="ETH_CH#{adcChannel}"
energyWidth=eventHDU.header(energyWidth_header).to_f
lowEnergy=eventHDU.header(lowEnergy_header).to_f/1000.0

hist=Root::TH1D.create("hist", "hist", binNum, 0, energyMax)

for i in 0..eventNum
  if adcIndex[i].to_i==adcChannel then
    energy=(energyRaw[i].to_f+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
    if energy>lowEnergy then
      hist.Fill(energy)
    end
  end
end

scaleFactor=binNum.to_f/(observationTime*energyMax)
hist.Scale(scaleFactor)
c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
hist.SetTitle("")
hist.GetXaxis.SetTitle("Energy (MeV)")
hist.GetXaxis.SetTitleOffset(1.2)
hist.GetXaxis.CenterTitle
hist.GetYaxis.SetTitle("Count s^{-1} MeV^{-1}")
hist.GetYaxis.CenterTitle
hist.GetYaxis.SetTitleOffset(1.35)
hist.GetYaxis.SetRangeUser(0.005, 1000)
hist.GetXaxis.SetRangeUser(0, 15)
hist.SetStats(0)
hist.Draw()
c0.SetLogy()
c0.Update
run_app()
