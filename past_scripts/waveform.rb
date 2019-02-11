# coding: utf-8
require "RubyFits"
require "RubyROOT"
include Math
include Root
include RootApp


if (ARGV[0]==nil)||(ARGV[1]==nil) then
  puts "Usage: ruby makeSpectrum.rb <input file> <event number>"
else
  fitsFile=ARGV[0]
  adcChannel=ARGV[1].to_i
  fits=Fits::FitsFile.new(fitsFile)
  eventHDU=fits["EVENTS"]
  adcIndex=eventHDU["boardIndexAndChannel"]
  eventNum=eventHDU.getNRows()
  waveform=eventHDU["waveform"]
  waveformArray=Array.new
  waveformXaxis=Array.new
  for i in 0..619
    waveformXaxis[i]=0.02*i.to_f
    waveformArray[i]=waveform[10][i].to_f-2048.0
    puts waveformArray[i]
  end
  graph=Root::TGraph.create(waveformXaxis, waveformArray)
  graph.SetName "g0"
  c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
  graph.SetTitle("Waveform")
  graph.GetXaxis.SetTitle("Time (microSec)")
  graph.GetXaxis.SetTitleOffset(1.2)
  graph.GetXaxis.CenterTitle
  graph.GetYaxis.SetTitle("ADC channel")
  graph.GetYaxis.CenterTitle
  graph.GetYaxis.SetTitleOffset(1.35)
  #graph.GetYaxis.SetRangeUser(0.5, 10000)
  graph.GetXaxis.SetRangeUser(0, 12)
  graph.Draw("apl")
  #c0.SetLogy()
  c0.Update
  
  run_app
end
