#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if (ARGV[1]==nil) then
  puts "Usage: ruby growth-analysis_spectrum.rb <input file> <channel>"
  exit 1
end

fitsFile=ARGV[0]
adcChannel=ARGV[1].to_i

fitsEvent=Fits::FitsFile.new(fitsFile)
eventHDU=fitsEvent["EVENTS"]
eventNum=eventHDU.getNRows()-1
adcIndex=eventHDU["boardIndexAndChannel"]
triggerCount=eventHDU["triggerCount"]

deltaTriggerCount=Root::TH1D.create("deltaTriggerCount", "deltaTriggerCount", 1001, -0.5, 1000.5)

for i in 1..eventNum
  if adcIndex[i].to_i==adcChannel then
    if triggerCount[i].to_i<triggerCount[i-1].to_i then
      deltaTriggerCount.Fill(triggerCount[i].to_i-triggerCount[i-1].to_i+2**16)
    else
      deltaTriggerCount.Fill(triggerCount[i].to_i-triggerCount[i-1].to_i)
    end
  end
end

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
deltaTriggerCount.SetTitle("")
deltaTriggerCount.GetXaxis().SetTitle("Delta Trigger Count")
deltaTriggerCount.GetXaxis().SetTitleOffset(1.15)
deltaTriggerCount.GetXaxis().CenterTitle()
deltaTriggerCount.GetYaxis().SetTitle("Count")
deltaTriggerCount.GetYaxis().CenterTitle()
deltaTriggerCount.GetYaxis().SetTitleOffset(1.2)
deltaTriggerCount.GetYaxis().SetRangeUser(0.5, 1e6)
#deltaTriggerCount.GetXaxis().SetRangeUser(0, 10)
deltaTriggerCount.GetXaxis().SetTitleSize(0.04)
deltaTriggerCount.GetYaxis().SetTitleSize(0.04)
deltaTriggerCount.GetXaxis().SetLabelSize(0.04)
deltaTriggerCount.GetYaxis().SetLabelSize(0.04)
deltaTriggerCount.SetStats(0)
deltaTriggerCount.Draw()
c0.SetLogy()
c0.Update
run_app()
