#!/usr/local/bin/ruby
require "RubyFits"
include Math

if (ARGV[2]==nil) then
  puts "Usage: ruby trackGainVariation.rb <fits list file> <channel> <output file name>"
  exit 1
end

fitsFileNameAddress=Array.new
unixTime=Array.new
errorUnixTime=Array.new

fitsListAddress=ARGV[0]
channel=ARGV[1].to_i
outputFile=ARGV[2]

meanK=582.994
errorMeanK=0.005
meanTl=636.208
errorMeanTl=0.011

i=0
fitsList=File.open(fitsListAddress, "r")
fitsList.each_line.with_index do |fitsName, fitsIndex|
  fitsName.chomp!
  fitsFileNameAddress[fitsIndex]=fitsName
  fits=Fits::FitsFile.new(fitsName)
  timeHDU=fits["GPS"]
  eventHDU=fits["EVENTS"]
  eventNum=eventHDU.getNRows()  
  fpgaTimeTagStart=eventHDU["timeTag"][0].to_i
  fpgaTimeTagLast=eventHDU["timeTag"][eventNum-1].to_i
  fpgaTimeTagDiff=fpgaTimeTagLast-fpgaTimeTagStart
  if fpgaTimeTagDiff<0 then
    fpgaTimeTagDiff+=2**40-1
  end
  observationTime=fpgaTimeTagDiff.to_f/(1.0*10**8)
  unixTime[fitsIndex]=timeHDU["unixTime"][0].to_f+observationTime/2.0
  errorUnixTime[fitsIndex]=observationTime/2.0
  i+=1
end
fitsList.close

File.open(outputFile, "w") do |output|
  for n in 0..i-1
    string=fitsFileNameAddress[n].to_s+"\t"+unixTime[n].to_s+"\t"+errorUnixTime[n].to_s+"\t"+meanK.to_s+"\t"+errorMeanK.to_s+"\t"+meanTl.to_s+"\t"+errorMeanTl.to_s
    output.puts(string)
  end
end
