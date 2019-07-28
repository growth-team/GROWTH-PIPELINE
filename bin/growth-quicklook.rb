#!/usr/bin/env ruby
# coding: utf-8
require "RubyROOT"
require "RubyFits"
require "date"
include Root
include RootApp
include Fits
include Math

def plotSetting(hist, xtitle, ytitle)
  hist.SetTitle("")
  hist.GetXaxis().SetTitle(xtitle)
  hist.GetYaxis().SetTitle(ytitle)
  hist.SetStats(0)
end

def showUsage(argv)
  if argv==nil then
    puts "Usage:   growth-quicklook.rb [input folder] [output folder] [detector name] [start date] [end date] [adc channel] [lower threshold] [upper threshold]"
    puts "Example: growth-quicklook.rb ~/work/raw_data ~/work/growth/data/quick_look growth-fy2016s 20181001 20190320 0 2400 4000"
    exit -1
  end
end

def createOutputFolder(dir)
  if !File.exists?(dir) then
    puts "#{dir} does not exist. Create it."
    `mkdir -p #{dir}`
  end
  daughter=["lc_1sec", "lc_10sec", "hist_2d", "spec", "delta_trigger"]
  daughter.each do |daughter|
    daughter_dir="#{dir}/#{daughter}"
    if !File.exists?(daughter_dir) then
      puts "#{daughter_dir} does not exist. Create it."
      `mkdir #{daughter_dir}`
    end
  end
end

def extractDateList(start_date, end_date)
  obj_start=Date.new(start_date[0..3].to_i, start_date[4..5].to_i, start_date[6..7].to_i) 
  obj_end=Date.new(end_date[0..3].to_i, end_date[4..5].to_i, end_date[6..7].to_i)
  date_num=(obj_end-obj_start+1).to_i
  date_array=Array.new
  date_num.times do |i|
    date_now=obj_start+i
    date_array << date_now.strftime("%Y%m%d")
  end
  date_array
end

def resetHist(h0, h1, h2, h3)
  h0.Reset()
  h1.Reset()
  h2.Reset()
  h3.Reset()
end

def extractFitsNameHeader(fitsAddress)
  fitsAddress.chomp!
  fitsAddressParse=fitsAddress.split("/")
  fitsName=fitsAddressParse[fitsAddressParse.length-1]
  fitsNameParse=fitsName.split(".")
  fitsHeader=fitsNameParse[0]
end

def extractObsTime(startTimeTag, stopTimeTag)
  if stopTimeTag<startTimeTag then
    observationTime=(stopTimeTag-startTimeTag+2**40).to_f/1.0e8
  else
    observationTime=(stopTimeTag-startTimeTag).to_f/1.0e8
  end
end

def fillHist(fitsAddress, observationTimeTotal, lowth, uppth, adcChannel, hist, spec, lc0, lc1, delta_trigger)
  fits=Fits::FitsFile.new(fitsAddress)
  eventHDU=fits["EVENTS"]
  timeTag=eventHDU["timeTag"]
  phaMax=eventHDU["phaMax"]
  phaMin=eventHDU["phaMin"]
  triggerCount=eventHDU["triggerCount"]
  adcIndex=eventHDU["boardIndexAndChannel"]
  eventNum=eventHDU.getNRows()-1
  
  startTimeTag=timeTag[0].to_i
  stopTimeTag=timeTag[eventNum].to_i

  observationTime=extractObsTime(startTimeTag, stopTimeTag)

  if (observationTime<2000.0)&&(observationTime>0.0) then
    pastCount=-1.0
    for i in 0..eventNum
      if adcIndex[i].to_i==adcChannel then
        spec.Fill(phaMax[i].to_f)
        if startTimeTag<=timeTag[i].to_i then
          eventTime=(timeTag[i].to_i-startTimeTag).to_f/1.0e8
        else
          eventTime=(timeTag[i].to_i-startTimeTag+2**40).to_f/1.0e8
        end
        hist.Fill(eventTime, phaMax[i].to_f)
        eventTimeHour=(observationTimeTotal+eventTime)/3600.0
        if (phaMax[i].to_i>lowth)&&(phaMax[i].to_i<uppth) then
          lc0.Fill(eventTimeHour)
          lc1.Fill(eventTimeHour)
        end
        if pastCount<0 then
          pastCount=triggerCount[i].to_i
        else
          deltaCount=triggerCount[i].to_i-pastCount-1
          if deltaCount<0 then
            deltaCount+=2**16
          end
          deltaCount.times do
            delta_trigger.Fill(eventTimeHour)
          end
          pastCount=triggerCount[i].to_i
        end
      end
    end
    observationTimeTotal+=observationTime
  end
  return observationTimeTotal
