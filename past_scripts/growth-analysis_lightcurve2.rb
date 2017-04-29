#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if ARGV[5]==nil then
  puts "Usage: ruby makeLightCurveEnergy.rb <fits file> <adc channel> <bin size (sec)> <lower channel> <upper channel> <center second>"
  exit 1
end

fitsFileAddress=ARGV[0]
adcChannel=ARGV[1].to_i
binWidth=ARGV[2].to_f
energyLimitsLow=ARGV[3].to_f
energyLimitsHigh=ARGV[4].to_f
centerSecond=ARGV[5].to_f

fits=Fits::FitsFile.new(fitsFileAddress)
eventHDU=fits["EVENTS"]
adcIndex=eventHDU["boardIndexAndChannel"]
energyRaw=eventHDU["energy"]
unixTime=eventHDU["unixTime"]
energyWidth_header="BINW_CH#{adcChannel}"
energyWidth=eventHDU.header(energyWidth_header).to_f
eventNum=eventHDU.getNRows()-1

obsStartTime=unixTime[0].to_f
obsEndTime=unixTime[eventNum].to_f
observationTime=obsEndTime-obsStartTime
binNum=(observationTime/binWidth).to_i

puts "observation satrt time: #{obsStartTime} (unixTime)"

binStart=0.0-centerSecond
binEnd=binWidth*binNum.to_f-centerSecond

hist=Root::TH1D.create("", "", binNum, binStart, binEnd)
ghist=Root::TH1D.create("", "", 100000, -250.0, 250.0)

for i in 0..eventNum
  eventTime=unixTime[i].to_f-obsStartTime-centerSecond
  if (adcChannel==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
    energy=(energyRaw[i]+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
    if (energy>=energyLimitsLow)&&(energy<energyLimitsHigh) then
      hist.Fill(eventTime)
    end
  end
end

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
scaleFactor=1.0/binWidth
hist.Sumw2()
hist.Scale(scaleFactor)
ghist.SetTitle("Count Rate")
ghist.GetXaxis.SetTitle("Date (JST)")
ghist.GetXaxis.SetTitleOffset(1.2)
ghist.GetXaxis.CenterTitle
ghist.GetXaxis.SetRangeUser(-250, 250)
ghist.GetYaxis.SetTitle("Count Rate (count/sec)")
ghist.GetYaxis.CenterTitle
ghist.GetYaxis.SetRangeUser(0, 60)
ghist.GetYaxis.SetTitleOffset(1.35)
ghist.SetStats(0)
#gStyle.SetTimeOffset(-788918400-86400)
#gStyle.SetNdivisions(505)
#hist.GetXaxis().SetTimeDisplay(1)
#hist.GetXaxis().SetTimeFormat("%m/%d %H:%M")
ghist.Draw("")
#hist.Draw("e1")
hist.SetLineWidth(2)
hist.Draw("same")
if ARGV[6]!=nil then
  outputFile=ARGV[6]
  Root::TFile.open(outputFile, "recreate") do |output|
    hist.Write("hist")
  end
end
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

