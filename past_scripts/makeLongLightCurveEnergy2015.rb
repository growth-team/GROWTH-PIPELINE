#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if ARGV[4]==nil then
  puts "Usage: ruby makeLongLightCurve <fits file list> <adc channel> <bin size (sec)> <lower energy> <energy>"
  exit 1
end

fitsListAddress=ARGV[0]
adcChannel=ARGV[1].to_i
binWidth=ARGV[2].to_f
phaLimitsLow=ARGV[3].to_i
phaLimitsUp=ARGV[4].to_i

observationTime=1800.0
fpgaClock=1.0e8
binNum=(observationTime/binWidth).to_i-1

fitsList=File.open(fitsListAddress, "r")
fitsFile=Array.new
fitsFile=fitsList.readlines
fitsFileNum=0
fitsFile.each do |fitsName|
  fitsName.chomp!
  fitsFileNum+=1
end

count=Array.new(binNum*fitsFileNum*2, 0)
errorCount=Array.new
countSec=Array.new
errorCountSec=Array.new
time=Array.new
errorTime=Array.new
startSecond=Array.new
lastSecond=Array.new
liveTime=Array.new(binNum*fitsFileNum*2, binWidth)

fits=Fits::FitsFile.new(fitsFile[0])
eventHDU=fits["EVENTS"]
adcIndex=eventHDU["boardIndexAndChannel"]
energyWidth_header="BINW_CH#{adcChannel}"
energyWidth=eventHDU.header(energyWidth_header).to_f
energyThreshold_header="ETH_CH#{adcChannel}"
energyThreshold=eventHDU.header(energyThreshold_header).to_f/1000.0
eventNum=eventHDU.getNRows()-1
timeTagStart=eventHDU["timeTag"][0]
timeTagLast=eventHDU["timeTag"][eventNum]
timeTagPast=eventHDU["timeTag"][eventNum]
unixTimeStart=eventHDU["unixTime"][0].to_f

