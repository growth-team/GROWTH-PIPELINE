#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if (ARGV[3]==nil) then
  puts "Usage: ruby growth-analysis_spectrum_short.rb <input file> <channel> <event start> <duration>"
  exit 1
end

energyMin=0.4
energyMax=15.0
eLogMin=log(energyMin, 10)
eLogMax=log(energyMax, 10)
binNum=40
binWidth=(eLogMax-eLogMin)/binNum
xbins=Array.new

(binNum+1).times do |nbin|
  xbins[nbin]=10**(eLogMin+nbin*binWidth)
end

=begin
require "RubyROOT"
include Root
include RootApp

energyMin=0.1
energyMax=15.0
logEnergyMin=log(energyMin, 10)
logEnergyMax=log(energyMax, 10)
binNum=40
binWidth=(logEnergyMax-logEnergyMin)/binNum
xbins=Array.new

(binNum+1).times do |nbin|
  xbins[nbin]=10**(eLogMin+nbin*binWidth)
end

spectrum=Root::TH1D.create("spectrum", "spectrum", binNum, xbins)
=end


eventFitsFile=ARGV[0]
adcChannel=ARGV[1].to_i
eventStart=ARGV[2].to_f
eventDuration=ARGV[3].to_f

eventEnd=eventStart+eventDuration

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

#spectrum=Root::TH1D.create("spectrum", "spectrum", binNum, energyMin, energyMax)
spectrum=Root::TH1D.create("spectrum", "spectrum", binNum, xbins)

for i in 0..eventNum
  if adcIndex[i].to_i==adcChannel then
    triggerTime=unixTime[i].to_f
    energy=(energyRaw[i].to_f+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
    if (energy>=energyMin)&&(energy<=energyMax)&&(triggerTime>=eventStart)&&(triggerTime<=eventEnd) then
      spectrum.Fill(energy)
    end
  end
end

eventScaleFactor=1.0/(eventDuration*((energyMax-energyMin)/binNum))
spectrum.Sumw2()
spectrum.Scale(eventScaleFactor)

c2=Root::TCanvas.create("c2", "canvas2", 640, 480)
spectrum.SetTitle("")
spectrum.GetXaxis().SetTitle("Energy (MeV)")
spectrum.GetXaxis().SetTitleOffset(1.15)
spectrum.GetXaxis().CenterTitle()
spectrum.GetYaxis().SetTitle("Count s^{-1} MeV^{-1}")
spectrum.GetYaxis().CenterTitle()
spectrum.GetYaxis().SetTitleOffset(1.2)
spectrum.GetYaxis().SetRangeUser(0.01, 1000)
spectrum.GetXaxis().SetRangeUser(energyMin, energyMax)
spectrum.GetXaxis().SetTitleSize(0.04)
spectrum.GetYaxis().SetTitleSize(0.04)
spectrum.GetXaxis().SetLabelSize(0.04)
spectrum.GetYaxis().SetLabelSize(0.04)
spectrum.SetStats(0)
spectrum.Draw()
c2.SetLogy()
c2.SetLogx()
c2.Update()
if ARGV[4]!=nil then
  outputFile=ARGV[4]
  c2.SaveAs(outputFile)
else
  run_app()
end
