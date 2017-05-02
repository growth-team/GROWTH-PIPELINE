#!/usr/bin/env ruby
require "RubyFits"
require "RubyROOT"
require "Time"
include Math
include Root
include RootApp

if ARGV[5]==nil then
  puts "Usage: ruby analysis_longburst.rb <fits file> <output directory> <adc channel> <energy threshold> <lc bin width> <time of event center>"
  puts ""
  exit 1
end

fitsFile=ARGV[0]
outputDir=ARGV[1]
adcChannel=ARGV[2].to_i
threshold=ARGV[3].to_f
binWidth=ARGV[4].to_f
eventTime=ARGV[5]
scale=ARGV[6]

if scale=="small" then
  rangeLow=500
  rangeHigh=50
elsif scale=="large" then
  rangeLow=1000
  rangeHigh=100
else
  puts "Type small or large"
  exit 1
end

if File.exists?(outputDir)==false then
  `mkdir #{outputDir}`
end

fits=Fits::FitsFile.new(fitsFile)
eventHDU=fits["EVENTS"]
adcIndex=eventHDU["boardIndexAndChannel"]
energyRaw=eventHDU["energy"]
unixTime=eventHDU["unixTime"]
energyWidth_header="BINW_CH#{adcChannel}"
energyWidth=eventHDU.header(energyWidth_header).to_f
eventNum=eventHDU.getNRows()-1

startUnixTime=unixTime[0].to_f
endUnixTime=unixTime[eventNum].to_f
duration=endUnixTime-startUnixTime
eventUnixTime=(Time.parse(eventTime).to_i).to_f
detailDuration=6.0*60.0

#------------------ lighcurve of longburst for low energy  ------------------
binNum=(duration/binWidth).to_i
binStart=startUnixTime
binEnd=startUnixTime+binWidth*binNum.to_f

lcLow=Root::TH1D.create("", "", binNum, binStart, binEnd)

