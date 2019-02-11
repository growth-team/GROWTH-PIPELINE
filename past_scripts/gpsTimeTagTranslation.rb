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
  gpsHDU=fits.hdu("GPS")
  fpgaTimeTag=gpsHDU["fpgaTimeTag"]
  unixTime=gpsHDU["unixTime"][0]
  gpsTime=gpsHDU["gpsTime"][0]
  unixTimeJst=Time.at(unixTime).strftime("%Y%m%d%H%M%S")
  if gpsTime[0..3]!="GP80" then
    for i in 0..10
      unixTimeUtc=Time.at(unixTime-60.0*60.0*9.0-i.to_f+5.0).strftime("%H%M%S")
      if gpsTime[8..13]==unixTimeUtc then
        unixTimeJst=Time.at(unixTime-i.to_f+5.0).strftime("%Y%m%d%H%M%S")
        puts "consistent"
        puts unixTimeJst
        break
      end
    end      
    #unixTimeJstModified=Time.strptime(gpsModified, '%Y%m%d%H%M%S')
  else
    puts "gps time not acquired"
  end
end
  #num=71389089160559
  #numLong=num & 0xFFFFFFFFFF
  #puts num
  #puts numLong
