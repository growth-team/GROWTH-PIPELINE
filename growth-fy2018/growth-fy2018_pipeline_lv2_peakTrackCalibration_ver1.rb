#!/usr/bin/env ruby
# coding: utf-8

require "RubyROOT"
require "RubyFits"
include Math
include Root
include RootApp
STDOUT.sync=true


def usage(argv)
  if (argv[5]==nil) then
    puts "Usage: ruby growth-fy2018_pipeline_lv2_peakTrackCalibration_ver1.rb <fits index> <channel> <mean of peak> <energy of peak (MeV)> <resolution> <rebin>"
    exit 1
  end
end

def remove_old_file(file)
  if File.exists?(file)==true then
  `rm #{file}`
  end
end

def set_pre_fit_parameters(energy, peakChan, peakEnergy, resolution)
  preFit=Arrayç.new(2){Array.new}
  for i in 0..1
    preFit[i][1]=peakChan*energy[i]/(1.0e3*peakEnergy)
    preFit[i][2]=preFit[i][1]*resolution/2.35
  end
  return preFit
end

def set_fit_range(const, preFit)
  fitRange=[preFit[1]-const[0]*preFit[2], preFit[1]+const[1]*preFit[2]]
  return fitRange
end

def calc_observartion_time(eventHDU, eventNum)
  fpgaTimeTagStart=eventHDU["timeTag"][0].to_i
  fpgaTimeTagLast=eventHDU["timeTag"][eventNum-1].to_i
  fpgaTimeTagDiff=fpgaTimeTagLast-fpgaTimeTagStart
  if fpgaTimeTagDiff<0 then
    fpgaTimeTagDiff+=2**40-1
  end
  observationTime=fpgaTimeTagDiff.to_f/1.0e8
  return observationTime
end

def fill_hist(hist, eventHDU, eventNum, channel)
  for i in 0..(eventNum.to_i-1)
    phaMax=eventHDU["phaMax"][i].to_f
    phaMin=eventHDU["phaMin"][i].to_f
    adcIndex=eventHDU["boardIndexAndChannel"][i].to_i
    if (channel==adcIndex) then
      hist.Fill(phaMax-phaMin)
    end
  end
end

def fit_gaussian(hist, preFit, fitRangeConst, hardLimit, fitLoopNum, norm, mean, sigma, errorMean, fitsIndex, c0)
  fitRange=set_fit_range(fitRangeConst, preFit)
  fitParameter=Array.new
  hist.Draw()
  gaus=Root::TF1.new("gaus","gaus(0)", 0, 4095)
  gausPrecise=Root::TF1.new("gausPrecise","gaus(0)", 0, 4095)

  gaus.SetParameter(1, preFit[1])
  gaus.SetParLimits(1, fitRange[0], fitRange[1])
  if preFit[0]==nil then
    gaus.SetParameter(2, preFit[2])
  else
    gaus.SetParameter(0, preFit[0])
    gaus.SetParameter(2, preFit[2])
  end
  fitLoopNum.times do
    hist.Fit("gaus", "", "", fitRange[0], fitRange[1])
  end
  
  for i in 0..2
    fitParameter[i]=gaus.GetParameter(i)
    gausPrecise.SetParameter(i, fitParameter[i])
  end
  
  fitRangePrecise=set_fit_range(fitRangeConst, fitParameter)
  gausPrecise.SetParLimits(1, fitRangePrecise[0], fitRangePrecise[1])
  fitLoopNum.times do
    hist.Fit("gausPrecise", "", "", fitRangePrecise[0], fitRangePrecise[1])
  end

  meanPrecise=gausPrecise.GetParameter(1)
  if (meanPrecise>=hardLimit[0])&&(meanPrecise<=hardLimit[1]) then
    for i in 0..2
      preFit[i]=gausPrecise.GetParameter(i)
    end
  else
    preFit[1]=(hardLimit[0]+hardLimit[1])/2.0
    preFit[2]=preFit[1]*0.15/2.35
  end
  
  norm[fitsIndex]=gausPrecise.GetParameter(0)
  mean[fitsIndex]=gausPrecise.GetParameter(1)
  sigma[fitsIndex]=gausPrecise.GetParameter(2)
  errorMean[fitsIndex]=gausPrecise.GetParError(1)
end

