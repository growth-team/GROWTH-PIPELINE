#!/usr/local/bin/ruby
require "RubyFits"
include Math

if ARGV[4]==nil then
  puts "Usage: ruby makeLightCurveEnergy.rb <fits file> <adc channel> <event start> <event end> <bgd start> <bgd start>"
  exit 1
end

fitsFileAddress=ARGV[0]
adcChannel=ARGV[1].to_i
eventStartTime=ARGV[2].to_f
eventStopTime=ARGV[3].to_f
bgdStartTime=ARGV[4].to_f
bgdStopTime=ARGV[5].to_f

fits=Fits::FitsFile.new(fitsFileAddress)
eventHDU=fits["EVENTS"]
adcIndex=eventHDU["boardIndexAndChannel"]
energyRaw=eventHDU["energy"]
unixTime=eventHDU["unixTime"]
unixTimeStart=unixTime[0].to_f
energyWidth_header="BINW_CH#{adcChannel}"
energyWidth=eventHDU.header(energyWidth_header).to_f
eventNum=eventHDU.getNRows()-1

eventDuration=eventStopTime-eventStartTime
bgdDuration=bgdStopTime-bgdStartTime
scaleFactor=eventDuration/bgdDuration

eventPhoton=0
bgdPhoton=0

for i in 0..eventNum
  if (adcChannel==adcIndex[i].to_i) then
    unixTimeEvent=unixTime[i].to_f-unixTimeStart
    energy=(energyRaw[i]+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
    if (energy>=3.0)&&(unixTimeEvent>=eventStartTime)&&(unixTimeEvent<=eventStopTime) then
      eventPhoton+=1
    elsif (energy>=3.0)&&(unixTimeEvent>=bgdStartTime)&&(unixTimeEvent<=bgdStopTime) then
      bgdPhoton+=1
    end
  end
end

bgdPhotonError=(bgdPhoton**0.5)*scaleFactor
intringicPhoton=eventPhoton-bgdPhoton*scaleFactor

puts "#{intringicPhoton} pm #{bgdPhotonError} was detected."
