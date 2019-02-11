#!/usr/bin/env ruby
require "RubyROOT"
require "RubyFits"
require "yaml"
include Root
include Fits
include Math

def fillFitsColumn(hist, histSize, hdu)
  hdu.resize(histSize)
  for i in 0..histSize-1
    hdu["CHANNEL"][i]=i
    hdu["COUNTS"][i]=hist.GetBinContent(i+1)
  end
end

configurationFile=ARGV[0]
type=ARGV[1]
inputFile=[ARGV[2], ARGV[3], ARGV[4]]
outputFile=ARGV[5]

if ARGV[5]==nil then
  puts "Usage: ruby makeSourcePI.rb <configuration file> <type> <source 1> <source 2> <source 3> <output file>"
  puts "Example: ruby makeSourcePi.rb trb161208a.yaml source (or bgd) 170000.fits 173000.fits 180000.fits source.pi"
  puts "If only a source file is to be loaded, input 'none' to <source 2> and <source 3>."
  exit 1
end

# Define PI Range: 0.04-41 MeV, Step: 0.02 MeV, Channel:2048
pi_low=0.04
pi_high=41.0
pi_num=2048
hist=Root::TH1F.create("hist", "hist", pi_num, pi_low, pi_high)

# Set extract time
configuration=YAML.load_file(configurationFile)
if type=="source" then
  start_time=configuration["time"]["event_start"].to_f
  stop_time=configuration["time"]["event_stop"].to_f
  duration=stop_time-start_time
elsif type=="bgd" then
  start_time1=configuration["time"]["bgd1_start"].to_f
  stop_time1=configuration["time"]["bgd1_stop"].to_f
  start_time2=configuration["time"]["bgd2_start"].to_f
  stop_time2=configuration["time"]["bgd2_stop"].to_f
  duration=(stop_time1-start_time1)+(stop_time2-start_time2)
elsif
  puts "Make sure type (source or bgd)"
  exit 1
end
detector=configuration["detector"]
date=configuration["date"]
eventName=["event"]
adcChannel=configuration["adcIndex"].to_i

# Open FITS file
inputFile.each do |fitsFile|
  if fitsFile!="none" then
    fits=Fits::FitsFile.new(fitsFile)
    eventHDU=fits["EVENTS"]
    eventNum=eventHDU.getNRows()-1
    adcIndex=eventHDU["boardIndexAndChannel"]
    unixTime=eventHDU["unixTime"]
    energyRaw=eventHDU["energy"]
    energyWidth_header="BINW_CH#{adcChannel}"
    energyWidth=eventHDU.header(energyWidth_header).to_f
    
    for i in 0..eventNum
      if type=="source" then
        if (adcIndex[i].to_i==adcChannel)&&(unixTime[i].to_f>=start_time)&&(unixTime[i].to_f<=stop_time) then
          energy=(energyRaw[i].to_f+(rand(-500..500).to_f/1000.0)*energyWidth)/1000.0
          hist.Fill(energy)
        end
      elsif type=="bgd" then
        if (adcIndex[i].to_i==adcChannel)&&
           (((unixTime[i].to_f>=start_time1)&&(unixTime[i].to_f<=stop_time1))||((unixTime[i].to_f>=start_time2)&&(unixTime[i].to_f<=stop_time2)))
          energy=(energyRaw[i].to_f+(rand(-500..500).to_f/1000.0)*energyWidth)/1000.0
          hist.Fill(energy)
        end
      end
    end
  end
end
# Create FITS file
template_events=<<EOS
XTENSION=BINTABLE
EXTNAME=SPECTRUM
TFORM#=J
TTYPE#=CHANNEL
TFORM#=J
TTYPE#=COUNTS
EOS
fitsFilePI=FitsFile.constructFromTemplateString(template_events)
spectrumHDU=fitsFilePI[1]
fillFitsColumn(hist, pi_num, spectrumHDU)
fitsFileOutput=FitsFile.new

spectrumHDU.addHeader("HDUCLASS", "OGIP"              , "format conforms to OGIP standard")
spectrumHDU.addHeader("HDUVERS1", "1.2.0"             , "Obsolete - included for backwards compatibility")
spectrumHDU.addHeader("HDUVERS" , "1.2.0"             , "Version of format (OGIP memo OGIP-92-007)")
spectrumHDU.addHeader("HDUCLAS2", "DERIVED"           , "WARNING This is NOT an OGIP-approved value")
spectrumHDU.addHeader("HDUCLAS3", "COUNT"             , "PHA data stored as Counts (not count/s)")
spectrumHDU.addHeader("TLMIN1"  , "0"                 , "Lowest legal channel number")
spectrumHDU.addHeader("TLMAX1"  , "#{(pi_num-1).to_s}", "Highest legal channel number")
spectrumHDU.addHeader("TELESCOP", "GROWTH"            , "mission name")
spectrumHDU.addHeader("INSTRUME", "#{detector}"       , "instrument/detector name")
spectrumHDU.addHeader("FILTER"  , "NONE"              , "filter in use")
spectrumHDU.addHeader("EXPOSURE", "#{duration.to_s}"  , "exposure (in seconds)")
spectrumHDU.addHeader("AREASCAL", "1.000000E+00"      , "area scaling factor")
spectrumHDU.addHeader("BACKFILE", "NONE"              , "associated background filename")
spectrumHDU.addHeader("BACKSCAL", "1.000000E+00"      , "background file scaling factor")
spectrumHDU.addHeader("CORRFILE", "NONE"              , "associated correction filename")
spectrumHDU.addHeader("CORRSCAL", "1.000000E+00"      , "correction file scaling factor")
spectrumHDU.addHeader("RESPFILE", "NONE"              , "associated redistrib matrix filename")
spectrumHDU.addHeader("ANCRFILE", "NONE"              , "associated ancillary response filename")
spectrumHDU.addHeader("PHAVERSN", "1992a"             , "obsolete")
spectrumHDU.addHeader("DETCHANS", "#{pi_num.to_s}"    , "total number possible channels")
spectrumHDU.addHeader("CHANTYPE", "PI"                , "channel type (PHA, PI etc)")
spectrumHDU.addHeader("POISSERR", "T"                 , "Poissonian errors are applicable")
spectrumHDU.addHeader("SYS_ERR" , "0"                 , "no systematic error specified")
spectrumHDU.addHeader("GROUPING", "0"                 , "no grouping of the data has been defined")
spectrumHDU.addHeader("EVENTDAT", "#{date}"           , "event date (JST)")
spectrumHDU.addHeader("EVENTNAM", "#{eventName}"      , "event name")

fitsFileOutput.append spectrumHDU
fitsFileOutput.saveAs(outputFile)
