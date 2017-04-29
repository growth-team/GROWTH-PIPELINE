#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if ARGV[2]==nil then
  puts "Usage: ruby makeLightCurveModified.rb <fits file> <adc channel> <bin size (sec)>"
  exit 1
end

fitsFileAddress=ARGV[0]
adcChannel=ARGV[1].to_i
binWidth=ARGV[2].to_f

fits=Fits::FitsFile.new(fitsFileAddress)
eventHDU=fits["EVENTS"]
adcIndex=eventHDU["boardIndexAndChannel"]
energyRaw=eventHDU["energy"]
unixTime=eventHDU["unixTime"]
triggerCount=eventHDU["triggerCount"]
energyWidth_header="BINW_CH#{adcChannel}"
energyWidth=eventHDU.header(energyWidth_header).to_f
eventNum=eventHDU.getNRows()-1

obsStartTime=unixTime[0].to_f
obsEndTime=unixTime[eventNum].to_f
observationTime=obsEndTime-obsStartTime
binNum=(observationTime/binWidth).to_i

binStart=obsStartTime
binEnd=binStart+binWidth*binNum.to_f

hist=Root::TH1D.create("", "", binNum, binStart, binEnd)

for i in 0..eventNum
  if (adcChannel==adcIndex[i].to_i)&&(unixTime[i]>=binStart)&&(unixTime[i]<=binEnd) then
    hist.Fill(unixTime[i].to_f)
  end
end
trigger=Array.new
unixTimeTrigger=Array.new
triggerIndex=0
for i in 1..eventNum
  if (adcChannel==adcIndex[i].to_i) then
    trigger[triggerIndex]=triggerCount[i].to_i
    unixTimeTrigger[triggerIndex]=unixTime[i].to_f
    triggerIndex+=1
  end
end
for i in 1..triggerIndex-1
  deltaTrigger=trigger[i]-trigger[i-1]-1
  if deltaTrigger<0 then
    deltaTrigger+=2**16
  end
  deltaTrigger.times do
    hist.Fill(unixTimeTrigger[i])
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
#hist.GetXaxis().SetTimeFormat("%m/%d %H:%M")
hist.GetXaxis().SetTimeFormat("%H:%M:%S")

hist.Draw("e1")
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

