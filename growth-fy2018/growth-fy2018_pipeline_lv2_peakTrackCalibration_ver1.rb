#!/usr/bin/env ruby
# coding: utf-8

require "RubyROOT"
require "RubyFits"
include Math
include Root
include RootApp
STDOUT.sync=true

if (ARGV[5]==nil) then
  puts "Usage: ruby growth-fy2018_pipeline_lv2_peakTrackCalibration_ver1.rb <fits index> <channel> <mean of peak> <energy of peak (MeV)> <resolution> <rebin>"
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
outputGraph="#{fitsHead}_work/peakTransition_ch#{channel.to_s}.pdf"

if File.exists?(outputFile)==true then
  `rm #{outputFile}`
end

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
fitRangeConstK=[0.8, 1.4]
fitRangeConstTl=[1.0, 1.4]
fitRangeK=[fitRangeConstK[0]*preFitK[2], fitRangeConstK[1]*preFitK[2]]
fitRangeTl=[fitRangeConstTl[0]*preFitTl[2], fitRangeConstTl[1]*preFitTl[2]]

binNum=4096/rebin
hist=Root::TH1F.create("h0","h0",binNum,-0.5,4095.5)
hist.GetXaxis().SetRangeUser(0, 1500)
c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
c0.SetLogy()

File.open(outputFile, "w") do |output|
  File.open(fitsListAddress, "r") do |fitsList|
    fitsList.each_line.with_index do |fitsName, fitsIndex|
      fitsName.chomp!
      if File.exist?("#{fitsHead}_fits_lv1/#{fitsName}") then
        fits=Fits::FitsFile.new("#{fitsHead}_fits_lv1/#{fitsName}")
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
        unixTime << timeHDU["unixTime"][0].to_f+observationTime/2.0
        errorUnixTime << observationTime/2.0
        wUnixTime=timeHDU["unixTime"][0].to_f+observationTime/2.0
        wErrorUnixTime=observationTime/2.0
        
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
        normK << gaussPreciseK.GetParameter(0)
        meanK << gaussPreciseK.GetParameter(1)
        sigmaK << gaussPreciseK.GetParameter(2)
        errorMeanK << gaussPreciseK.GetParError(1)
        wMeanK=gaussPreciseK.GetParameter(1)
        wErrorMeanK=gaussPreciseK.GetParError(1)
        hist.Draw()
        c0.Update()
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
        normTl << gaussPreciseTl.GetParameter(0)
        meanTl << gaussPreciseTl.GetParameter(1)
        sigmaTl << gaussPreciseTl.GetParameter(2)
        errorMeanTl << gaussPreciseTl.GetParError(1)
        wMeanTl=gaussPreciseTl.GetParameter(1)
        wErrorMeanTl=gaussPreciseTl.GetParError(1)
        hist.Draw()
        c0.Update()
        
        string="#{fitsName.to_s}\t#{wUnixTime.to_s}\t#{wErrorUnixTime.to_s}\t#{wMeanK.to_s}\t#{wErrorMeanK.to_s}\t#{wMeanTl.to_s}\t#{wErrorMeanTl.to_s}"
        output.puts(string)
      end
    end
  end
end
  
c1=Root::TCanvas.create("c1", "canvas1", 640, 480)  
gainVariationK=Root::TGraphErrors.create(unixTime, meanK, errorUnixTime, errorMeanK)
gainVariationTl=Root::TGraphErrors.create(unixTime, meanTl, errorUnixTime, errorMeanTl)
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
c1.SaveAs(outputGraph)