end


def saveHistPic(observationTimeTotal, adcChannel, outputFileDir, date, spec, lc0, lc1, delta_trigger, c0)
  plotSetting(spec, "channel", "Count s^{-1} ch^{-1}")
  plotSetting(lc0, "Hour", "Count s^{-1}")
  plotSetting(lc1, "Hour", "Count s^{-1}")
  plotSetting(delta_trigger, "Hour", "unread event")
  #spec.Scale(1.0/observationTimeTotal)
  spec.Draw("h")
  c0.SetLogy(1)
  c0.Update()
  c0.SaveAs("#{outputFileDir}/spec/#{date}_ch#{adcChannel.to_s}_spec.png")
  lc0.Draw("h")
  c0.SetLogy(0)
  c0.Update()
  c0.SaveAs("#{outputFileDir}/lc_1sec/#{date}_ch#{adcChannel.to_s}_lc_1sec.png")
  lc1.Draw("h")
  c0.SetLogy(0)
  c0.Update()
  c0.SaveAs("#{outputFileDir}/lc_10sec/#{date}_ch#{adcChannel.to_s}_lc_10sec.png")
  delta_trigger.Draw("h")
  c0.Update()
  c0.SaveAs("#{outputFileDir}/delta_trigger/#{date}_ch#{adcChannel.to_s}_deltaTrigger.png")
end

def verify_fits(fitsAddress)
  result=`fverify #{fitsAddress} prstat=no`
  resultParse=result.split"\s"
  if resultParse[1] == "OK" then
    return true
  else
    puts "#{fitsAddress} is broken and excluded for analysis."
    return false
  end
end

input_dir=ARGV[0]  
output_dir=ARGV[1]
detector=ARGV[2]
start_date=ARGV[3]
end_date=ARGV[4]
adcChannel=ARGV[5].to_i
if ARGV[6].to_i<2050 then
  lowth=2050
else
  lowth=ARGV[6].to_i
end
uppth=ARGV[7].to_i
lc_width=[1.0, 10.0]
lc_binNum=[25*3600/lc_width[0].to_i, 25*3600/lc_width[1].to_i]

showUsage(ARGV[7])
outputFileDir="#{output_dir}/#{detector}"
createOutputFolder(outputFileDir)
dateList=extractDateList(start_date, end_date)

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)

hist=Root::TH2F.create("hist", "hist", 2400, 0.0, 2400.0, 2048, 2047.5, 4095.5)
spec=Root::TH1F.create("spec", "spec", 2048, 2047.5, 4095.5)
lc0=Root::TH1F.create("lc0", "lc0", lc_binNum[0], 0.0, 25.0)
lc1=Root::TH1F.create("lc1", "lc1", lc_binNum[1], 0.0, 25.0)
delta_trigger=Root::TH1F.create("delta_trigger", "delta_trigger", lc_binNum[0], 0.0, 25.0)

dateList.each do |date|
  puts date
  month=date[0..5]
  resetHist(spec, lc0, lc1, delta_trigger)
  observationTimeTotal=0.0

  fitsListName="./fitsList_#{detector}_#{date}.txt"
  inputFileDir="#{input_dir}/#{detector}/#{month}/"
  `find #{inputFileDir} -name #{date}*.fits.gz | sort > #{fitsListName}`

  File.open(fitsListName, "r") do |list|
    list.each_line do |fitsAddress|
      fitsHeader=extractFitsNameHeader(fitsAddress)
      puts fitsAddress
      if verify_fits(fitsAddress) then
        hist.Reset()
        observationTimeTotal=fillHist(fitsAddress, observationTimeTotal, lowth, uppth, adcChannel, hist, spec, lc0, lc1, delta_trigger)
        hist_output="#{outputFileDir}/hist_2d/#{fitsHeader}_ch#{adcChannel.to_s}_2d.root"
        Root::TFile.open(hist_output, "RECREATE") do |rootFile|
          hist.Write("hist")
        end
      end
    end
  end
  saveHistPic(observationTimeTotal, adcChannel, outputFileDir, date, spec, lc0, lc1, delta_trigger, c0)
  `rm #{fitsListName}`
end
