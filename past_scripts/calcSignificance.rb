#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root

if ARGV[6]==nil then
  puts "Usage: ruby calcSignificance.rb <fits file> <adc channel> <bin size (sec)> <lower energy> <upper energy> <bgd mean> <bgd sigma>"
  exit 1
end

fitsAddress=ARGV[0]
adcChannel=ARGV[1].to_i
binWidth=ARGV[2].to_f
energyLimitsLow=ARGV[3].to_f
energyLimitsHigh=ARGV[4].to_f
bgdMean=ARGV[5].to_f
bgdSigma=ARGV[6].to_f

fits=Fits::FitsFile.new(fitsAddress)
eventHDU=fits["EVENTS"]
adcIndex=eventHDU["boardIndexAndChannel"]
unixTime=eventHDU["unixTime"]
eventNum=eventHDU.getNRows()-1
energyWidth_header="BINW_CH#{adcChannel}"
energyWidth=eventHDU.header(energyWidth_header).to_f
energyThreshold_header="ETH_CH#{adcChannel}"
energyThreshold=eventHDU.header(energyThreshold_header).to_f/1000.0

obsDuration=unixTime[eventNum].to_f-unixTime[0].to_f
binNum=(obsDuration/binWidth).to_i
startTime=unixTime[0].to_f
endTime=startTime+binWidth*binNum.to_f
  
hist=Root::TH1D.create("", "", binNum, startTime, endTime)

for i in 0..eventNum
  if adcIndex[i].to_i==adcChannel then
    unixTimeEvent=unixTime[i].to_f
    energyRaw=eventHDU["energy"][i].to_f
    energy=(energyRaw+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
    if (energy>=energyLimitsLow)&&(energy<energyLimitsHigh)&&(energy>=energyThreshold)&&(unixTimeEvent>=startTime)&&(unixTimeEvent<=endTime) then
      hist.Fill(unixTimeEvent)
    end
  end
end
scaleFactor=1.0/binWidth
hist.Scale(scaleFactor)

significance=0
for i in 0..binNum-1
  binCount=hist.GetBinContent(i)
  significanceCalc=(binCount-bgdMean)/bgdSigma
  if significance<significanceCalc then
    significance=significanceCalc
  end
end
puts significance
