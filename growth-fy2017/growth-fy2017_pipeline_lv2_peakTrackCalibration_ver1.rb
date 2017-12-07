#!/usr/bin/env ruby
# coding: utf-8

require "RubyROOT"
require "RubyFits"
include Math
include Root
include RootApp

if (ARGV[5]==nil) then
  puts "Usage: ruby growth-fy2017_pipeline_lv2_peakTrackCalibration_ver1.rb <fits index> <channel> <mean of peak> <energy of peak (MeV)> <resolution> <rebin>"
  exit 1
end

fitsHead=ARGV[0]
channel=ARGV[1].to_i
peak_chan=ARGV[2].to_f
peak_energy=ARGV[3].to_f
resolution=ARGV[4].to_f
rebin=ARGV[5].to_i
fitsListAddress="#{fitsHead}_work/fitslist.dat"
outputFile="#{fitsHead}_work/peakList_ch#{channel.to_s}.dat"

fitsFileNameAddress=Array.new
meanK=Array.new
meanTl=Array.new
normK=Array.new
normTl=Array.new
sigmaK=Array.new
sigmaTl=Array.new
errorMeanK=Array.new
errorMeanTl=Array.new
preFitK=Array.new
preFitTl=Array.new
fitParameterK=Array.new
fitParameterTl=Array.new
unixTime=Array.new
errorUnixTime=Array.new
meanGraphK=Array.new
meanGraphTl=Array.new

energy_K=1460.8
energy_Tl=2614.5

preFitK[1]=peak_chan*energy_K/(1.0e3*peak_energy)
preFitK[2]=preFitK[1]*resolution/2.35
preFitTl[1]=peak_chan*energy_Tl/(1.0e3*peak_energy)
preFitTl[2]=preFitTl[1]*resolution/2.35

fitLoop=5
fitRangeConstK=[1.0, 1.7]
fitRangeConstTl=[1.2, 1.7]
fitRangeK=[fitRangeConstK[0]*preFitK[2], fitRangeConstK[1]*preFitK[2]]
fitRangeTl=[fitRangeConstTl[0]*preFitTl[2], fitRangeConstTl[1]*preFitTl[2]]

binNum=4096/rebin
hist=Root::TH1F.create("h0","h0",binNum,-0.5,4095.5)
hist.GetXaxis().SetRangeUser(0, 1500)
c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
c0.SetLogy()

