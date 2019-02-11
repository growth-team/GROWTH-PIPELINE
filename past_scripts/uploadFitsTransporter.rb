#!/usr/bin/env ruby

date=Time.now.strftime("%Y%m%d%H%M%S")
listFileAddress="fitsList_#{date}.dat"
`ls *.fits.gz > #{listFileAddress}`

fitsFile=File.open(listFileAddress, "r")
fitsFile.each_line do |fileName|
  fileName.chomp!
  fileNameParse=fileName.split("_-_")
  detectorID=fileNameParse[0]
  obsMonth=fileNameParse[1]
  obsFile=fileNameParse[2]
  obsFileFolder="../fitsFile/uploaded_raw_fits/#{detectorID}/#{obsMonth}"
  obsFileFullAddress="#{obsFileFolder}/#{obsFile}"
  if File.exist?(obsFileFullAddress)==false then
    puts obsFileFullAddress
    if File.exist?(obsFileFolder)==false then
      `mkdir -p #{obsFileFolder}`
    end
    `rsync -avr #{fileName} #{obsFileFolder}`
    `mv #{obsFileFolder}/#{fileName} #{obsFileFullAddress}`
  end
end
`rm #{listFileAddress}`
