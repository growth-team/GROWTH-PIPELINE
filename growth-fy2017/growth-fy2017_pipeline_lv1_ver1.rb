#!/usr/bin/env ruby
# coding: utf-8
# growth-fy2017 pipeline level-1 Ver 1.0
# Created and maintained by Yuuki Wada
# Created on 20171127

require "json"
require "shellwords"
require "RubyFits"
require "tempfile"
include Math
include Fits

puts ""
puts "  #######################################"
puts "  ## GROWTH-PIPELINE for growth-fy2017 ##"
puts "  ##  Level-1 FITS Process  Version 1  ##"
puts "  ##        November 27th, 2017        ##"
puts "  ## Yuuki Wada  (University of Tokyo) ##"
puts "  #######################################"
puts ""

if (ARGV[1]==nil) then
  puts "Usage: ruby growth-fy2017_pipeline_lv1_ver1.rb <fits index> <caldb file>"
  puts ""
  exit 1
end

pipeline_version="growth-fy2017 Ver1"
pipeline_version_short="ver1"

fitsIndex=ARGV[0]
caldbFile=ARGV[1]
date=Time.now.strftime("%Y%m%d_%H%M%S")

tempFitsList="#{fitsIndex}_work/fitslist.dat"
errorFitsList="#{fitsIndex}_work/errorFitsList_#{date}.dat"
workFolder="#{fitsIndex}_work"
fitsFolderLv0="#{fitsIndex}_fits_lv0"
fitsFolderLv1="#{fitsIndex}_fits_lv1_#{pipeline_version_short}"

if File.exists?(fitsFolderLv0)==false then
  puts "fits files do not exist"
  exit 1
end

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

for i in 0..7
  caldb_key[i]=(caldb[i].keys)
  caldb_value[i]=(caldb[i].values)
end

caldb_comment=Array.new
caldb_comment[0]="detector ID"
caldb_comment[1]="observation site"
caldb_comment[2]="scintillator ID of Channel 0"
caldb_comment[3]="scintillator ID of Channel 1"
caldb_comment[4]="scintillator ID of Channel 2"
caldb_comment[5]="scintillator ID of Channel 3"
caldb_comment[6]="installation date"
caldb_comment[7]="removal date"

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
        $stdout.flush
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
            eventHDU.setHeader("PL1_DATE", "#{date}")
            eventHDU.setHeader("PL1_VER", "#{pipeline_version}")
            for i in 0..7
              fits_key=caldb_key[i].join("")
              fits_value=caldb_value[i].join("")
              fits_comment=caldb_comment[i]
              eventHDU.addHeader(fits_key, fits_value, fits_comment)
            end
            fits.saveAs(newFitsAddress)
          end
        end
      elsif resultParse[1] == "OK" then
        puts "#{fitsName} OK!"
        newFitsAddress="#{fitsFolderLv1}/#{fitsName}"
        fits=FitsFile.new(fitsAddress)
        eventHDU=fits.hdu("EVENTS")
        eventHDU.addHeader("PIPELINE", "level-1", "present pipeline process level")
        eventHDU.addHeader("PL1_DATE", "#{date}", "pipeline level-1 processing date")
        eventHDU.addHeader("PL1_VER", "#{pipeline_version}", "pipeline level-1 version")
        for i in 0..7
          fits_key=caldb_key[i].join("")
          fits_value=caldb_value[i].join("")
          fits_comment=caldb_comment[i]
          eventHDU.addHeader(fits_key, fits_value, fits_comment)
        end
        fits.saveAs(newFitsAddress)
      end
    end
  end
end

