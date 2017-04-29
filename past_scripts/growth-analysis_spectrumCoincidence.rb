#!/usr/local/bin/ruby
# coding: utf-8
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if (ARGV[3]==nil) then
  puts "Usage: ruby makeSpectrum.rb <input file> <channel> <plastic channel> <output file>"
  exit 1
end

energyMax=15.0
energyMin=1.0
binNum=50

fitsFileList=ARGV[0]
adcChannel=ARGV[1].to_i
adcPlastic=ARGV[2].to_i

h0=Root::TH1D.create("h0", "h0", binNum, energyMin, energyMax)
h1=Root::TH1D.create("h1", "h1", binNum, energyMin, energyMax)
h2=Root::TH1D.create("h2", "h2", binNum, energyMin, energyMax)
h0e=Root::TH1D.create("h0e", "h0e", binNum, energyMin, energyMax)
h1e=Root::TH1D.create("h1e", "h1e", binNum, energyMin, energyMax)
h2e=Root::TH1D.create("h2e", "h2e", binNum, energyMin, energyMax)

observationTime=0.0

File.open(fitsFileList, "r") do |fitsList|
  fitsList.each_line do |fitsFile|
    fitsFile.chomp!
    puts fitsFile
    fits=Fits::FitsFile.new(fitsFile)
    eventHDU=fits["EVENTS"]
    eventNum=eventHDU.getNRows()-1
    adcIndex=eventHDU["boardIndexAndChannel"]
    timeTag=eventHDU["timeTag"]
    energyRaw=eventHDU["energy"]
    unixTime=eventHDU["unixTime"]
    unixTimeStart=eventHDU["unixTime"][0].to_f
    unixTimeLast=eventHDU["unixTime"][eventNum].to_f
    deltaObservationTime=unixTimeLast-unixTimeStart
    observationTime+=unixTimeLast-unixTimeStart
    energyWidth_header="BINW_CH#{adcChannel}"
    lowEnergy_header="ETH_CH#{adcChannel}"
    energyWidth=eventHDU.header(energyWidth_header).to_f
    lowEnergy=eventHDU.header(lowEnergy_header).to_f/1000.0
    for i in 1..eventNum-1
      if adcIndex[i].to_i==adcChannel then
        energy=(energyRaw[i].to_f+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
        h0.Fill(energy)
        h0e.Fill(energy)
        if (energy>=lowEnergy)&&(energy<=energyMax) then
          if((timeTag[i].to_i-timeTag[i-1].to_i<100)&&(adcIndex[i-1].to_i==adcPlastic)) then
            #puts timeTag[i].to_i-timeTag[i-1].to_i
            h1.Fill(energy)
            h1e.Fill(energy)
          elsif((timeTag[i+1].to_i-timeTag[i].to_i<100)&&(adcIndex[i+1].to_i==adcPlastic)) then
            #puts timeTag[i+1].to_i-timeTag[i].to_i
            h1.Fill(energy)
            h1e.Fill(energy)
          end
        end
      end
    end
  end
end
puts observationTime

h0e.Sumw2()
h1e.Sumw2()
h2.Add(h0, h1, 1.0, -1.0)
h2e.Add(h0e, h1e, 1.0, -1.0)

scaleFactor=binNum.to_f/(observationTime*(energyMax-energyMin))
h0.Scale(scaleFactor)
h1.Scale(scaleFactor)
h2.Scale(scaleFactor)
h0e.Scale(scaleFactor)
h1e.Scale(scaleFactor)
h2e.Scale(scaleFactor)
c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
h0.SetTitle("")
h0.GetXaxis.SetTitle("Energy (MeV)")
h0.GetXaxis.SetTitleOffset(1.2)
h0.GetXaxis.CenterTitle
h0.GetYaxis.SetTitle("Count s^{-1} MeV^{-1}")
h0.GetYaxis.CenterTitle
h0.GetYaxis.SetTitleOffset(1.35)
h0.GetYaxis.SetRangeUser(1e-4, 1000)
h0.GetXaxis.SetRangeUser(1.0, 15)
h0.SetStats(0)
h1.SetLineColor(3)
h1.SetMarkerColor(3)
h2.SetLineColor(2)
h2.SetMarkerColor(2)
h0.SetLineWidth(3)
h1.SetLineWidth(3)
h2.SetLineWidth(3)
h0.Draw("")
h1.Draw("same")
h2.Draw("same")
c0.SetLogx()
c0.SetLogy()
c0.Update

if ARGV[3]!=nil
  outputFile=ARGV[3]
  c0.SaveAs("#{outputFile}_camvas.root")
  c0.SaveAs("#{outputFile}_camvas.pdf")
  Root::TFile.open("#{outputFile}_h0.root", "recreate") do |output|
    h0e.Write("h0")
  end
  Root::TFile.open("#{outputFile}_h1.root", "recreate") do |output|
    h1e.Write("h1")
  end
  Root::TFile.open("#{outputFile}_h2.root", "recreate") do |output|
    h2e.Write("h2")
  end
end
run_app()
