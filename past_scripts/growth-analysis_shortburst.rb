#!/usr/local/bin/ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

if ARGV[4]==nil then
  puts "Usage: ruby growth-analysis_shortburst.rb <fits file> <adc channel> <event time (unixTime)> <title second> <file header>"
  exit 1
end

fitsFileAddress=ARGV[0]
adcChannel=ARGV[1].to_i
eventTime=ARGV[2].to_f
titleSecond=ARGV[3]
fileHeader=ARGV[4]

binWidth=0.001
rebin=64
energyLimitsLow_low=1.0
energyLimitsLow_high=3.0
energyLimitsHigh=30.0
duration_before=0.05
duration_after=0.2
duration=duration_before+duration_after

fits=Fits::FitsFile.new(fitsFileAddress)
eventHDU=fits["EVENTS"]
adcIndex=eventHDU["boardIndexAndChannel"]
energyRaw=eventHDU["energy"]
phaMax=eventHDU["phaMax"]
phaMin=eventHDU["phaMin"]
maxDerivative=eventHDU["maxDerivative"]
triggerCount=eventHDU["triggerCount"]
unixTime=eventHDU["unixTime"]
energyWidth_header="BINW_CH#{adcChannel}"
energyWidth=eventHDU.header(energyWidth_header).to_f
eventNum=eventHDU.getNRows()-1

binStart=eventTime-duration_before
binEnd=eventTime+duration_after
binNum=(duration/binWidth).to_i

lightCurve_low=Root::TH1D.create("", "", binNum, binStart, binEnd)
lightCurve_high=Root::TH1D.create("", "", binNum, binStart, binEnd)
deltaTriggerCountCurve=Root::TH1D.create("", "", binNum, binStart, binEnd)
energyCurve=Root::TH2D.create("", "", binNum, binStart, binEnd, 300, 0.0, 30.0)
phaMaxHist=Root::TH2D.create("", "", binNum, binStart, binEnd, 4096/rebin, 0.0, 4096.0)
phaMinHist=Root::TH2D.create("", "", binNum, binStart, binEnd, 4096/rebin, 0.0, 4096.0)
phaMax_Min=Root::TH2D.create("", "", binNum, binStart, binEnd, 4096/rebin, 0.0, 4096.0)
phaMax_phaMin=Root::TH2D.create("", "", 4096, 0.0, 4096.0, 4096, 0.0, 4096.0)
phaMax_maxDerivative=Root::TH2D.create("", "", 4096, 0.0, 4096.0, 100, 0.0, 100.0)

