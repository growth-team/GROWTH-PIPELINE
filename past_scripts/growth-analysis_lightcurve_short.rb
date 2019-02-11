#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if ARGV[5]==nil then
  puts "Usage: ruby growth-analysis_lightcurve_short.rb <fits file> <adc channel> <bin size (sec)> <lower channel> <upper channel> <start unixtime> <duration> <output file>"
  exit 1
end

fitsFileAddress=ARGV[0]
adcChannel=ARGV[1].to_i
binWidth=ARGV[2].to_f
energyLimitsLow=ARGV[3].to_f
energyLimitsHigh=ARGV[4].to_f
startTime=ARGV[5].to_f
duration=ARGV[6].to_f

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

binNum=(duration/binWidth).to_i
binStart=0.0
binEnd=binWidth*binNum.to_f

hist=Root::TH1D.create("", "", binNum, binStart, binEnd)

for i in 0..eventNum
  eventTime=unixTime[i].to_f-startTime
  if (adcChannel==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
    energy=(energyRaw[i]+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
    if (energy>=energyLimitsLow)&&(energy<energyLimitsHigh) then
      hist.Fill(eventTime)
    end
  end
end

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
#scaleFactor=1.0/binWidth
#hist.Sumw2()
#hist.Scale(scaleFactor)
hist.SetTitle("")
hist.GetXaxis().SetTitle("Second")
hist.GetXaxis().SetTitleOffset(1.2)
hist.GetXaxis().CenterTitle()
hist.GetXaxis().SetRangeUser(binStart, binEnd)
hist.GetYaxis().SetTitle("Count Rate (count/bin)")
hist.GetYaxis().CenterTitle()
hist.GetYaxis().SetTitleOffset(1.35)
hist.SetStats(0)
hist.GetYaxis().SetRangeUser(0.0, 50.0)
#gStyle.SetTimeOffset(-788918400)
#gStyle.SetNdivisions(505)
#hist.GetXaxis().SetTimeDisplay(1)
#hist.GetXaxis().SetTimeFormat("%m/%d %H:%M")
#hist.GetXaxis().SetTimeFormat("%H:%M:%S")

hist.Draw("e1")
c0.Update()
if ARGV[7]==nil then
  run_app()
else
  outputFile=ARGV[7]
  c0.SaveAs(outputFile)
end

#hist.GetYaxis.SetRangeUser(0, 70)
#
#output=File.open("longLightCurveLaw.dat", "w+")
#i=0
#countSec.each do
#  line=time[i].to_s+"\t"+errorTime[i].to_s+"\t"+countSec[i].to_s+"\t"+errorCountSec[i].to_s+"\n"
#  output.write(line)
#  i+=1
#end
