#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if ARGV[2]==nil then
  puts "Usage: ruby growth-analysis_trigerCount_lightcurve.rb <fits file> <adc channel> <bin size (sec)>"
  exit 1
end

fitsFileAddress=ARGV[0]
adcChannel=ARGV[1].to_i
binWidth=ARGV[2].to_f

fits=Fits::FitsFile.new(fitsFileAddress)
eventHDU=fits["EVENTS"]
adcIndex=eventHDU["boardIndexAndChannel"]
triggerCountCh=eventHDU["triggerCount"]
unixTime=eventHDU["unixTime"]
eventNum=eventHDU.getNRows()-1

obsStartTime=unixTime[0].to_f
obsEndTime=unixTime[eventNum].to_f
duration=obsEndTime-obsStartTime

binNum=(duration/binWidth).to_i
binStart=obsStartTime
binEnd=obsStartTime+binWidth*binNum.to_f

hist=Root::TH1D.create("", "", binNum, binStart, binEnd)

channelIndex=0
triggerCount=Array.new
unixTimeChannel=Array.new
for i in 0..eventNum-1
  if adcChannel==adcIndex[i].to_i then
    triggerCount[channelIndex]=triggerCountCh[i].to_i
    unixTimeChannel[channelIndex]=unixTime[i].to_f
    channelIndex+=1
  end
end

for i in 0..channelIndex-2
  if triggerCount[i+1]<triggerCount[i] then
    deltaTriggerCount=triggerCount[i+1]-triggerCount[i]+2**16
  else
    deltaTriggerCount=triggerCount[i+1]-triggerCount[i]
  end
  (deltaTriggerCount-1).times do
    hist.Fill(unixTimeChannel[i].to_f)
  end
end

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
hist.SetTitle("")
hist.GetXaxis.SetTitle("Second")
hist.GetXaxis.SetTitleOffset(1.2)
hist.GetXaxis.CenterTitle
hist.GetXaxis.SetRangeUser(binStart, binEnd)
hist.GetYaxis.SetTitle("Abandoned Event")
hist.GetYaxis.CenterTitle
hist.GetYaxis.SetTitleOffset(1.35)
hist.GetYaxis.SetRangeUser(0.5, 200.0)
hist.SetStats(0)
gStyle.SetTimeOffset(-788918400)
gStyle.SetNdivisions(505)
hist.GetXaxis().SetTimeDisplay(1)
hist.GetXaxis().SetTimeFormat("%m/%d %H:%M")
hist.GetXaxis().SetTimeFormat("%H:%M:%S")

hist.Draw("")
c0.SetLogy()
c0.Update()
run_app()

#hist.GetYaxis.SetRangeUser(0, 70)
#
#output=File.open("longLightCurveLaw.dat", "w+")
#i=0
#countSec.each do
#  line=time[i].to_s+"\t"+errorTime[i].to_s+"\t"+countSec[i].to_s+"\t"+errorCountSec[i].to_s+"\n"
#  output.write(line)
#  i+=1
#end

