#!/usr/local/bin/ruby
# coding: utf-8
require "json"
require "shellwords"
require "RubyFits"
require "tempfile"
include Math
include Fits

fitsIndex=ARGV[0]
caldbFile=ARGV[1]

if (ARGV[1]==nil) then
  puts "Usage: ruby growth-fy2015_pipeline_lv0.fits <fits index> <caldb file>"
  exit 1
end

date=Time.now.strftime("%Y%m%d_%H%M%S")

tempFitsList="#{fitsIndex}_work/fitsList_#{date}.dat"
errorFitsList="#{fitsIndex}_work/errorFitsList_#{date}.dat"
workFolder="#{fitsIndex}_work"
fitsFolderLv0="#{fitsIndex}_fits_lv0"
fitsFolderLv1="#{fitsIndex}_fits_lv1"

if File.exists?(workFolder)==false then
  `mkdir #{workFolder}`
end
if File.exists?(fitsFolderLv1)==false then
  `mkdir #{fitsFolderLv1}`
end

`ls #{fitsFolderLv0}/ > #{tempFitsList}`

caldbInput=File.open(caldbFile)
jsonLoad=JSON.load(caldbInput)

caldb=jsonLoad["detectorInfo"]
caldb_key=Array.new
caldb_value=Array.new

for i in 0..5
  caldb_key[i]=(caldb[i].keys)
  caldb_value[i]=(caldb[i].values)
end

errorList=File.open(errorFitsList, "a")
fitsList=File.open(tempFitsList, "r")
fitsFile=fitsList.readlines
fitsFile.each do |fitsName|
  fitsName.chomp!
  if fitsName!=nil then
    fitsAddress="#{fitsFolderLv0}/#{fitsName}"
    newFitsAddress="#{fitsFolderLv1}/#{fitsName}"
    if File.exist?(newFitsAddress)==false then
      result=`fverify #{fitsAddress} prstat=no`
      resultParse=result.split"\s"
      if resultParse[1] != "OK" then
        fits=FitsFile.new(fitsAddress)
        tempString = Tempfile.open("")
        $stdout = File.open(tempString, "w")
        puts fits
        $stdout.flush  # 対応策
        $stdout = STDOUT
        resultString=File.read(tempString)
        stringParse=resultString.split("\s")
        if stringParse[5]!="3" then
          puts "#{fitsName} error!"
          errorList.puts(fitsName)
        else
          gpsHDU=fits.hdu("GPS")
          eventNum=gpsHDU.getNRows()-1
          gpsTime=gpsHDU["gpsTime"]
          for i in 0..eventNum
            if gpsTime[i]!="NULL" then
              gpsParse=gpsTime[i]
              gpsModified=gpsParse[0..13]
              gpsTime[i]=gpsModified
            end
          end
          fits.saveAs(newFitsAddress)
          newResult=`fverify #{newFitsAddress} prstat=no`
          newResultParse=newResult.split"\s"
          if newResultParse[1] != "OK" then      
            puts "#{fitsName} error!"
            `rm #{newFitsAddress}`
            errorList.puts(fitsName)
          elsif
            newResultParse[1] == "OK" then
            puts "#{fitsName} OK!"
            eventHDU=fits.hdu("EVENTS")
            eventHDU.setHeader("PIPELINE", "level-1")
            eventHDU.setHeader("PIPELINE_LEVEL-1_DATE", date)
            for i in 0..5
              fits_key=caldb_key[i].join("")
              fits_value=caldb_value[i].join("")
              eventHDU.setHeader(fits_key, fits_value)
            end
            fits.saveAs(newFitsAddress)
          end
        end
      elsif resultParse[1] == "OK" then
        puts "#{fitsName} OK!"
        newFitsAddress="#{fitsFolderLv1}/#{fitsName}"
        fits=FitsFile.new(fitsAddress)
        eventHDU=fits.hdu("EVENTS")
        eventHDU.setHeader("PIPELINE", "level-1")
        eventHDU.setHeader("PIPELINE_LEVEL-1_DATE", date)
        for i in 0..5
          fits_key=caldb_key[i].join("")
          fits_value=caldb_value[i].join("")
          eventHDU.setHeader(fits_key, fits_value)
        end
        fits.saveAs(newFitsAddress)
      end
    end
  end
end
`rm #{tempFitsList}`

