#!/usr/bin/env ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if (ARGV[2]==nil) then
  puts "Usage: ruby makeSpectrum.rb <input file> <channel> <rebin>"
  exit 1
end

fitsFile=ARGV[0]
adcChannel=ARGV[1].to_i
rebin=ARGV[2].to_f

energyMin=0.1
energyMax=50.0
binNum=(2000.0/rebin).to_i
eLogMin=log(energyMin, 10)
eLogMax=log(energyMax, 10)
binWidth=(eLogMax-eLogMin)/binNum
xbins=Root::DoubleArray.new(binNum+1)
(binNum+1).times do |nbin|
  xbins[nbin]=10**(eLogMin+nbin*binWidth)
end
xbins[0]=energyMin
xbins[binNum]=energyMax
hist=Root::TH1F.create("hist", "hist", binNum, xbins)        

fits=Fits::FitsFile.new(fitsFile)
eventHDU=fits["EVENTS"]
eventNum=eventHDU.getNRows()-1
adcIndex=eventHDU["boardIndexAndChannel"]
energyRaw=eventHDU["energy"]
energyWidth_header="BINW_CH#{adcChannel}"
energyWidth=eventHDU.header(energyWidth_header).to_f

unixTimeStart=eventHDU["unixTime"][0].to_f
unixTimeLast=eventHDU["unixTime"][eventNum].to_f
observationTime=unixTimeLast-unixTimeStart

for i in 0..eventNum
  if adcIndex[i].to_i==adcChannel then
    energy=(energyRaw[i].to_f+(rand(-500..500).to_f/1000.0)*energyWidth)/1000.0
    hist.Fill(energy)
  end
end

for i in 0..binNum-1
  scale=1.0/(observationTime*(xbins[i+1]-xbins[i]))
  binScaled=(hist.GetBinContent(i+1))*scale
  binScaledError=(hist.GetBinError(i+1))*scale
  hist.SetBinContent(i+1, binScaled)
  hist.SetBinError(i+1, binScaledError)
end

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
hist.SetTitle("")
hist.GetXaxis().SetTitle("Energy (MeV)")
hist.GetXaxis().SetTitleOffset(1.2)
hist.GetXaxis().CenterTitle()
hist.GetYaxis().SetTitle("Count s^{-1} MeV^{-1}")
hist.GetYaxis().CenterTitle()
hist.GetYaxis().SetTitleOffset(1.35)
hist.GetXaxis().SetRangeUser(energyMin, energyMax)
hist.SetStats(0)
hist.Draw()
c0.SetLogx()
c0.SetLogy()
c0.Update()
run_app()
