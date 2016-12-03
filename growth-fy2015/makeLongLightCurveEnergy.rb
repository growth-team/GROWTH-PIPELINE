require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if ARGV[4]==nil then
  puts "Usage: ruby makeLongLightCurve <fits file list> <adc channel> <bin size (sec)> <lower channel> <upper channel>"
  exit 1
end

fitsListAddress=ARGV[0]
adcChannel=ARGV[1].to_i
binWidth=ARGV[2].to_f
energyLimitsLow=ARGV[3].to_f
energyLimitsHigh=ARGV[4].to_f

observationTime=1800.0
fpgaClock=1.0e8
binNum=(observationTime/binWidth).to_i+1

fitsList=File.open(fitsListAddress, "r")
fitsFile=fitsList.readlines
fitsFileNum=fitsFile.length

count=Array.new(2*binNum*fitsFileNum, 0)
errorCount=Array.new
countSec=Array.new
errorCountSec=Array.new
time=Array.new
errorTime=Array.new
startSecond=Array.new
lastSecond=Array.new
liveTime=Array.new(2*binNum*fitsFileNum, binWidth)

fitsFile.each_with_index do |fitsName, index|
  fits=Fits::FitsFile.new(fitsFile[0])
    fits=Fits::FitsFile.new(fitsName)
    eventHDU=fits["EVENTS"]
    adcIndex=eventHDU["boardIndexAndChannel"]
    eventNum=eventHDU.getNRows()-1
    unixTimeStart=eventHDU["UNIXTIME"][0].to_f
    unixTimeLast=eventHDU["UNIXTIME"][eventNum].to_f
    if index==0 then
      @unixTimeAllStart=unixTimeStart
    end
    startSecond[index]=unixTimeStart-@unixTimeAllStart
    lastSecond[index]=unixTimeLast-@unixTimeAllStart
    for i in 0..eventNum
      unixTime=eventHDU["UNIXTIME"][i].to_f
      energyRaw=eventHDU["ENERGY"][i].to_f
      energyRawLow=eventHDU["ENERGY_LOW"][i].to_f
      energyRawHigh=eventHDU["ENERGY_HIGH"][i].to_f
      if adcIndex[i].to_i==adcChannel then
        energy=energyRaw+(rand(-5..5).to_f/5.0)*(energyRawHigh-energyRaw)
        if (energy>=energyLimitsLow)&&(energy<energyLimitsHigh) then
          second=startSecond[index]+(unixTime-unixTimeStart.to_f)
          binNo=(second/binWidth).to_i
          count[binNo]+=1
        end
      end
    end
    message="#{(index+1).to_s}/#{fitsFileNum.to_s} completed"
    puts message
end

for i in 1..fitsFileNum-1
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

for i in 0..binNum
  errorCount[i]=count[i]**0.5
  #  countSec[i]=count[i]/liveTime[i]
  #  errorCountSec[i]=errorCount[i]/liveTime[i]
  countSec[i]=count[i]/binWidth
  errorCountSec[i]=errorCount[i]/binWidth
  time[i]=(i+0.5)*binWidth/60.0
  errorTime[i]=0.5*binWidth/60.0
end

hist=Root::TGraphErrors.create(time,countSec,errorTime,errorCountSec)
c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
hist.SetTitle("Count Rate")
hist.GetXaxis.SetTitle("Time (min)")
hist.GetXaxis.SetTitleOffset(1.2)
hist.GetXaxis.CenterTitle
hist.GetYaxis.SetTitle("Count Rate (count/sec)")
hist.GetYaxis.CenterTitle
hist.GetYaxis.SetTitleOffset(1.35)
hist.Draw()
c0.Update()
run_app()

#hist.GetYaxis.SetRangeUser(0, 70)
#hist.GetXaxis.SetRangeUser(0, 80000)
#output=File.open("longLightCurveLaw.dat", "w+")
#i=0
#countSec.each do
#  line=time[i].to_s+"\t"+errorTime[i].to_s+"\t"+countSec[i].to_s+"\t"+errorCountSec[i].to_s+"\n"
#  output.write(line)
#  i+=1
#end
