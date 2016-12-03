# coding: utf-8
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if (ARGV[1]==nil) then
  puts "Usage: ruby makeSpectrum.rb <input file> <channel>"
  exit 1
end

energyMax=10.0
energyMin=1.0
binNum=500

fitsFileList=ARGV[0]
adcChannel=ARGV[1].to_i

hist=Root::TH1D.create("hist", "hist", binNum, energyMin, energyMax)
observationTime=0

fitsList=File.open(fitsFileList, "r")
fitsList.each_line do |fitsFile|
  fitsFile.chomp!
  puts fitsFile
  fits=Fits::FitsFile.new(fitsFile)
  eventHDU=fits["EVENTS"]
  eventNum=eventHDU.getNRows()-1
  adcIndex=eventHDU["boardIndexAndChannel"]
  energyRaw=eventHDU["ENERGY"]
  energyRawLow=eventHDU["ENERGY_LOW"]
  energyRawHigh=eventHDU["ENERGY_HIGH"]
  unixTimeStart=eventHDU["UNIXTIME"][0].to_f
  unixTimeLast=eventHDU["UNIXTIME"][eventNum].to_f
  observationTime+=unixTimeLast-unixTimeStart
  for i in 0..eventNum
    if adcIndex[i].to_i==adcChannel then
      energy=(energyRaw[i].to_f+(rand(-5..5).to_f/5.0)*(energyRawHigh[i].to_f-energyRaw[i].to_f))/1000.0
      if (energy>=1.0)&&(energy<=10.0) then
        hist.Fill(energy)
      end
    end
  end
end
  
scaleFactor=binNum.to_f/(observationTime*(energyMax-energyMin))
hist.Scale(scaleFactor)
c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
hist.SetTitle("Spectrum")
hist.GetXaxis.SetTitle("Energy (MeV)")
hist.GetXaxis.SetTitleOffset(1.2)
hist.GetXaxis.CenterTitle
hist.GetYaxis.SetTitle("Count/s/MeV")
hist.GetYaxis.CenterTitle
hist.GetYaxis.SetTitleOffset(1.35)
hist.GetYaxis.SetRangeUser(0.005, 1000)
hist.GetXaxis.SetRangeUser(0, 15)
hist.Draw()
c0.SetLogy()
c0.Update
run_app()