for i in 0..eventNum
  timeTag=eventHDU["timeTag"][i]
  energyRaw=eventHDU["energy"][i].to_f
  energy=(energyRaw+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
  if adcIndex[i].to_i==adcChannel then
    if (timeTag>=timeTagStart)&&(energy>=phaLimitsLow)&&(energy<phaLimitsUp) then
      second=(timeTag.to_f-timeTagStart.to_f)/fpgaClock
      binNo=(second/binWidth).to_i
      count[binNo]+=1
    elsif (timeTag<timeTagStart)&&(energy>=phaLimitsLow)&&(energy<phaLimitsUp) then
      second=(timeTag.to_f-timeTagStart.to_f+2.0**40-1.0)/fpgaClock
      binNo=(second/binWidth).to_i
      count[binNo]+=1
    end
  end
end
if timeTagLast>=timeTagStart then
  lastSecond[0]=(timeTagLast.to_f-timeTagStart.to_f)/fpgaClock
elsif timeTagLast<timeTagStart then
  lastSecond[0]=(timeTagLast.to_f+2.0**40-1.0-timeTagStart.to_f)/fpgaClock
end
for i in 1..(fitsFileNum-1)
  message=i.to_s+"/"+fitsFileNum.to_s+" completed"
  puts message
  fits=Fits::FitsFile.new(fitsFile[i])
  eventHDU=fits["EVENTS"]
  eventNum=eventHDU.getNRows()-1
  timeTagStart=eventHDU["timeTag"][0]
  timeTagLast=eventHDU["timeTag"][eventNum]
  adcIndex=eventHDU["boardIndexAndChannel"]
  energyWidth_header="BINW_CH#{adcChannel}"
  energyWidth=eventHDU.header(energyWidth_header).to_f
  energyThreshold_header="ETH_CH#{adcChannel}"
  energyThreshold=eventHDU.header(energyThreshold_header).to_f/1000.0
  if timeTagStart>=timeTagPast then
    startSecond[i-1]=lastSecond[i-1]+(timeTagStart.to_f-timeTagPast.to_f)/fpgaClock
  elsif timeTagStart<timeTagPast then
    startSecond[i-1]=lastSecond[i-1]+(2.0**40-1.0+timeTagStart.to_f-timeTagPast.to_f)/fpgaClock
  end
  for j in 0..eventNum
    timeTag=eventHDU["timeTag"][j]
    energyRaw=eventHDU["energy"][j].to_f
    energy=(energyRaw+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
    if adcIndex[j].to_i==adcChannel then
      if (timeTag>=timeTagStart)&&(energy>=phaLimitsLow)&&(energy<phaLimitsUp) then
        second=startSecond[i-1]+(timeTag.to_f-timeTagStart.to_f)/fpgaClock
        binNo=(second/binWidth).to_i
        count[binNo]+=1
      elsif (timeTag<timeTagStart)&&(energy>=phaLimitsLow)&&(energy<phaLimitsUp) then
        second=startSecond[i-1]+(timeTag.to_f-timeTagStart.to_f+2.0**40-1.0)/fpgaClock
        binNo=(second/binWidth).to_i
        count[binNo]+=1
      end
    end
  end
  if timeTagLast>=timeTagStart then
    lastSecond[i]=startSecond[i-1]+(timeTagLast.to_f-timeTagStart.to_f)/fpgaClock
  elsif timeTagLast<timeTagStart then
    lastSecond[i]=startSecond[i-1]+(timeTagLast.to_f+2.0**40-1.0-timeTagStart.to_f)/fpgaClock
  end
  timeTagPast=eventHDU["timeTag"][eventNum]
end
for i in 0..fitsFileNum-2
  if (lastSecond[i]/binWidth).to_i == (startSecond[i]/binWidth).to_i then
    binNum=(lastSecond[i]/binWidth).to_i
    liveTime[binNum]=binWidth-(startSecond[i]-lastSecond[i])
  elsif (lastSecond[i]/binWidth).to_i != (startSecond[i]/binWidth).to_i then
    binNum=(lastSecond[i]/binWidth).to_i
    tempLiveTimeA=liveTime[binNum]
    tempLiveTimeB=liveTime[binNum+1]
    liveTime[binNum]=tempLiveTimeA-(binWidth*(((lastSecond[i]/binWidth).to_i+1).to_f)-lastSecond[i])
    liveTime[binNum+1]=tempLiveTimeB-(startSecond[i]-binWidth*(((startSecond[i]/binWidth).to_i).to_f))
  end
end
binNum=(lastSecond[fitsFileNum-1]/binWidth).to_i
liveTime[binNum]=lastSecond[fitsFileNum-1]-binWidth*(((lastSecond[fitsFileNum-1]/binWidth).to_i).to_f)

for i in 0..((lastSecond[fitsFileNum-1]/binWidth).to_i)
  errorCount[i]=count[i]**0.5
  countSec[i]=count[i]/liveTime[i]
  errorCountSec[i]=errorCount[i]/liveTime[i]
  time[i]=(i+0.5)*binWidth+unixTimeStart
  errorTime[i]=0.5*binWidth
end

hist=Root::TGraphErrors.create(time,countSec,errorTime,errorCountSec)
hist.SetName "g0"
c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
hist.SetTitle("")
hist.GetXaxis.SetTitle("Time (min)")
hist.GetXaxis.SetTitleOffset(1.2)
hist.GetXaxis.CenterTitle
hist.GetYaxis.SetTitle("Count Rate (count/sec)")
hist.GetYaxis.CenterTitle
hist.GetYaxis.SetTitleOffset(1.35)
gStyle.SetTimeOffset(-788918400)
hist.GetXaxis().SetTimeDisplay(1)
hist.GetXaxis().SetTimeFormat("%H:%M")
hist.Draw("ap")
c0.Update
sleep(2)

if ARGV[5]!=nil then
  outputFile=ARGV[5]
  Root::TFile.open(outputFile, "recreate") do |output|
    hist.Write("hist")
  end
else
  run_app()
end

#output=File.open("longLightCurveLaw.dat", "w+")
#i=0
#countSec.each do
#  line=time[i].to_s+"\t"+errorTime[i].to_s+"\t"+countSec[i].to_s+"\t"+errorCountSec[i].to_s+"\n"
#  output.write(line)
#  i+=1
#end
