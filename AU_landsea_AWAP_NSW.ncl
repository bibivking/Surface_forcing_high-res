;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

begin

; ___________________________ make landsea ___________________________
file_name = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_OpenLandMap.nc"

f = addfile (file_name,"r")

filo = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_OpenLandMap_NSW_mask.nc"

system("/bin/rm -f " + filo)    ; remove if exists
fout  = addfile (filo, "c")     ; open output file

; explicitly declare file definition mode. Improve efficiency.
setfileoption(fout,"DefineMode",True)

; create global attributes of the file
fAtt               = True            ; assign file attributes
fAtt@title         = "New South Wales landmask for OpenLandMap to run with AWAP data"
fAtt@source_file   = file_name
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

nlat   = 681 ;
nlon   = 841

dimNames = (/ "latitude", "longitude" /)
dimSizes = (/ nlat , nlon  /)
dimUnlim = (/ False, False /)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

; predefine the the dimensionality of the variables to be written out
print("Predefine")

filevardef(fout, "landsea",typeof(f->landsea),getvardims(f->landsea))
filevardef(fout, "latitude",typeof(f->latitude),getvardims(f->latitude))
filevardef(fout, "longitude",typeof(f->longitude),getvardims(f->longitude))

print("Copy attributes")
filevarattdef(fout,"landsea",f->landsea)
filevarattdef(fout,"latitude",f->latitude)
filevarattdef(fout,"longitude",f->longitude)
setfileoption(fout,"DefineMode",False)
print("Exit DefineMode")

landsea = f->landsea
fout->landsea = landsea
fout->landsea = 1.
fout->landsea({-40:-28},{140:154}) = f->landsea({-40:-28},{140:154})
fout->latitude  = f->latitude
fout->longitude = f->longitude

end
