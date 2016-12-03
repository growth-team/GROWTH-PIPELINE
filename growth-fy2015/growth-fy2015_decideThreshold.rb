#!/usr/local/bin/ruby

if (ARGV[1]==nil) then
  puts "Usage: ruby growth-fy2015_decideThreshold.rb <peak data> <threshold>"
  exit 1
end

peakFitData=ARGV[0]
thresholdChannel=ARGV[1].to_f
thresholdEnergy=0.0

fitData=File.open(peakFitData, "r")
fitData.each do |fitDataLine|
  fitDataLine.chomp!
  line=fitDataLine.split"\t"
  peak_K=line[3].to_f
  peak_Tl=line[5].to_f
  energy=1460.0+(2160.0-1460.0)*(thresholdChannel-peak_K)/(peak_Tl-peak_K)
  if energy>thresholdEnergy then
    thresholdEnergy=energy
  end
end

puts thresholdEnergy