fitsList=File.open(fitsListAddress, "r")
fitsList.each_line.with_index do |fitsName, fitsIndex|
  fitsName.chomp!
  fitsFileNameAddress[fitsIndex]=fitsName
  fits=Fits::FitsFile.new("#{fitsHead}_fits_lv1_ver1/#{fitsName}")
  timeHDU=fits["GPS"]
  eventHDU=fits["EVENTS"]
  eventNum=eventHDU.getNRows()
  
  fpgaTimeTagStart=eventHDU["timeTag"][0].to_i
  fpgaTimeTagLast=eventHDU["timeTag"][eventNum-1].to_i
  fpgaTimeTagDiff=fpgaTimeTagLast-fpgaTimeTagStart
  if fpgaTimeTagDiff<0 then
    fpgaTimeTagDiff+=2**40-1
  end
  observationTime=fpgaTimeTagDiff.to_f/1.0e8
  unixTime[fitsIndex]=timeHDU["unixTime"][0].to_f+observationTime/2.0
  errorUnixTime[fitsIndex]=observationTime/2.0
  
  hist.Reset()
  for i in 0..(eventNum.to_i-1)
    phaMax=eventHDU["phaMax"][i].to_f
    phaMin=eventHDU["phaMin"][i].to_f
    adcIndex=eventHDU["boardIndexAndChannel"][i].to_i
    if (channel == adcIndex) then
      hist.Fill(phaMax-phaMin)
    end
  end
  hist.Draw()
  puts fitsName
  
  gaussK=Root::TF1.new("gaussK","gaus(0)", 0, 4096)
  gaussK.SetParameter(1, preFitK[1])
  gaussK.SetParLimits(1, preFitK[1]-fitRangeK[0], preFitK[1]+fitRangeK[1])
  if preFitK[0]==nil then
    gaussK.SetParameter(2, preFitK[2])
  else
    gaussK.SetParameter(0, preFitK[0])
    gaussK.SetParameter(2, preFitK[2])
  end
  fitLoop.times do
    hist.Fit("gaussK", "", "", preFitK[1]-fitRangeK[0], preFitK[1]+fitRangeK[1])
  end

  gaussPreciseK=Root::TF1.new("gaussPreciseK","gaus(0)", 0, 4095)
  for i in 0..2
    fitParameterK[i]=gaussK.GetParameter(i)
    gaussPreciseK.SetParameter(i, fitParameterK[i])
  end
  gaussPreciseK.SetParLimits(1, fitParameterK[1]-fitRangeK[0], fitParameterK[1]+fitRangeK[1])
  fitLoop.times do
    hist.Fit("gaussPreciseK", "", "", fitParameterK[1]-fitRangeK[0], fitParameterK[1]+fitRangeK[1])
  end
  for i in 0..2
    preFitK[i]=gaussPreciseK.GetParameter(i)
  end
  normK[fitsIndex]=gaussPreciseK.GetParameter(0)
  meanK[fitsIndex]=gaussPreciseK.GetParameter(1)
  sigmaK[fitsIndex]=gaussPreciseK.GetParameter(2)
  errorMeanK[fitsIndex]=gaussPreciseK.GetParError(1)
  hist.Draw()
  c0.Update
  sleep(0.3)
  
  gaussTl=Root::TF1.new("gaussTl","gaus(0)", 0, 4096)
  gaussTl.SetParameter(1, preFitTl[1])
  gaussTl.SetParLimits(1, preFitTl[1]-fitRangeTl[0], preFitTl[1]+fitRangeTl[1])
  if preFitTl[0]==nil then
    gaussTl.SetParameter(2, preFitTl[2])
  else
    gaussTl.SetParameter(0, preFitTl[0])
    gaussTl.SetParameter(2, preFitTl[2])
  end
  fitLoop.times do
    hist.Fit("gaussTl", "", "", preFitTl[1]-fitRangeTl[0], preFitTl[1]+fitRangeTl[1])
  end
  gaussPreciseTl=Root::TF1.new("gaussPreciseTl","gaus(0)", 0, 4095)
  for i in 0..2
    fitParameterTl[i]=gaussTl.GetParameter(i)
    gaussPreciseTl.SetParameter(i, fitParameterTl[i])
  end
  gaussPreciseTl.SetParLimits(1, fitParameterTl[1]-fitRangeTl[0], fitParameterTl[1]+fitRangeTl[1])
  fitLoop.times do
    hist.Fit("gaussPreciseTl", "", "", fitParameterTl[1]-fitRangeTl[0], fitParameterTl[1]+fitRangeTl[1])
  end
  for i in 0..2
    preFitTl[i]=gaussPreciseTl.GetParameter(i)    
  end
  normTl[fitsIndex]=gaussPreciseTl.GetParameter(0)
  meanTl[fitsIndex]=gaussPreciseTl.GetParameter(1)
  sigmaTl[fitsIndex]=gaussPreciseTl.GetParameter(2)
  errorMeanTl[fitsIndex]=gaussPreciseTl.GetParError(1)
  hist.Draw()
  c0.Update
end

for i in 0..fitsList.lineno-1
  meanGraphK[i]=meanK[i]
  meanGraphTl[i]=meanTl[i]
end
fitsList.close

c1=Root::TCanvas.create("c1", "canvas1", 640, 480)  
gainVariationK=Root::TGraphErrors.create(unixTime, meanGraphK, errorUnixTime, errorMeanK)
gainVariationTl=Root::TGraphErrors.create(unixTime, meanGraphTl, errorUnixTime, errorMeanTl)
gainVariationK.SetTitle("Center energy of 1460 keV and 2610 keV")
gainVariationK.GetXaxis().SetTitle("Unix Time")
gainVariationK.GetXaxis().SetTitleOffset(1.2)
gainVariationK.GetXaxis().CenterTitle()
gainVariationK.GetYaxis().SetTitle("Center Energy of 1460 keV (ch)")
gainVariationK.GetYaxis().CenterTitle()
gainVariationK.GetYaxis().SetTitleOffset(1.35)
gainVariationTl.SetLineColor(Root::KRed)
gainVariationK.Draw("ap")
gainVariationTl.Draw("same")
c1.Update()

# c1とTGraphを保存する

File.open(outputFile, "w") do |output|
  fitsFileNameAddress.each_with_index do |fitsAddress, i|
    string="#{fitsAddress.to_s}\t#{unixTime[i].to_s}\t#{errorUnixTime[i].to_s}\t#{meanGraphK[i].to_s}\t#{errorMeanK[i].to_s}\t#{meanGraphTl[i].to_s}\t#{errorMeanTl[i].to_s}"
    output.puts(string)
  end
end
