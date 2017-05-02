#!/usr/bin/env ruby
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp

fitsFile=ARGV[0]
detectorID=ARGV[1]
adcChannel=ARGV[2].to_i
eventStart=ARGV[3].to_f
outputDir=ARGV[4]

energyLimitsLow=0.2
energyLimitsHigh=30.0
energyPositronLow=0.45
energyPositronHigh=0.55
limitLong=1800
limitShort=300
limitTrigger=400
limitPositron=200

fits=Fits::FitsFile.new(fitsFile)
eventHDU=fits["EVENTS"]
adcIndex=eventHDU["boardIndexAndChannel"]
energyRaw=eventHDU["energy"]
unixTime=eventHDU["unixTime"]
energyWidth_header="BINW_CH#{adcChannel[detNum]}"
energyWidth=eventHDU.header(energyWidth_header).to_f
eventNum=eventHDU.getNRows()-1

#------------------ lighcurve of short period ------------------
binWidth=0.01
startTime=-0.2
endTime=1.0
duration=endTime-startTime
binNum=(duration/binWidth).to_i
binStart=startTime
binEnd=startTime+binWidth*binNum.to_f

lcShort=Root::TH1D.create("", "", binNum, binStart, binEnd)

for i in 0..eventNum
  eventTime=unixTime[i].to_f-eventStart
  if (adcChannel==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
    energy=(energyRaw[i]+(rand(-500..500).to_f/1000.0)*energyWidth)/1000.0
    if (energy>=energyLimitsLow)&&(energy<energyLimitsHigh) then
      lcShort.Fill(eventTime)
    end
  end
end

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
lcShort.Sumw2()
lcShort.SetTitle("")
lcShort.GetXaxis.SetTitle("Second from Shortburst")
lcShort.GetXaxis.SetTitleOffset(1.2)
lcShort.GetXaxis.CenterTitle
lcShort.GetXaxis.SetRangeUser(binStart, binEnd)
lcShort.GetYaxis.SetTitle("Count bin^{-1}")
lcShort.GetYaxis.CenterTitle
lcShort.GetYaxis.SetTitleOffset(1.35)
lcShort.GetYaxis.SetRangeUser(0, limitShort[detNum])
lcShort.SetStats(0)
lcShort.Draw("e1")
c0.Update()
c0.SaveAs("#{outputDir}/lc_short.pdf")
c0.SaveAs("#{outputDir}/lc_short.png")
c0.SaveAs("#{outputDir}/lc_short.root")

#------------------ modified lighcurve with trigger count ------------------
triggerCountCh=eventHDU["triggerCount"]
lcShortAll=Root::TH1D.create("", "", binNum, binStart, binEnd)
lcTriggerTag=Root::TH1D.create("", "", binNum, binStart, binEnd)
channelIndex=0
triggerCount=Array.new
unixTimeChannel=Array.new
for i in 0..eventNum-1
  if adcChannel==adcIndex[i].to_i then
    triggerCount[channelIndex]=triggerCountCh[i].to_i
    unixTimeChannel[channelIndex]=unixTime[i].to_f-eventStart
    channelIndex+=1
  end
end
for i in 0..channelIndex-2
  if triggerCount[i+1]<triggerCount[i] then
    deltaTriggerCount=triggerCount[i+1]-triggerCount[i]+2**16
  else
    deltaTriggerCount=triggerCount[i+1]-triggerCount[i]
  end
  (deltaTriggerCount-1).times do
    lcTriggerTag.Fill(unixTimeChannel[i])
    if unixTimeChannel[i]<0.08 then
      lcShortAll.Fill(unixTimeChannel[i])
    end
  end
end
for i in 0..eventNum
  eventTime=unixTime[i].to_f-eventStart
  if (adcChannel[detNum]==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
    energy=(energyRaw[i]+(rand(-500..500).to_f/1000.0)*energyWidth)/1000.0
    if (energy>=energyLimitsLow)&&(energy<energyLimitsHigh) then
      lcShortAll.Fill(eventTime)
    end
  end
end

c1=Root::TCanvas.create("c1", "canvas0", 640, 480)
lcShortAll.Sumw2()
lcShortAll.SetTitle("")
lcShortAll.GetXaxis.SetTitle("Second from Shortburst")
lcShortAll.GetXaxis.SetTitleOffset(1.2)
lcShortAll.GetXaxis.CenterTitle
lcShortAll.GetXaxis.SetRangeUser(binStart, binEnd)
lcShortAll.GetYaxis.SetTitle("Count bin^{-1}")
lcShortAll.GetYaxis.CenterTitle
lcShortAll.GetYaxis.SetTitleOffset(1.35)
lcShortAll.GetYaxis.SetRangeUser(0, limitShort[detNum])
lcShortAll.SetStats(0)
lcShortAll.Draw("e1")
c1.Update()
c1.SaveAs("#{outputDir}/lc_short_modified.pdf")
c1.SaveAs("#{outputDir}/lc_short_modified.png")
c1.SaveAs("#{outputDir}/lc_short_modified.root")

c2=Root::TCanvas.create("c2", "canvas0", 640, 480)
    lcTriggerTag.Sumw2()
    lcTriggerTag.SetTitle("")
    lcTriggerTag.GetXaxis.SetTitle("Second from Shortburst")
    lcTriggerTag.GetXaxis.SetTitleOffset(1.2)
    lcTriggerTag.GetXaxis.CenterTitle
    lcTriggerTag.GetXaxis.SetRangeUser(binStart, binEnd)
    lcTriggerTag.GetYaxis.SetTitle("Count bin^{-1}")
    lcTriggerTag.GetYaxis.CenterTitle
    lcTriggerTag.GetYaxis.SetTitleOffset(1.35)
    lcTriggerTag.GetYaxis.SetRangeUser(0, limitTrigger[detNum])
    lcTriggerTag.SetStats(0)
    lcTriggerTag.Draw("e1")
    c2.Update()
    c2.SaveAs("products/#{detectorID[detNum]}_lc_trigger.pdf")
    c2.SaveAs("products/#{detectorID[detNum]}_lc_trigger.png")
    c2.SaveAs("products/#{detectorID[detNum]}_lc_trigger.root")
  end

  #------------------ lighcurve of long period ------------------
  binWidth=1.0
  startTime=-60.0
  endTime=120.0
  duration=endTime-startTime
  binNum=(duration/binWidth).to_i
  binStart=startTime
  binEnd=startTime+binWidth*binNum.to_f
  
  lcLong=Root::TH1D.create("", "", binNum, binStart, binEnd)

  for i in 0..eventNum
    eventTime=unixTime[i].to_f-eventStart[detNum]
    if (adcChannel[detNum]==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
      energy=(energyRaw[i]+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
      if (energy>=energyLimitsLow[detNum])&&(energy<energyLimitsHigh[detNum]) then
        lcLong.Fill(eventTime)
      end
    end
  end

  c3=Root::TCanvas.create("c3", "canvas3", 640, 480)
  lcLong.Sumw2()
  lcLong.SetTitle("")
  lcLong.GetXaxis.SetTitle("Second from Shortburst")
  lcLong.GetXaxis.SetTitleOffset(1.2)
  lcLong.GetXaxis.CenterTitle
  lcLong.GetXaxis.SetRangeUser(binStart, binEnd)
  lcLong.GetYaxis.SetTitle("Count s^{-1}")
  lcLong.GetYaxis.CenterTitle
  lcLong.GetYaxis.SetTitleOffset(1.35)
  lcLong.GetYaxis.SetRangeUser(0, limitLong[detNum])
  lcLong.SetStats(0)
  lcLong.Draw("e1")
  c3.Update()
  c3.SaveAs("products/#{detectorID[detNum]}_lc_long.pdf")
  c3.SaveAs("products/#{detectorID[detNum]}_lc_long.png")
  c3.SaveAs("products/#{detectorID[detNum]}_lc_long.root")

  #------------------ 2-dementional histogram of short period ------------------
  xbinWidth=0.01
  startTime=-0.2
  endTime=1.0
  duration=endTime-startTime
  xbinNum=(duration/xbinWidth).to_i
  binStart=startTime
  binEnd=startTime+xbinWidth*xbinNum.to_f
  xbins=Root::DoubleArray.new(xbinNum+1)
  (xbinNum+1).times do |nbin|
    xbins[nbin]=startTime+nbin*xbinWidth
  end
  
  energyMin=0.2
  energyMax=15.0
  eLogMin=log(energyMin, 10)
  eLogMax=log(energyMax, 10)
  ybinNum=30
  ybinWidth=(eLogMax-eLogMin)/ybinNum.to_f
  ybins=Root::DoubleArray.new(ybinNum+1)
  (ybinNum+1).times do |nbin|
    ybins[nbin]=10**(eLogMin+nbin*ybinWidth)
  end
  ybins[0]=energyMin
  ybins[ybinNum]=energyMax

  lcShortEnergy=Root::TH2D.create("", "", xbinNum, xbins, ybinNum, ybins)

  for i in 0..eventNum
    eventTime=unixTime[i].to_f-eventStart[detNum]
    if (adcChannel[detNum]==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
      energy=(energyRaw[i]+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
      if (energy>=energyMin)&&(energy<energyMax) then
        lcShortEnergy.Fill(eventTime, energy)
      end
    end
  end

  c4=Root::TCanvas.create("c4", "canvas4", 640, 480)
  lcShortEnergy.SetTitle("")
  lcShortEnergy.GetXaxis.SetTitle("Second from Shortburst")
  lcShortEnergy.GetXaxis.SetTitleOffset(1.2)
  lcShortEnergy.GetXaxis.CenterTitle
  lcShortEnergy.GetYaxis.SetTitle("Energy (MeV)")
  lcShortEnergy.GetYaxis.CenterTitle
  lcShortEnergy.GetYaxis.SetTitleOffset(1.35)
  lcShortEnergy.SetStats(0)
  lcShortEnergy.Draw("colz")
  c4.SetLogy()
  c4.Update()
  c4.SaveAs("products/#{detectorID[detNum]}_2d_short.pdf")
  c4.SaveAs("products/#{detectorID[detNum]}_2d_short.png")
  c4.SaveAs("products/#{detectorID[detNum]}_2d_short.root")

  #------------------ 2-dementional histogram of long period ------------------
  xbinWidth=1.0
  startTime=-60.0
  endTime=120.0
  duration=endTime-startTime
  xbinNum=(duration/xbinWidth).to_i
  binStart=startTime
  binEnd=startTime+xbinWidth*xbinNum.to_f
  xbins=Root::DoubleArray.new(xbinNum+1)
  (xbinNum+1).times do |nbin|
    xbins[nbin]=startTime+nbin.to_f*xbinWidth
  end
  
  energyMin=0.2
  energyMax=15.0
  eLogMin=log(energyMin, 10)
  eLogMax=log(energyMax, 10)
  ybinNum=30
  ybinWidth=(eLogMax-eLogMin)/ybinNum.to_f
  ybins=Root::DoubleArray.new(ybinNum+1)
  (ybinNum+1).times do |nbin|
    ybins[nbin]=10**(eLogMin+nbin*ybinWidth)
  end
  ybins[0]=energyMin
  ybins[ybinNum]=energyMax

  lcLongEnergy=Root::TH2D.create("", "", xbinNum, xbins, ybinNum, ybins)

  for i in 0..eventNum
    eventTime=unixTime[i].to_f-eventStart[detNum]
    if (adcChannel[detNum]==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
      energy=(energyRaw[i]+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
      if (energy>=energyMin)&&(energy<energyMax) then
        lcLongEnergy.Fill(eventTime, energy)
      end
    end
  end

  c5=Root::TCanvas.create("c5", "canvas5", 640, 480)
  lcLongEnergy.SetTitle("")
  lcLongEnergy.GetXaxis.SetTitle("Second from Shortburst")
  lcLongEnergy.GetXaxis.SetTitleOffset(1.2)
  lcLongEnergy.GetXaxis.CenterTitle
  lcLongEnergy.GetYaxis.SetTitle("Energy (MeV)")
  lcLongEnergy.GetYaxis.CenterTitle
  lcLongEnergy.GetYaxis.SetTitleOffset(1.35)
  lcLongEnergy.SetStats(0)
  lcLongEnergy.Draw("colz")
  c5.SetLogy()
  c5.Update()
  c5.SaveAs("products/#{detectorID[detNum]}_2d_long.pdf")
  c5.SaveAs("products/#{detectorID[detNum]}_2d_long.png")
  c5.SaveAs("products/#{detectorID[detNum]}_2d_long.root")

  #------------------ lightcurve of long period in the range of 0.4-0.6 MeV ------------------
  if (detNum==0)||(detNum==1)||(detNum==2) then
    binWidth=1.0
    startTime=-60.0
    endTime=120.0
    duration=endTime-startTime
    binNum=(duration/binWidth).to_i
    binStart=startTime
    binEnd=startTime+binWidth*binNum.to_f
    
    lcLongPositron=Root::TH1D.create("", "", binNum, binStart, binEnd)
    
    for i in 0..eventNum
      eventTime=unixTime[i].to_f-eventStart[detNum]
      if (adcChannel[detNum]==adcIndex[i].to_i)&&(eventTime>=binStart)&&(eventTime<=binEnd) then
        energy=(energyRaw[i]+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
        if (energy>energyPositronLow)&&(energy<energyPositronHigh) then
          lcLongPositron.Fill(eventTime)
        end
      end
    end
    
    c6=Root::TCanvas.create("c6", "canvas6", 640, 480)
    lcLongPositron.Sumw2()
    lcLongPositron.SetTitle("")
    lcLongPositron.GetXaxis.SetTitle("Second from Shortburst")
    lcLongPositron.GetXaxis.SetTitleOffset(1.2)
    lcLongPositron.GetXaxis.CenterTitle
    lcLongPositron.GetXaxis.SetRangeUser(binStart, binEnd)
    lcLongPositron.GetYaxis.SetTitle("Count bin^{-1}")
    lcLongPositron.GetYaxis.CenterTitle
    lcLongPositron.GetYaxis.SetTitleOffset(1.35)
    lcLongPositron.GetYaxis.SetRangeUser(0, limitPositron[detNum])
    lcLongPositron.SetStats(0)
    lcLongPositron.Draw("e1")
    c6.Update()
    c6.SaveAs("products/#{detectorID[detNum]}_lc_long_positron.pdf")
    c6.SaveAs("products/#{detectorID[detNum]}_lc_long_positron.png")
    c6.SaveAs("products/#{detectorID[detNum]}_lc_long_positron.root")
  end

  #---------------- short term spectrum of plastic scintillator ----------------
  sourceStart=0.05
  sourceDuration=0.3
  sourceEnd=sourceStart+sourceDuration

  energyMin=0.2
  energyMax=15.0
  eLogMin=log(energyMin, 10)
  eLogMax=log(energyMax, 10)
  ybinNum=64
  ybinWidth=(eLogMax-eLogMin)/ybinNum.to_f
  ybins=Root::DoubleArray.new(ybinNum+1)
  (ybinNum+1).times do |nbin|
    ybins[nbin]=10**(eLogMin+nbin*ybinWidth)
  end
  ybins[0]=energyMin
  ybins[ybinNum]=energyMax

  shortSpectrum=Root::TH1D.create("", "", ybinNum, ybins)

  for i in 0..eventNum
    eventTime=unixTime[i].to_f-eventStart[detNum]
    if (adcChannel[detNum]==adcIndex[i].to_i)&&(eventTime>=sourceStart)&&(eventTime<=sourceEnd) then
      energy=(energyRaw[i]+(rand(-5..5).to_f/10.0)*energyWidth)/1000.0
      if (energy>=energyMin)&&(energy<energyMax) then
        shortSpectrum.Fill(energy)
      end
    end
  end
  shortSpectrum.Sumw2()
  for i in 0..ybinNum-1
    eventScaleFactor=1.0/(sourceDuration*(ybins[i+1]-ybins[i]))
    eventBinScaled=(shortSpectrum.GetBinContent(i+1))*eventScaleFactor
    eventBinScaledError=(shortSpectrum.GetBinError(i+1))*eventScaleFactor
    shortSpectrum.SetBinContent(i+1, eventBinScaled)
    shortSpectrum.SetBinError(i+1, eventBinScaledError)
  end

  c7=Root::TCanvas.create("c7", "canvas7", 640, 480)
  shortSpectrum.SetTitle("")
  shortSpectrum.GetXaxis().SetTitle("Energy (MeV)")
  shortSpectrum.GetXaxis().SetTitleOffset(1.15)
  shortSpectrum.GetXaxis().CenterTitle()
  shortSpectrum.GetYaxis().SetTitle("Count s^{-1} MeV^{-1}")
  shortSpectrum.GetYaxis().CenterTitle()
  shortSpectrum.GetYaxis().SetTitleOffset(1.2)
  shortSpectrum.GetXaxis().SetTitleSize(0.04)
  shortSpectrum.GetYaxis().SetTitleSize(0.04)
  shortSpectrum.GetXaxis().SetLabelSize(0.04)
  shortSpectrum.GetYaxis().SetLabelSize(0.04)
  shortSpectrum.SetStats(0)
  shortSpectrum.Draw()
  c7.SetLogx()
  c7.SetLogy()
  c7.Update() 
  c7.SaveAs("products/#{detectorID[detNum]}_spec_short.pdf")
  c7.SaveAs("products/#{detectorID[detNum]}_spec_short.png")
  c7.SaveAs("products/#{detectorID[detNum]}_spec_short.root")
  
end
run_app()