for i in 0..eventNum
  if (adcChannel==adcIndex[i].to_i)&&(unixTime[i]>=binStart)&&(unixTime[i]<=binEnd) then
    phaMaxHist.Fill(unixTime[i].to_f, phaMax[i].to_f)
    phaMinHist.Fill(unixTime[i].to_f, phaMin[i].to_f)
    phaMax_Min.Fill(unixTime[i].to_f, phaMax[i].to_f-phaMin[i].to_f)
    energy=(energyRaw[i]+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
    energyCurve.Fill(unixTime[i].to_f, energy)
    phaMax_phaMin.Fill(phaMax[i].to_f, phaMin[i].to_f)
    phaMax_maxDerivative.Fill(phaMax[i].to_f, maxDerivative[i].to_f)
    (triggerCount[i].to_i-triggerCount[i-1].to_i-1).times do |trigger|
          deltaTriggerCountCurve.Fill(unixTime[i].to_f)
    end
    if (energy>=energyLimitsLow_low)&&(energy<energyLimitsHigh) then
      lightCurve_low.Fill(unixTime[i].to_f)
    end
    if (energy>=energyLimitsLow_high)&&(energy<energyLimitsHigh) then
      lightCurve_high.Fill(unixTime[i].to_f)
    end
  end
end

gStyle.SetNdivisions(512)
#gStyle.SetPalette(53)
lightCurve_low.SetStats(0)
lightCurve_low.GetYaxis().SetRangeUser(0, 30)
lightCurve_low.GetXaxis().SetTimeDisplay(1)
lightCurve_low.GetXaxis().SetTimeFormat("%S")
lightCurve_low.GetXaxis().SetTitle("Second from #{titleSecond}")
lightCurve_low.GetYaxis().SetTitle("count bin^{-1}")
lightCurve_low.GetXaxis().SetTitle("Second from #{titleSecond}")
lightCurve_low.GetXaxis().SetTitleOffset(1.0)
lightCurve_low.GetYaxis().SetTitleOffset(1.35)

lightCurve_high.SetStats(0)
lightCurve_high.GetYaxis().SetRangeUser(0, 30)
lightCurve_high.GetXaxis().SetTimeDisplay(1)
lightCurve_high.GetXaxis().SetTimeFormat("%S")
lightCurve_high.GetXaxis().SetTitle("Second from #{titleSecond}")
lightCurve_high.GetYaxis().SetTitle("count bin^{-1}")
lightCurve_high.GetXaxis().SetTitleOffset(1.0)
lightCurve_high.GetYaxis().SetTitleOffset(1.35)

deltaTriggerCountCurve.SetStats(0)
deltaTriggerCountCurve.GetXaxis().SetTimeDisplay(1)
deltaTriggerCountCurve.GetXaxis().SetTimeFormat("%S")
deltaTriggerCountCurve.GetZaxis().SetRangeUser(0.5, 400)
deltaTriggerCountCurve.GetXaxis().SetTitle("Second from #{titleSecond}")
deltaTriggerCountCurve.GetYaxis().SetTitle("Delta Trigger Count")
deltaTriggerCountCurve.GetXaxis().SetTitleOffset(1.0)
deltaTriggerCountCurve.GetYaxis().SetTitleOffset(1.35)

energyCurve.SetStats(0)
energyCurve.GetXaxis().SetTimeDisplay(1)
energyCurve.GetXaxis().SetTimeFormat("%S")
energyCurve.GetZaxis().SetRangeUser(0, 10)
energyCurve.GetXaxis().SetTitle("Second from #{titleSecond}")
energyCurve.GetYaxis().SetTitle("Energy (MeV)")
energyCurve.GetXaxis().SetTitleOffset(1.0)
energyCurve.GetYaxis().SetTitleOffset(1.35)

phaMaxHist.SetStats(0)
phaMaxHist.GetXaxis().SetTimeDisplay(1)
phaMaxHist.GetXaxis().SetTimeFormat("%S")
phaMaxHist.GetZaxis().SetRangeUser(0, 10)
phaMaxHist.GetXaxis().SetTitle("Second from #{titleSecond}")
phaMaxHist.GetYaxis().SetTitle("phaMax")
phaMaxHist.GetXaxis().SetTitleOffset(1.0)
phaMaxHist.GetYaxis().SetTitleOffset(1.35)

phaMinHist.SetStats(0)
phaMinHist.GetXaxis().SetTimeDisplay(1)
phaMinHist.GetXaxis().SetTimeFormat("%S")
phaMinHist.GetZaxis().SetRangeUser(0, 10)
phaMinHist.GetXaxis().SetTitle("Second from #{titleSecond}")
phaMinHist.GetYaxis().SetTitle("phaMin")
phaMinHist.GetXaxis().SetTitleOffset(1.0)
phaMinHist.GetYaxis().SetTitleOffset(1.35)

phaMax_Min.SetStats(0)
phaMax_Min.GetXaxis().SetTimeDisplay(1)
phaMax_Min.GetXaxis().SetTimeFormat("%S")
phaMax_Min.GetZaxis().SetRangeUser(0, 10)
phaMax_Min.GetXaxis().SetTitle("Second from #{titleSecond}")
phaMax_Min.GetYaxis().SetTitle("phaMax-phaMin")
phaMax_Min.GetXaxis().SetTitleOffset(1.0)
phaMax_Min.GetYaxis().SetTitleOffset(1.35)

phaMax_Min.SetStats(0)
phaMax_Min.GetXaxis().SetTimeDisplay(1)
phaMax_Min.GetXaxis().SetTimeFormat("%S")
phaMax_Min.GetZaxis().SetRangeUser(0, 10)
phaMax_Min.GetXaxis().SetTitle("Second from #{titleSecond}")
phaMax_Min.GetYaxis().SetTitle("phaMax-phaMin")
phaMax_Min.GetXaxis().SetTitleOffset(1.0)
phaMax_Min.GetYaxis().SetTitleOffset(1.35)

phaMax_phaMin.SetStats(0)
phaMax_phaMin.GetZaxis().SetRangeUser(0, 10)
phaMax_phaMin.GetXaxis().SetTitle("phaMax")
phaMax_phaMin.GetYaxis().SetTitle("phaMin")
phaMax_phaMin.GetXaxis().SetTitleOffset(1.0)
phaMax_phaMin.GetYaxis().SetTitleOffset(1.35)

phaMax_maxDerivative.SetStats(0)
phaMax_maxDerivative.GetXaxis().SetTimeDisplay(1)
phaMax_maxDerivative.GetXaxis().SetTimeFormat("%S")
phaMax_maxDerivative.GetYaxis().SetRangeUser(0, 100)
phaMax_maxDerivative.GetZaxis().SetRangeUser(0, 80)
phaMax_maxDerivative.GetXaxis().SetTitle("Second from #{titleSecond}")
phaMax_maxDerivative.GetYaxis().SetTitle("maxDerivative")
phaMax_maxDerivative.GetXaxis().SetTitleOffset(1.0)
phaMax_maxDerivative.GetYaxis().SetTitleOffset(1.35)

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
lightCurve_low.Draw("e1")
c0.Update()
c1=Root::TCanvas.create("c1", "canvas1", 640, 480)
lightCurve_high.Draw("e1")
c1.Update()
c2=Root::TCanvas.create("c2", "canvas2", 640, 480)
energyCurve.Draw("colz")
c2.Update()
c3=Root::TCanvas.create("c3", "canvas3", 640, 480)
phaMaxHist.Draw("colz")
c3.Update()
c4=Root::TCanvas.create("c4", "canvas4", 640, 480)
phaMinHist.Draw("colz")
c4.Update()
c5=Root::TCanvas.create("c5", "canvas5", 640, 480)
phaMax_Min.Draw("colz")
c5.Update()
c6=Root::TCanvas.create("c6", "canvas6", 640, 480)
deltaTriggerCountCurve.Draw("")
c6.SetLogy()
c6.Update()
c7=Root::TCanvas.create("c7", "canvas7", 640, 480)
phaMax_phaMin.Draw("colz")
c7.Update()
c8=Root::TCanvas.create("c8", "canvas8", 640, 480)
phaMax_maxDerivative.Draw("colz")
c8.Update()

c0.SaveAs("#{fileHeader}_lightCurve_low.pdf")
c1.SaveAs("#{fileHeader}_lightCurve_high.pdf")
c2.SaveAs("#{fileHeader}_energyCurve.pdf")
c3.SaveAs("#{fileHeader}_phaMaxHist.pdf")
c4.SaveAs("#{fileHeader}_phaMinHist.pdf")
c5.SaveAs("#{fileHeader}_phaMax-Min.pdf")
c6.SaveAs("#{fileHeader}_deltaTriggerCount.pdf")
c7.SaveAs("#{fileHeader}_phaMax_phaMin.pdf")
c8.SaveAs("#{fileHeader}_phaMax_maxDerivative.pdf")
#run_app()
