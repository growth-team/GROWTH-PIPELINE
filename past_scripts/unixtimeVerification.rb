require "RubyFits"
require "RubyROOT"
require "time"
include Math
include Fits
include Root
include RootApp

unixTimeStart=Array.new
unixTimeStop=Array.new
timeTagStart=Array.new
timeTagStop=Array.new

listFileAddress=ARGV[0]
listFile=File.open(listFileAddress, "r")
listFileLine=listFile.readlines
listFileLine.each_with_index do |fitsFile, index|
  fitsFile.chomp!
  fits=FitsFile.new(fitsFile)
  eventHDU=fits.hdu("EVENTS")
  unixTime=eventHDU["unixTime"]
  timeTag=eventHDU["timeTag"]
  nRow=eventHDU.getNRows()-1
  unixTimeStart[index]=unixTime[0].to_f
  unixTimeStop[index]=unixTime[nRow].to_f
  timeTagStart[index]=timeTag[0].to_i
  timeTagStop[index]=timeTag[nRow].to_i
  puts index
end

hist=Root::TH1D.create("hist", "hist", 2001, -0.1005, 0.1005)
unixTimeStart.each_with_index do |unixTimeStart, index|
  if index>0 then
    timeDiffUnixTime=unixTimeStart-unixTimeStop[index-1]
    timeDiffTimeTag=(timeTagStart[index]-timeTagStop[index-1]).to_f/1.0e8
    hist.Fill(timeDiffUnixTime-timeDiffTimeTag)
    #    puts timeDiffUnixTime
    #    puts timeDiffTimeTag
    #    puts timeDiffUnixTime-timeDiffTimeTag
  end
end

c0=Root::TCanvas.create("c0", "canvas0", 640, 480)
hist.SetTitle("Precision of Time Calibration")
hist.GetXaxis.SetTitle("error time (sec)")
hist.GetXaxis.SetTitleOffset(1.2)
hist.GetXaxis.CenterTitle
hist.GetYaxis.SetTitle("Count")
hist.GetYaxis.CenterTitle
hist.GetYaxis.SetTitleOffset(1.35)
#hist.GetYaxis.SetRangeUser(0.5, 100000)
hist.GetXaxis.SetRangeUser(-0.1005, 0.1005)
hist.Draw()
c0.SetLogy()
c0.Update
run_app()
