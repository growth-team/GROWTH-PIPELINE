#!/usr/bin/env ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if ARGV[0]==nil then
  puts ""
  puts "Input file"
  fitsFile=gets
  puts "Unix time of shortburst beginning"
  startUnixTime=gets.to_f
  puts "ADC Index"
  channel=gets.to_i
  puts "Plot duration (second)"
  plotTime=gets.to_f
elsif ARGV[3]==nil then
  puts "Usage: makeWaveformShortburst.rb <fits file> <start unix time> <adc index> <plot duration>"
  exit -1
else
  fitsFile=ARGV[0]
  startUnixTime=ARGV[1].to_f
  channel=ARGV[2].to_i
  plotTime=ARGV[3].to_f
end

#fitsFile=["growth-fy2016f/20170206_172859.fits.gz", "growth-fy2016g/20170206_173207.fits.gz", "growth-fy2016s/20170206_170753.fits.gz"]
#eventStart=[1486370045.0, 1486370045.825, 1486370045.51]
#channel=[0, 0, 3]
#plotTime=1.0

#sampleBefore=20
sampleAfter=1020
clock=1.0e8

fits=Fits::FitsFile.new(fitsFile)
eventHDU=fits["EVENTS"]
eventNum=eventHDU.getNRows()-1
adcIndex=eventHDU["boardIndexAndChannel"]
triggerCount=eventHDU["triggerCount"]
unixTime=eventHDU["unixTime"]
phaMax=eventHDU["phaMax"]
phaMin=eventHDU["phaMin"]
phaFirst=eventHDU["phaFirst"]
phaLast=eventHDU["phaLast"]
phaMaxTime=eventHDU["phaMaxTime"]
timeTag=eventHDU["timeTag"]


timeTagGraph=Array.new
phaGraph=Array.new
timeTagTrigger=Array.new
deltaTrigger=Array.new
phaMinTimeGraph=Array.new
phaMinGraph=Array.new

index=0
indexMin=0
beginUnixTime=unixTime[0].to_f
beginTimeTag=timeTag[0].to_i

startTime=startUnixTime-beginUnixTime-0.2*plotTime
endTime=beginUnixTime+0.8*plotTime

for i in 0..eventNum
  eventTimeTag=timeTag[i].to_i-beginTimeTag
  if eventTimeTag<0 then
    eventTimeTag+=2**40
  end
  eventTime=eventTimeTag.to_f/clock
    
  if (eventTime>=startTime)&(eventTime<endTime)&(adcIndex[i].to_i==channel) then
    timeTagGraph[index]=(eventTime-startTime-0.2*plotTime)*1.0e3
    phaGraph[index]=phaFirst[i].to_f
    index+=1
    timeTagGraph[index]=(eventTime-startTime-0.2*plotTime+phaMaxTime[i].to_f/clock)*1.0e3
    phaGraph[index]=phaMax[i].to_f
    index+=1
    timeTagGraph[index]=(eventTime-startTime-0.2*plotTime+sampleAfter.to_f/clock)*1.0e3
    phaGraph[index]=phaLast[i].to_f
    index+=1
    phaMinTimeGraph[indexMin]=(eventTime-startTime-0.2*plotTime+phaMaxTime[i].to_f/clock)*1.0e3
    phaMinGraph[indexMin]=phaMin[i].to_f
    indexMin+=1
  end
end

index=0
for i in 1..eventNum
  eventTimeTag=timeTag[i].to_i-beginTimeTag
  if eventTimeTag<0 then
    eventTimeTag+=2**40
  end
  eventTime=eventTimeTag.to_f/clock.to_f
    
  if (eventTime>=startTime)&(eventTime<endTime)&(adcIndex[i].to_i==channel) then
    deltaTriggerCount=triggerCount[i].to_f-triggerCount[i-1].to_f-1
    if deltaTriggerCount>0 then
      timeTagTrigger[index]=(eventTime-startTime-0.2*plotTime-1.0/clock)*1.0e3
      deltaTrigger[index]=0.0
      index+=1
      timeTagTrigger[index]=(eventTime-startTime-0.2*plotTime)*1.0e3
      deltaTrigger[index]=deltaTriggerCount.to_f*100.0
      index+=1
      timeTagTrigger[index]=(eventTime-startTime-0.2*plotTime+1.0/clock)*1.0e3
      deltaTrigger[index]=0.0
      index+=1
    end
  end
end

step=(plotTime*1.0e3).to_i
startPlotTime=-0.2*plotTime*1.0e3
endPlotTime=0.8*plotTime*1.0e3
hist=Root::TH1D.create("", "", step, startPlotTime, endPlotTime)
waveform=Root::TGraph.create(timeTagGraph, phaGraph)
deltaTriggerGraph=Root::TGraph.create(timeTagTrigger, deltaTrigger)
phaMinForm=Root::TGraph.create(phaMinTimeGraph, phaMinGraph)

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
hist.SetTitle("")
hist.GetXaxis().SetTitle("ms")
hist.GetXaxis().SetTitleOffset(1.15)
hist.GetXaxis().CenterTitle()
hist.GetYaxis().SetTitle("ADC Channel")
hist.GetYaxis().CenterTitle()
hist.GetYaxis().SetTitleOffset(1.2)
hist.GetYaxis().SetRangeUser(0, 4096)
hist.GetXaxis().SetTitleSize(0.04)
hist.GetYaxis().SetTitleSize(0.04)
hist.GetXaxis().SetLabelSize(0.04)
hist.GetYaxis().SetLabelSize(0.04)
hist.SetStats(0)
deltaTriggerGraph.SetLineColor(2)
deltaTriggerGraph.SetMarkerColor(2)
phaMinForm.SetLineColor(3)
phaMinForm.SetMarkerColor(3)
hist.Draw("")
if index!=0 then
  deltaTriggerGraph.Draw("same")
end
waveform.Draw("same")
phaMinForm.Draw("same")
c0.Update()
run_app()
