#!/usr/bin/env ruby
require "RubyROOT"
require "RubyFits"
include Root
include Fits
include Math

def plotSetting(hist, xtitle, ytitle)
  hist.SetTitle("")
  hist.GetXaxis().SetTitle(xtitle)
  hist.GetYaxis().SetTitle(ytitle)
  hist.SetStats(0)
  hist.Sumw2()
end

if ARGV[2]==nil then
  puts "Usage: ruby phaMin_hist.rb [ql folder] [list file] [detector name] [adc channel]"
  exit -1
end
  
ql_dir=ARGV[0]
fitsList=ARGV[1]
detector=ARGV[2]
num_chan=ARGV[3].to_i

if File.exists?("#{ql_dir}/#{detector}")==false then
  `mkdir #{ql_dir}/#{detector}`
end

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
File.open(fitsList, "r") do |list|
  list.each_line do |fitsAddress|
    fitsAddress.chomp!
    fitsAddressParse=fitsAddress.split("/")
    fitsName=fitsAddressParse[fitsAddressParse.length-1]
    fitsNameParse=fitsName.split(".")
    fitsHeader=fitsNameParse[0]

    puts fitsAddress
    
    fits=Fits::FitsFile.new(fitsAddress)
    eventHDU=fits["EVENTS"]
    phaMax=eventHDU["phaMax"]
    phaMin=eventHDU["phaMin"]
    adcIndex=eventHDU["boardIndexAndChannel"]
    eventNum=eventHDU.getNRows()-1

    binLow=1599.5
    binHigh=2100.5
    binNum=(binHigh-binLow).to_i
    unscreened=Root::TH1F.create("unscreened", "unscreened", binNum, binLow, binHigh)
    screened=Root::TH1F.create("screened", "screened", binNum, binLow, binHigh)
    
    for adc in 0..num_chan
      unscreened.Reset()
      screened.Reset()
      threshold=3800
      for i in 0..eventNum
        if adcIndex[i].to_i==adc then
          unscreened.Fill(phaMin[i].to_f)
          if phaMax[i].to_i<threshold then
            screened.Fill(phaMin[i].to_f)
          end
        end
      end
      plotSetting(unscreened, "channel", "count")
      plotSetting(screened, "channel", "count")

      unscreened.Draw("")
      c0.SetLogy(1)
      c0.Update()
      c0.SaveAs("#{ql_dir}/#{detector}/#{fitsHeader}_ch#{adc.to_s}_phaMin_unscreened.pdf")
      screened.Draw("")
      c0.SetLogy(1)
      c0.Update()
      c0.SaveAs("#{ql_dir}/#{detector}/#{fitsHeader}_ch#{adc.to_s}_phaMin_screened.pdf")
    end
  end
end
