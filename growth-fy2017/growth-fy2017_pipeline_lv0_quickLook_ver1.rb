#!/usr/bin/env ruby
# coding: utf-8
# growth-fy2017 pipeline level-1 Ver 1.0
# Created and maintained by Yuuki Wada
# Created on 20171127

require "json"
require "shellwords"
require "RubyFits"
require "RubyROOT"
require "tempfile"
include Math
include Fits
include Root
include RootApp

puts ""
puts "  #######################################"
puts "  ## GROWTH-PIPELINE for growth-fy2017 ##"
puts "  ##  Level-0 FITS Process  Version 1  ##"
puts "  ##        November 28th, 2017        ##"
puts "  ## Yuuki Wada  (University of Tokyo) ##"
puts "  #######################################"
puts ""

if (ARGV[0]==nil) then
  puts "Usage: ruby growth-fy2017_pipeline_lv0_quickLook_ver1.rb <fits index>"
  puts ""
  exit 1
end

pipeline_version="growth-fy2017 Ver1"
pipeline_version_short="ver1"
date=Time.now.strftime("%Y%m%d_%H%M%S")

#============================================
# Define Methods
#============================================

def prepare_folder(fitsFolderLv0, workFolder, productFolder)
  if File.exists?(fitsFolderLv0)==false then
    puts "fits files do not exist"
    exit 1
  end
  if File.exists?(workFolder)==false then
    `mkdir #{workFolder}`
  end
  if File.exists?(productFolder)==false then
    `mkdir #{productFolder}`
  end
end

#============================================
# Main
#============================================

fitsIndex=ARGV[0]
tempFitsList="#{fitsIndex}_work/fitsList_#{date}.dat"
workFolder="#{fitsIndex}_work"
productFolder="#{workFolder}/products"
fitsFolderLv0="#{fitsIndex}_fits_lv0"

prepare_folder(fitsFolderLv0, workFolder, productFolder)

`ls #{fitsFolderLv0}/ > #{tempFitsList}`

fitsList=File.open(tempFitsList, "r")
fitsLine=fitsList.readlines()
fitsName=fitsLine[0]
fitsName.chomp!
if fitsName!=nil then
  fitsHead=File.basename(fitsName, ".tar.gz")
  fits=Fits::FitsFile.new("#{fitsFolderLv0}/#{fitsName}")
  eventHDU=fits["EVENTS"]
  adcIndex=eventHDU["boardIndexAndChannel"]
  eventNum=eventHDU.getNRows()-1
  binNum=4096
  hist=Root::TH1F.create("hist", "hist", binNum, -0.5, 4095.5)
  c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
  for n in 0..3
    hist.Reset()
    for i in 0..eventNum
      if adcIndex[i].to_i==n then
        hist.Fill(eventHDU["phaMax"][i].to_i-eventHDU["phaMin"][i].to_i)
      end
    end

    hist.SetTitle("")
    hist.GetXaxis().SetTitle("Channel")
    hist.GetXaxis().SetTitleOffset(1.2)
    hist.GetXaxis().CenterTitle()
    hist.GetYaxis().SetTitle("Counts bin^{-1}")
    hist.GetYaxis().CenterTitle()
    hist.GetYaxis().SetTitleOffset(1.35)
    hist.GetXaxis().SetRangeUser(-0.5, 500.5)
    hist.SetStats(0)
    hist.Draw("e1")
    c0.SetLogy()
    c0.Update()
    c0.SaveAs("#{productFolder}/#{fitsHead}_ch#{n.to_s}_line.pdf")
  end
end
`rm #{tempFitsList}`
