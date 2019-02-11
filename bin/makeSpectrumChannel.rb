#!/usr/bin/env ruby

require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if (ARGV[1]==nil) then
  puts "Usage: ruby makeSpectrum.rb <input file> <channel> <rebin>"
  exit 1
end
  
fitsFile=ARGV[0]
adcChannel=ARGV[1].to_i
rebin=ARGV[2].to_i
fits=Fits::FitsFile.new(fitsFile)
eventHDU=fits["EVENTS"]
adcIndex=eventHDU["boardIndexAndChannel"]
eventNum=eventHDU.getNRows()

binNum=4096/rebin
hist=Root::TH1F.create("hist", "hist", binNum, -0.5, 4095.5)

for i in 0..(eventNum.to_i-1)
  if adcIndex[i].to_i==adcChannel then
      hist.Fill(eventHDU["phaMax"][i].to_i)
  end
end
c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
hist.SetTitle("Spectrum")
hist.GetXaxis.SetTitle("Channel")
hist.GetXaxis.SetTitleOffset(1.2)
hist.GetXaxis.CenterTitle
hist.GetYaxis.SetTitle("Count")
hist.GetYaxis.CenterTitle
hist.GetYaxis.SetTitleOffset(1.35)
#hist.GetYaxis.SetRangeUser(0.5, 100000)
#hist.GetXaxis.SetRangeUser(512, 1024)
hist.Draw()
c0.SetLogy()
c0.Update
run_app()
