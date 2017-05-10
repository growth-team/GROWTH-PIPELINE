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
  eventStart=gets.to_f
  puts "ADC Index"
  channel=gets.to_i
  puts "Plot duration (second)"
  plotTime=gets.to_f
elsif ARGV[3]==nil then
  puts "Usage: makeWaveformShortburst.rb <fits file> <start unix time> <adc index> <plot duration>"
else
  fitsFile=ARGV[0]
  eventStart=ARGV[1].to_f
  channel=ARGV[2].to_i
  plotTime=ARGV[3].to_f
end

#fitsFile=["growth-fy2016f/20170206_172859.fits.gz", "growth-fy2016g/20170206_173207.fits.gz", "growth-fy2016s/20170206_170753.fits.gz"]
#eventStart=[1486370045.0, 1486370045.825, 1486370045.51]
#channel=[0, 0, 3]
#plotTime=1.0

sampleBefore=20
sampleAfter=1000
clock=1.0e5
phaMinTime=200.0

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

startTime=eventStart
endTime=eventStart+plotTime

timeTagGraph=Array.new
phaGraph=Array.new
timeTagTrigger=Array.new
deltaTrigger=Array.new
phaMinTimeGraph=Array.new
phaMinGraph=Array.new

index=0
indexMin=0
for i in 0..eventNum
  if (unixTime[i].to_f>=startTime)&(unixTime[i].to_f<endTime)&(adcIndex[i].to_i==channel) then
    if index==0 then
      startTimeTag=timeTag[i].to_i
    end
    timeTagNow=timeTag[i].to_i-startTimeTag
    if timeTagNow<0 then
      timeTagNow+=2**40
    end
    timeTagGraph[index]=timeTagNow.to_f/clock
    phaGraph[index]=phaFirst[i].to_f
    index+=1
    timeTagGraph[index]=(timeTagNow.to_f+phaMaxTime[i].to_f)/clock
    phaGraph[index]=phaMax[i].to_f
    index+=1
    timeTagGraph[index]=(timeTagNow.to_f+sampleBefore.to_f+sampleAfter.to_f)/clock
    phaGraph[index]=phaLast[i].to_f
    index+=1
    phaMinTimeGraph[indexMin]=(timeTagNow.to_f)/clock
    phaMinGraph[indexMin]=phaMin[i].to_f
    indexMin+=1
  end
end
index=0
for i in 1..eventNum
  if (unixTime[i].to_f>=startTime)&(unixTime[i].to_f<endTime)&(adcIndex[i].to_i==channel) then
    deltaTriggerCount=triggerCount[i].to_f-triggerCount[i-1].to_f-1
    if deltaTriggerCount>0 then
      timeTagNow=timeTag[i].to_i-startTimeTag
      if timeTagNow<0 then
        timeTagNow+=2**40
      end
      timeTagTrigger[index]=(timeTagNow-1).to_f/clock
      deltaTrigger[index]=0.0
      index+=1
      timeTagTrigger[index]=(timeTagNow).to_f/clock
      deltaTrigger[index]=deltaTriggerCount.to_f*1000.0
      index+=1
      timeTagTrigger[index]=(timeTagNow+1).to_f/clock
      deltaTrigger[index]=0.0
      index+=1
    end
  end
end
  
waveform=Root::TGraph.create(timeTagGraph, phaGraph)
deltaTriggerGraph=Root::TGraph.create(timeTagTrigger, deltaTrigger)
phaMinForm=Root::TGraph.create(phaMinTimeGraph, phaMinGraph)

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
waveform.SetTitle("")
waveform.GetXaxis().SetTitle("ms")
waveform.GetXaxis().SetTitleOffset(1.15)
waveform.GetXaxis().CenterTitle()
waveform.GetYaxis().SetTitle("ADC Channel")
waveform.GetYaxis().CenterTitle()
waveform.GetYaxis().SetTitleOffset(1.2)
waveform.GetYaxis().SetRangeUser(0, 4096)
waveform.GetXaxis().SetTitleSize(0.04)
waveform.GetYaxis().SetTitleSize(0.04)
waveform.GetXaxis().SetLabelSize(0.04)
waveform.GetYaxis().SetLabelSize(0.04)
deltaTriggerGraph.SetLineColor(2)
deltaTriggerGraph.SetMarkerColor(2)
phaMinForm.SetLineColor(3)
phaMinForm.SetMarkerColor(3)
waveform.Draw("")
if index!=0 then
  deltaTriggerGraph.Draw("same")
end
waveform.Draw("same")
phaMinForm.Draw("same")
c0.Update()
run_app()
