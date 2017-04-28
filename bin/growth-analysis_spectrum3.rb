#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if (ARGV[9]==nil) then
  puts "Usage: ruby growth-analysis_spectrum2.rb <input file> <bgd file 1> <bgd file 2> <channel> <event start> <event end> <bgd1 start> <bgd1 end> <bgd2 start> <bgd2 end> <output file 1> <output file 2>"
  exit 1
end

energyMin=0.8
energyMax=14.5
binNum=32
#binNum=100

eventFitsFile=ARGV[0]
bgdFitsFile=ARGV[1]
bgdFitsFile2=ARGV[2]
adcChannel=ARGV[3].to_i
eventStart=ARGV[4].to_f
eventEnd=ARGV[5].to_f
bgdStart=ARGV[6].to_f
bgdEnd=ARGV[7].to_f
bgd2Start=ARGV[8].to_f
bgd2End=ARGV[9].to_f

eventDuration=eventEnd-eventStart
bgdDuration=(bgdEnd-bgdStart)+(bgd2End-bgd2Start)

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
responseSpectrum=Root::TH1D.create("responseSpectrum", "responseSpectrum", binNum, energyMin, energyMax)

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

bgdFits2=Fits::FitsFile.new(bgdFitsFile2)
eventHDU=bgdFits2["EVENTS"]
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
    if (energy>=energyMin)&&(energy<=energyMax)&&(triggerTime>=bgd2Start)&&(triggerTime<=bgd2End) then
      bgdSpec.Fill(energy)
    end
  end
end

eventScaleFactor=binNum.to_f/(eventDuration*(energyMax-energyMin))
bgdScaleFactor=binNum.to_f/(bgdDuration*(energyMax-energyMin))
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

responseFile="/Users/yuukiwada/work/growth/mapping-kanazawa/pipeline/GROWTH-PIPELINE/bin/sakurai-bgo_response_index1.root"
rootFile=Root::TFile.open(responseFile)
response=rootFile.Get("response")

responseSpectrum.Divide(spectrum, response, 1.0/200.0, 1)

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
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
spectrum.SetLineWidth(2)
bgdSpec.SetLineWidth(2)
eventSpec.SetLineWidth(2)
bgdSpec.SetMarkerColor(2)
bgdSpec.SetLineColor(2)
bgdSpec.SetStats(0)
eventSpec.SetMarkerColor(3)
eventSpec.SetLineColor(3)
eventSpec.SetStats(0)
eventSpec.Draw("same")
bgdSpec.Draw("same")
c0.SetLogy()
c0.SetLogx()
c0.Update()

c1=Root::TCanvas.create("c1", "canvas1", 640, 480)
responseSpectrum.SetTitle("")
responseSpectrum.GetXaxis().SetTitle("Energy (MeV)")
responseSpectrum.GetXaxis().SetTitleOffset(1.15)
responseSpectrum.GetXaxis().CenterTitle()
responseSpectrum.GetYaxis().SetTitle("Folded Spectrum (Count cm^{-2} s^{-1} MeV^{-1})")
responseSpectrum.GetYaxis().CenterTitle()
responseSpectrum.GetYaxis().SetTitleOffset(1.2)
#responseSpectrum.GetYaxis().SetRangeUser(0.01, 300)
responseSpectrum.GetXaxis().SetRangeUser(energyMin, energyMax)
responseSpectrum.SetStats(0)
responseSpectrum.SetLineWidth(2)
responseSpectrum.Draw()
c1.SetLogy()
c1.SetLogx()
c1.Update()

if ARGV[10]!=nil then
  outputFile=ARGV[10]
  c0.SaveAs("#{outputFile}_raw.root")
  c0.SaveAs("#{outputFile}_raw.pdf")
  c1.SaveAs("#{outputFile}_canvas.root")

  Root::TFile.open("#{outputFile}_hist.root", "recreate") do |output|
    responseSpectrum.Write("hist")
  end
end

run_app()