def set_gain_graph(unixTime, errorUnixTime, mean, errorMean)
  gain=Array.new
  for i in 0..1
    gain[i]=Root::TGraphErrors.create(unixTime, mean[i], errorUnixTime, errorMean[i])
    gain[i].SetTitle("Center energy of 1460 keV and 2610 keV")
    gain[i].GetXaxis().SetTitle("Unix Time")
    gain[i].GetXaxis().SetTitleOffset(1.2)
    gain[i].GetXaxis().CenterTitle()
    gain[i].GetYaxis().SetTitle("Center Energy of Lines (ch)")
    gain[i].GetYaxis().CenterTitle()
    gain[i].GetYaxis().SetTitleOffset(1.35)
  end
  gain[1].SetLineColor(Root::KRed)
  return gain
end

def set_hard_limit(preFit, hardLimitRes)
  hardLimit=Array.new
  for i in 0..1
    hardLimit[i]=[preFit[i][1]*(1.0-hardLimitRes), preFit[i][1]*(1.0+hardLimitRes)]
  end
  return hardLimit
end
  
# main
usage(ARGV)

# main parameter
energy=[1460.8, 2614.5] 
fitLoopNum=5
fitRangeConst=Array.new
fitRangeConst[0]=[0.6, 1.4]
fitRangeConst[1]=[0.6, 1.4] 
hardLimitRes=0.15

fitsHead=ARGV[0]
channel=ARGV[1].to_i
peakChan=ARGV[2].to_f
peakEnergy=ARGV[3].to_f
resolution=ARGV[4].to_f
rebin=ARGV[5].to_i

fitsListAddress="#{fitsHead}_work/fitslist.dat"
outputFile="#{fitsHead}_work/peakList_ch#{channel.to_s}.dat"
outputGraph="#{fitsHead}_work/peakTransition_ch#{channel.to_s}.pdf"

remove_old_file(outputFile)

fitsFileNameAddress=Array.new
mean=Array.new(2){Array.new}
norm=Array.new(2){Array.new}
sigma=Array.new(2){Array.new}
errorMean=Array.new(2){Array.new}
unixTime=Array.new
errorUnixTime=Array.new
meanGraph=Array.new(2){Array.new}

preFit=set_pre_fit_parameters(energy, peakChan, peakEnergy, resolution)
hardLimit=set_hard_limit(preFit, hardLimitRes)

binNum=4096/rebin
hist=Root::TH1F.create("h0", "h0", binNum, -0.5, 4095.5)
hist.GetXaxis().SetRangeUser(0, 1500)
c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
c0.SetLogy()
c0.Update()

File.open(outputFile, "w") do |output|
  File.open(fitsListAddress, "r") do |fitsList|
    fitsList.each_line.with_index do |fitsName, index|
      fitsName.chomp!
      if File.exist?("#{fitsHead}_fits_lv1/#{fitsName}") then
        fits=Fits::FitsFile.new("#{fitsHead}_fits_lv1/#{fitsName}")
        timeHDU=fits["GPS"]
        eventHDU=fits["EVENTS"]
        eventNum=eventHDU.getNRows()
        
        observationTime=calc_observartion_time(eventHDU, eventNum)
        if (observationTime>1200.0)&&(observationTime<2400.0) then
          unixTime[index]=timeHDU["unixTime"][0].to_f+observationTime/2.0
          errorUnixTime[index]=observationTime/2.0
        
          hist.Reset()
          fill_hist(hist, eventHDU, eventNum, channel)
          hist.Draw()
          c0.Update()
          puts fitsName
          
          gausPrecise=Array.new
          for i in 0..1
            fit_gaussian(hist, preFit[i], fitRangeConst[i], hardLimit[i], fitLoopNum, norm[i], mean[i], sigma[i], errorMean[i], index, c0)
            c0.Update()
            sleep(0.2)
          end
          string="#{fitsName}\t#{unixTime[index]}\t#{errorUnixTime[index]}\t#{mean[0][index]}\t#{errorMean[0][index]}\t#{mean[1][index]}\t#{errorMean[1][index]}"
          output.puts(string)
        end
      end
    end
  end
end
c1=Root::TCanvas.create("c1", "canvas1", 640, 480)
gainVar=set_gain_graph(unixTime, errorUnixTime, mean, errorMean)
gainVar[0].Draw("ap")
gainVar[1].Draw("same")
c1.Update()
c1.SaveAs(outputGraph)
