#!/usr/bin/env ruby
require "RubyROOT"
require "RubyFits"
include Root
include RootApp
include Fits
include Math

# usage: ruby response_generator.rb [input root file] [output fits file] [detector name] [event tree name] [area density] [simulation energy binning file name]
#                                   [resolution sigma factor 1] [resolution sigma factor 2] [resolution sigma factor 3]
# sigma (MeV) = [factor1] * (E MeV)**[factor2] + [factor3]


def addFitsHeader(hdu, det)
  ## define header keyvalues
  telescop = "GROWTH"
  instrume = "#{det}"
  chantype = "PI"
  detchans = 2048
  hduclass = "OGIP"
  hduclas1 = "RESPONSE"
  
  ## write header keyvalues
  hdu.addHeader("TELESCOP", telescop, "mission name")
  hdu.addHeader("INSTRUME", instrume, "instrument/detector name")
  hdu.addHeader("CHANTYPE", chantype, "channel type (PHA, PI etc)")
  hdu.addHeader("DETCHANS", detchans, "total number possible channels")
  hdu.addHeader("HDUCLASS", hduclass, "")
  hdu.addHeader("HDUCLAS1", hduclas1, "")
end

if ARGV[7]==nil then
  puts "usage: ruby response_generator.rb [input root file] [output fits file] [detector name] [event tree name] [area density] [simulation energy binning file name]"
  puts "                                  [resolution sigma factor 1] [resolution sigma factor 2] [resolution sigma factor 3]"
  puts "sigma (MeV) = [factor1] * (E MeV)**[factor2] + [factor3]"
  exit
end

## information
puts "  #####################################"
puts "  #     GROWTH RESPONSE GENERATOR     #"
puts "  #        2018 May 24 (Ver1.0)       #"
puts "  #        Y. Furuta & Y. Wada        #"
puts "  #####################################"

## read arguments
input_file   = ARGV[0]
output_fits  = ARGV[1]
det_name     = ARGV[2]
tree_name    = ARGV[3]
area_dens    = ARGV[4]
binning_file = ARGV[5]
sigma_fact1  = ARGV[6]
sigma_fact2  = ARGV[7]
sigma_fact3  = ARGV[8]

## define PI
pi_Emin  =    40.0 # keV
pi_Emax  = 41000.0 # keV
pi_Estep =    20.0 # keV
pi_chnum =    2048

## simulation energy range
sim_Emin   =    40.0 # keV
sim_Emax   = 41000.0 # keV
sim_Erange = sim_Emax - sim_Emin

## read simulation energy binning file
sim_binfile=File.open(binning_file, "r")
sim_binlist = sim_binfile.readlines()
sim_binnum  = sim_binlist.length-1
sim_bins=Root::DoubleArray.new(sim_binnum+1)
sim_binlist.each_with_index do |line, i|
  sim_bins[i] = line.to_f
end

if sim_bins[0] < sim_Emin then
  puts "*** ERROR *** Lower edge of energy bin 1 is lower than simulation minimum energy."
  exit 1
end

if sim_bins[sim_binnum] > sim_Emax then
  puts "*** ERROR *** Upper edge of energy bin #{sim_binnum.to_s} is higher than simulation maximum energy."
  exit 1
end


## make input vs detected energy histogram
pi_bins=Root::DoubleArray.new(pi_chnum+1)
for i in 0..pi_chnum
  pi_bins[i]=pi_Emin+pi_Estep*i.to_f
end
h = Root::TH2D.create("input_vs_detected", "input_vs_detected", sim_binnum, sim_bins, pi_chnum, pi_bins)

## open input root file
random = Root::TRandom3.new()
random.SetSeed()
File.open(input_file, "r") do |input_data|
  input_data.each_line do |input_root|
    input_root.chomp!
    puts input_root
    f = Root::TFile.open(input_root)
    tree = f.Get(tree_name)
    evnum = tree.GetEntries()
    tree.read.each do |data|
      e_detected=data.energyDeposit.to_f
      ## randomize detected energy
      sigma = (sigma_fact1.to_f*(e_detected**sigma_fact2.to_f)+sigma_fact3.to_f) # MeV
      e_random = random.Gaus(e_detected, sigma)
      h.Fill(data.initial.to_f*1000.0, e_random*1000.0)
    end
  end
end
## scale histogram according to the simulated photon number per unit area in each energy bin
matrix = Array.new(sim_binnum){Array.new(pi_chnum)}
for i in 0..sim_binnum-1
  areadens_per_bin = area_dens.to_f*(sim_bins[i+1]-sim_bins[i])/sim_Erange
  for j in 0..pi_chnum-1
    val = h.GetBinContent(i+1,j+1)
    matrix[i][j]=val/areadens_per_bin
  end
end

## fill element values to extension 1
n_grp = 1
f_chan = 1

template_matrix=<<EOS
XTENSION=BINTABLE
EXTNAME=MATRIX
TFORM#=1E
TTYPE#=ENERG_LO
TFORM#=1E
TTYPE#=ENERG_HI
TFORM#=1I
TTYPE#=N_GRP
TFORM#=1I
TTYPE#=F_CHAN
TFORM#=1I
TTYPE#=N_CHAN
TFORM#=#{pi_chnum.to_s}E
TTYPE#=MATRIX
EOS

template_ebounds=<<EOS
XTENSION=BINTABLE
EXTNAME=EBOUNDS
TFORM#=1I
TTYPE#=CHANNEL
TFORM#=1E
TTYPE#=E_MIN
TFORM#=1E
TTYPE#=E_MAX
EOS

fitsHduMatrix=FitsFile.constructFromTemplateString(template_matrix)
primaryHDU=fitsHduMatrix[0]
matrixHDU=fitsHduMatrix[1]
matrixHDU.resize(sim_binnum)
for i in 0..sim_binnum-1
  matrixHDU["ENERG_LO"][i] = sim_bins[i]
  matrixHDU["ENERG_HI"][i] = sim_bins[i+1]
  matrixHDU["N_GRP"][i]    = 1
  matrixHDU["F_CHAN"][i]   = 1
  matrixHDU["N_CHAN"][i]   = pi_chnum
  matrixHDU["MATRIX"][i]   = matrix[i]
end

fitsHduEbounds=FitsFile.constructFromTemplateString(template_ebounds)
eboundsHDU=fitsHduEbounds[1]
eboundsHDU.resize(pi_chnum)
for i in 0..pi_chnum-1
  eboundsHDU["CHANNEL"][i] = i
  eboundsHDU["E_MIN"][i]   = pi_Emin+pi_Estep*i.to_f
  eboundsHDU["E_MAX"][i]   = pi_Emin+pi_Estep*(i+1).to_f
end

addFitsHeader(primaryHDU, det_name)
addFitsHeader(matrixHDU, det_name)
addFitsHeader(eboundsHDU, det_name)

matrixHDU.addHeader("HDUCLAS2", "RSP_MATRIX")
matrixHDU.addHeader("HDUVERS" , "1.3.0")
matrixHDU.addHeader("TLMIN4"  , "0")

eboundsHDU.addHeader("HDUCLAS2", "EBOUNDS")
eboundsHDU.addHeader("HDUVERS" ,  "1.2.0")

## write HDUs to output fits file
fitsFileOutput=FitsFile.new
fitsFileOutput.append primaryHDU
fitsFileOutput.append matrixHDU
fitsFileOutput.append eboundsHDU
fitsFileOutput.saveAs(output_fits)