for i in 0..eventNum
  eventTime=unixTime[i].to_f
  if (adcChannel==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
    energy=(energyRaw[i]+(rand(-500..500).to_f/1000.0)*energyWidth)/1000.0
    if (energy>=threshold)&&(energy<30.0) then
      lcLow.Fill(eventTime)
    end
  end
end

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
lcLow.Sumw2()
lcLow.Scale(1.0/binWidth)
lcLow.SetTitle("")
lcLow.GetXaxis().SetTitle("Time (JST)")
lcLow.GetXaxis().SetTitleOffset(1.2)
lcLow.GetXaxis().CenterTitle()
lcLow.GetXaxis().SetRangeUser(binStart, binEnd)
lcLow.GetYaxis().SetRangeUser(0, rangeLow)
lcLow.GetYaxis().SetTitle("Count s^{-1}")
lcLow.GetYaxis().CenterTitle()
lcLow.GetYaxis().SetTitleOffset(1.35)
lcLow.SetStats(0)
lcLow.GetXaxis().SetTimeDisplay(1)
lcLow.GetXaxis().SetTimeFormat("%H:%M")
lcLow.Draw("e1")
gStyle.SetNdivisions(505)
c0.Update()
c0.SaveAs("#{outputDir}/lc_lowEnergy.pdf")
c0.SaveAs("#{outputDir}/lc_lowEnergy.png")
c0.SaveAs("#{outputDir}/lc_lowEnergy.root")

#------------------ lighcurve of longburst for low energy  ------------------


lcHigh=Root::TH1D.create("", "", binNum, binStart, binEnd)
for i in 0..eventNum
  eventTime=unixTime[i].to_f
  if (adcChannel==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
    energy=(energyRaw[i]+(rand(-500..500).to_f/1000.0)*energyWidth)/1000.0
    if (energy>=3.0)&&(energy<30.0) then
      lcHigh.Fill(eventTime)
    end
  end
end

c1=Root::TCanvas.create("c1", "canvas1", 640, 480)
lcHigh.Sumw2()
lcHigh.Scale(1.0/binWidth)
lcHigh.SetTitle("")
lcHigh.GetXaxis().SetTitle("Time (JST)")
lcHigh.GetXaxis().SetTitleOffset(1.2)
lcHigh.GetXaxis().CenterTitle()
lcHigh.GetXaxis().SetRangeUser(binStart, binEnd)
lcHigh.GetYaxis().SetRangeUser(0, rangeHigh)
lcHigh.GetYaxis().SetTitle("Count s^{-1}")
lcHigh.GetYaxis().CenterTitle()
lcHigh.GetYaxis().SetTitleOffset(1.35)
lcHigh.SetStats(0)
lcHigh.GetXaxis().SetTimeDisplay(1)
lcHigh.GetXaxis().SetTimeFormat("%H:%M")
lcHigh.Draw("e1")
gStyle.SetNdivisions(505)
c1.Update()
c1.SaveAs("#{outputDir}/lc_highEnergy.pdf")
c1.SaveAs("#{outputDir}/lc_highEnergy.png")
c1.SaveAs("#{outputDir}/lc_highEnergy.root")

#------------------ 2-dementional histogram ------------------
xbins=Root::DoubleArray.new(binNum+1)
(binNum+1).times do |nbin|
  xbins[nbin]=startUnixTime+nbin.to_f*binWidth
end

energyMin=0.3
energyMax=30.0
eLogMin=log(energyMin, 10)
eLogMax=log(energyMax, 10)
ybinNum=40
ybinWidth=(eLogMax-eLogMin)/ybinNum.to_f
ybins=Root::DoubleArray.new(ybinNum+1)
(ybinNum+1).times do |nbin|
  ybins[nbin]=10**(eLogMin+nbin*ybinWidth)
end
ybins[0]=energyMin
ybins[ybinNum]=energyMax

lcEnergy=Root::TH2D.create("", "", binNum, xbins, ybinNum, ybins)

for i in 0..eventNum
  eventTime=unixTime[i].to_f
  if (adcChannel==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
    energy=(energyRaw[i]+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
    if (energy>=energyMin)&&(energy<energyMax) then
      lcEnergy.Fill(eventTime, energy)
    end
  end
end

c2=Root::TCanvas.create("c2", "canvas2", 640, 480)
lcEnergy.SetTitle("")
lcEnergy.GetXaxis().SetTitle("Time (JST)")
lcEnergy.GetXaxis().SetTitleOffset(1.2)
lcEnergy.GetXaxis().CenterTitle()
lcEnergy.GetYaxis().SetTitle("Energy (MeV)")
lcEnergy.GetYaxis().CenterTitle()
lcEnergy.GetYaxis().SetTitleOffset(1.35)
lcEnergy.GetXaxis().SetTimeDisplay(1)
lcEnergy.GetXaxis().SetTimeFormat("%H:%M")
lcEnergy.SetStats(0)
lcEnergy.Draw("colz")
c2.SetLogy()
c2.Update()
c2.SaveAs("#{outputDir}/2d_long.pdf")
c2.SaveAs("#{outputDir}/2d_long.png")
c2.SaveAs("#{outputDir}/2d_long.root")

#------------------ detail lighcurve of longburst for low energy  ------------------
binStart=eventUnixTime-detailDuration/2.0
binNum=(detailDuration/binWidth).to_i
binEnd=binStart+binWidth*binNum.to_f

lcLowDetail=Root::TH1D.create("", "", binNum, binStart, binEnd)

for i in 0..eventNum
  eventTime=unixTime[i].to_f
  if (adcChannel==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
    energy=(energyRaw[i]+(rand(-500..500).to_f/1000.0)*energyWidth)/1000.0
    if (energy>=threshold)&&(energy<30.0) then
      lcLowDetail.Fill(eventTime)
    end
  end
end

c3=Root::TCanvas.create("c3", "canvas3", 640, 480)
lcLowDetail.Sumw2()
lcLowDetail.Scale(1.0/binWidth)
lcLowDetail.SetTitle("")
lcLowDetail.GetXaxis().SetTitle("Time (JST)")
lcLowDetail.GetXaxis().SetTitleOffset(1.2)
lcLowDetail.GetXaxis().CenterTitle()
lcLowDetail.GetXaxis().SetRangeUser(binStart, binEnd)
lcLowDetail.GetYaxis().SetRangeUser(0, rangeLow)
lcLowDetail.GetYaxis().SetTitle("Count s^{-1}")
lcLowDetail.GetYaxis().CenterTitle()
lcLowDetail.GetYaxis().SetTitleOffset(1.35)
lcLowDetail.SetStats(0)
lcLowDetail.GetXaxis().SetTimeDisplay(1)
lcLowDetail.GetXaxis().SetTimeFormat("%H:%M")
lcLowDetail.Draw("e1")
gStyle.SetNdivisions(505)
c3.Update()
c3.SaveAs("#{outputDir}/lcDetail_lowEnergy.pdf")
c3.SaveAs("#{outputDir}/lcDetail_lowEnergy.png")
c3.SaveAs("#{outputDir}/lcDetail_lowEnergy.root")

#------------------ lighcurve of longburst for high energy  ------------------

lcHighDetail=Root::TH1D.create("", "", binNum, binStart, binEnd)
for i in 0..eventNum
  eventTime=unixTime[i].to_f
  if (adcChannel==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
    energy=(energyRaw[i]+(rand(-500..500).to_f/1000.0)*energyWidth)/1000.0
    if (energy>=3.0)&&(energy<30.0) then
      lcHighDetail.Fill(eventTime)
    end
  end
end

c4=Root::TCanvas.create("c4", "canvas4", 640, 480)
lcHighDetail.Sumw2()
lcHighDetail.Scale(1.0/binWidth)
lcHighDetail.SetTitle("")
lcHighDetail.GetXaxis().SetTitle("Time (JST)")
lcHighDetail.GetXaxis().SetTitleOffset(1.2)
lcHighDetail.GetXaxis().CenterTitle()
lcHighDetail.GetXaxis().SetRangeUser(binStart, binEnd)
lcHighDetail.GetYaxis().SetRangeUser(0, rangeHigh)
lcHighDetail.GetYaxis().SetTitle("Count s^{-1}")
lcHighDetail.GetYaxis().CenterTitle()
lcHighDetail.GetYaxis().SetTitleOffset(1.35)
lcHighDetail.SetStats(0)
lcHighDetail.GetXaxis().SetTimeDisplay(1)
lcHighDetail.GetXaxis().SetTimeFormat("%H:%M")
lcHighDetail.Draw("e1")
gStyle.SetNdivisions(505)
c4.Update()
c4.SaveAs("#{outputDir}/lcDetail_highEnergy.pdf")
c4.SaveAs("#{outputDir}/lcDetail_highEnergy.png")
c4.SaveAs("#{outputDir}/lcDetail_highEnergy.root")

#------------------ 2-dementional histogram ------------------
xbins=Root::DoubleArray.new(binNum+1)
(binNum+1).times do |nbin|
  xbins[nbin]=binStart+nbin.to_f*binWidth
end

energyMin=0.3
energyMax=30.0
eLogMin=log(energyMin, 10)
eLogMax=log(energyMax, 10)
ybinNum=40
ybinWidth=(eLogMax-eLogMin)/ybinNum.to_f
ybins=Root::DoubleArray.new(ybinNum+1)
(ybinNum+1).times do |nbin|
  ybins[nbin]=10**(eLogMin+nbin*ybinWidth)
end
ybins[0]=energyMin
ybins[ybinNum]=energyMax

lcEnergyDetail=Root::TH2D.create("", "", binNum, xbins, ybinNum, ybins)

for i in 0..eventNum
  eventTime=unixTime[i].to_f
  if (adcChannel==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
    energy=(energyRaw[i]+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
    if (energy>=energyMin)&&(energy<energyMax) then
      lcEnergyDetail.Fill(eventTime, energy)
    end
  end
end

c5=Root::TCanvas.create("c5", "canvas5", 640, 480)
lcEnergyDetail.SetTitle("")
lcEnergyDetail.GetXaxis().SetTitle("Time (JST)")
lcEnergyDetail.GetXaxis().SetTitleOffset(1.2)
lcEnergyDetail.GetXaxis().CenterTitle()
lcEnergyDetail.GetYaxis().SetTitle("Energy (MeV)")
lcEnergyDetail.GetYaxis().CenterTitle()
lcEnergyDetail.GetYaxis().SetTitleOffset(1.35)
lcEnergyDetail.GetXaxis().SetTimeDisplay(1)
lcEnergyDetail.GetXaxis().SetTimeFormat("%H:%M")
lcEnergyDetail.SetStats(0)
lcEnergyDetail.Draw("colz")
c5.SetLogy()
c5.Update()
c5.SaveAs("#{outputDir}/2d_detail_long.pdf")
c5.SaveAs("#{outputDir}/2d_detail_long.png")
c5.SaveAs("#{outputDir}/2d_detail_long.root")

run_app()
