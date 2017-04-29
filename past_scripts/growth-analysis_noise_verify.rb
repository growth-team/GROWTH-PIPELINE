#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if ARGV[0]==nil then
  puts "Usage: ruby growth-analysis_lightcurve_short.rb <fits file> <start time> <duration> <output file>"
  exit 1
end

fitsFileAddress=ARGV[0]
startTimeInput=ARGV[1].to_f
duration=ARGV[2].to_f
outputFile=ARGV[3]
  
fits=Fits::FitsFile.new(fitsFileAddress)
eventHDU=fits["EVENTS"]
phaMax=eventHDU["phaMax"]
maxDerivative=eventHDU["maxDerivative"]
unixTime=eventHDU["unixTime"]
eventNum=eventHDU.getNRows()-1

if startTimeInput==0 then
  startTime=unixTime[0].to_f
else
  startTime=startTimeInput
end
endTime=duration+startTime

hist=Root::TH2D.create("hist", "hist", 256, 2048, 4096, 200, 0, 200)

#hist=Root::TGraph.create(phaMaxX, maxDerivativeY)
#phaMaxX=Array.new
#maxDerivativeY=Array.new
#index=0
#if phaMax[i].to_f<3800 then
#phaMaxX[index]=phaMax[i].to_f
#maxDerivativeY[index]=maxDerivative[i].to_f
#index+=1

for i in 0..eventNum
  if (unixTime[i].to_f>startTime)&&(unixTime[i].to_f<endTime) then
    hist.Fill(phaMax[i].to_f, maxDerivative[i].to_f)
  end
end

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
hist.SetTitle("")
hist.GetXaxis().SetTitle("ADC Channel")
hist.GetXaxis().SetTitleOffset(1.2)
hist.GetXaxis().CenterTitle()
hist.GetXaxis().SetRangeUser(2048, 3900)
hist.GetYaxis().SetTitle("Max Derivative")
hist.GetYaxis().CenterTitle()
hist.GetYaxis().SetTitleOffset(1.35)
hist.SetStats(0)
hist.GetYaxis().SetRangeUser(0.0, 50.0)
hist.GetZaxis().SetRangeUser(0.5, 500.0)
hist.Draw("colz")
#hist.Draw("apl")
c0.SetLogz()
c0.Update()
c0.SaveAs(outputFile)
#run_app()
