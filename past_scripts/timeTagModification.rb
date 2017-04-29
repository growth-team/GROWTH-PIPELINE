require "RubyFits"
require "time"
include Math
include Fits

listFileAddress=ARGV[0]
listFile=File.open(listFileAddress, "r")
listFileLine=listFile.readlines
listFileLine.each do |fitsFile|
  fitsFile.chomp!
  fits=FitsFile.new(fitsFile)
  eventHDU=fits.hdu("EVENTS")
  gpsHDU=fits.hdu("GPS")
  timeTag=eventHDU["timeTag"][0]
  fpgaTimeTag=gpsHDU["fpgaTimeTag"][0]
  unixTime=gpsHDU["unixTime"][0]
  gpsTime=gpsHDU["gpsTime"][0]
  unixTimeJst=Time.at(unixTime).strftime("%Y%m%d%H%M%S")
  if gpsTime[0..3]!="GP80" then
    for i in 0..10
      unixTimeUtc=Time.at(unixTime-60.0*60.0*9.0-i.to_f+5.0).strftime("%H%M%S")
      if gpsTime[8..13]==unixTimeUtc then
        #unixTimeJst=Time.at(unixTime-i.to_f+5.0).strftime("%Y%m%d%H%M%S")
        unixTimeJst=Time.at(unixTime-i.to_f+5.0)
        #puts "consistent"
        puts unixTimeJst.to_f
        break
      end
    end      
    #unixTimeJstModified=Time.strptime(gpsModified, '%Y%m%d%H%M%S')
  else
    puts "gps time not acquired"
  end
  fpgaTimeTagModified=fpgaTimeTag&0xFFFFFFFFFF
  timeTagDiff=(timeTag-fpgaTimeTagModified)/1.0e8
  if timeTagDiff>60.0 then
    timeTagDiff=(timeTag-2**40-fpgaTimeTagModified)/1.0e8
  elsif timeTagDiff<-60.0 then
    timeTagDiff=(timeTag+2**40-fpgaTimeTagModified)/1.0e8
  end
  #puts timeTagDiff
  unixTimeStart=unixTimeJst.to_f+timeTagDiff
  puts unixTimeStart
end
  #num=71389089160559
  #numLong=num & 0xFFFFFFFFFF
  #puts num
  #puts numLong
