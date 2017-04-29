#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if (ARGV[6]==nil) then
  puts "Usage: ruby growth-analysis_spectrum.rb <input file> <channel> <event start> <event end> <bgd start> <bgd end>"
  exit 1
end

energyMin=0.8
energyMax=14.5
binNum=40

eventFitsFile=ARGV[0]
bgdFitsFile=ARGV[1]
adcChannel=ARGV[2].to_i
eventStart=ARGV[3].to_f
eventEnd=ARGV[4].to_f
bgdStart=ARGV[5].to_f
bgdEnd=ARGV[6].to_f

eventDuration=eventEnd-eventStart
bgdDuration=bgdEnd-bgdStart

fitsEvent=Fits::FitsFile.new(eventFitsFile)
eventHDU=fitsEvent["EVENTS"]
eventNum=eventHDU.getNRows()-1
adcIndex=eventHDU["boardIndexAndChannel"]
energyRaw=eventHDU["energy"]
unixTime=eventHDU["unixTime"]
unixTimeStart=eventHDU["unixTime"][0].to_f
unixTimeLast=eventHDU["unixTime"][eventNum].to_f
observationTime=unixTimeLast-unixTimeStart
energyWidth_header="BINW_CH#{adcChannel}"
lowEnergy_header="ETH_CH#{adcChannel}"
energyWidth=eventHDU.header(energyWidth_header).to_f
lowEnergy=eventHDU.header(lowEnergy_header).to_f/1000.0

eventSpec=Root::TH1D.create("eventSpec", "eventSpec", binNum, energyMin, energyMax)
bgdSpec=Root::TH1D.create("bgdSpec", "bgdSpec", binNum, energyMin, energyMax)
spectrum=Root::TH1D.create("spectrum", "spectrum", binNum, energyMin, energyMax)

for i in 0..eventNum
  if adcIndex[i].to_i==adcChannel then
    triggerTime=unixTime[i].to_f-unixTimeStart
    energy=(energyRaw[i].to_f+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
    if (energy>=energyMin)&&(energy<=energyMax)&&(triggerTime>=eventStart)&&(triggerTime<=eventEnd) then
      eventSpec.Fill(energy)
    end
  end
end

bgdFits=Fits::FitsFile.new(bgdFitsFile)
eventHDU=bgdFits["EVENTS"]
eventNum=eventHDU.getNRows()-1
adcIndex=eventHDU["boardIndexAndChannel"]
energyRaw=eventHDU["energy"]
unixTime=eventHDU["unixTime"]
unixTimeStart=eventHDU["unixTime"][0].to_f
unixTimeLast=eventHDU["unixTime"][eventNum].to_f
observationTime=unixTimeLast-unixTimeStart
energyWidth_header="BINW_CH#{adcChannel}"
lowEnergy_header="ETH_CH#{adcChannel}"
energyWidth=eventHDU.header(energyWidth_header).to_f
lowEnergy=eventHDU.header(lowEnergy_header).to_f/1000.0

for i in 0..eventNum
  if adcIndex[i].to_i==adcChannel then
    triggerTime=unixTime[i].to_f-unixTimeStart
    energy=(energyRaw[i].to_f+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
    if (energy>=energyMin)&&(energy<=energyMax)&&(triggerTime>=bgdStart)&&(triggerTime<=bgdEnd) then
      bgdSpec.Fill(energy)
    end
  end
end

eventScaleFactor=1.0/(eventDuration*((energyMax-energyMin)/binNum))
bgdScaleFactor=1.0/(bgdDuration*((energyMax-energyMin)/binNum))
eventSpec.Sumw2()
bgdSpec.Sumw2()
eventSpec.Scale(eventScaleFactor)
bgdSpec.Scale(bgdScaleFactor)

for i in 0..binNum-1
  specData=eventSpec.GetBinContent(i)-bgdSpec.GetBinContent(i)
  specDataError=((eventSpec.GetBinError(i))**2+(bgdSpec.GetBinError(i))**2)**0.5
  spectrum.SetBinContent(i, specData)
  spectrum.SetBinError(i, specDataError)
end

#hist.SetTitle("")
#hist.GetXaxis.SetTitle("Energy (MeV)")
#hist.GetXaxis.SetTitleOffset(1.2)
#hist.GetXaxis.CenterTitle
#hist.GetYaxis.SetTitle("Count s^{-1} MeV^{-1}")
#hist.GetYaxis.CenterTitle
#hist.GetYaxis.SetTitleOffset(1.35)
#hist.GetYaxis.SetRangeUser(0.005, 1000)
#hist.GetXaxis.SetRangeUser(0, 15)

#gStyle.SetLabelFont(132, "XYZ")
#c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
#c0.SetLogy()
#c0.Update
#c1=Root::TCanvas.create("c1", "canvas1", 640, 480)
#c1.SetLogy()
#c1.Update

c2=Root::TCanvas.create("c2", "canvas2", 640, 480)
#spectrumScaleFactor=1.0/((energyMax-energyMin)/binNum)
#spectrum.Sumw2()
#spectrum.Scale(spectrumScaleFactor)
spectrum.SetTitle("")
spectrum.GetXaxis().SetTitle("Energy (MeV)")
spectrum.GetXaxis().SetTitleOffset(1.15)
spectrum.GetXaxis().CenterTitle()
spectrum.GetYaxis().SetTitle("Count s^{-1} MeV^{-1}")
spectrum.GetYaxis().CenterTitle()
spectrum.GetYaxis().SetTitleOffset(1.2)
spectrum.GetYaxis().SetRangeUser(0.01, 300)
spectrum.GetXaxis().SetRangeUser(energyMin, energyMax)
spectrum.GetXaxis().SetTitleSize(0.04)
spectrum.GetYaxis().SetTitleSize(0.04)
spectrum.GetXaxis().SetLabelSize(0.04)
spectrum.GetYaxis().SetLabelSize(0.04)
spectrum.SetStats(0)
spectrum.Draw()
bgdSpec.SetMarkerColor(2)
bgdSpec.SetLineColor(2)
bgdSpec.SetStats(0)
eventSpec.SetMarkerColor(3)
eventSpec.SetLineColor(3)
eventSpec.SetStats(0)
eventSpec.Draw("same")
bgdSpec.Draw("same")
c2.SetLogy()
c2.SetLogx()
c2.Update()
if ARGV[7]!=nil then
  outputFile=ARGV[7]
  c2.SaveAs(outputFile)
else
  run_app()
end

