;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

; make a single var nc file from a multi-var netcdf file

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

begin

; _________________ option __________________
soil_data_type = 1 ; 0: CSIRO, 1: OpenLandMap
var_name       = "iveg"

; ________________ file name ________________
if soil_data_type .eq. 0 then
    fname_in  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_CSIRO_AU_NAT.nc"
    fin  = addfile (fname_in, "r")     ; open output file
else if soil_data_type .eq. 1 then
    fname_in  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_OpenLandMap_new_iveg.nc"
    ;"/srv/ccrc/data25/z5218916/script/surface_data_for_AWAP/nc_files/MD_elev_orig_std_avg-sand_AWAP_AU_mask.nc"
    ;"/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_OpenLandMap.nc"
    fin  = addfile (fname_in, "r")     ; open output file
end if
end if

fname_out = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/"+var_name+".nc"
fout      = addfile (fname_out, "c")     ; open output file
; _________________ set range of lat and lon ______________________
lat_s = -44.
lat_e = -10.
lon_s = 112.
lon_e = 154.

nlat   = 681
nlon   = 841
ntime  = 12
nsoil  = 6
npatch = 1
nrad   = 3
nsdepth = 6

; explicitly declare file definition mode. Improve efficiency.
setfileoption(fout,"DefineMode",True)

; create global attributes of the file
fAtt               = True            ; assign file attributes
fAtt@title         = var_name + " over Australia"
if soil_data_type .eq. 0 then
    fAtt@source_file = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_CSIRO_AU_NAT.nc"
else if soil_data_type .eq. 1 then
    fAtt@source_file = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_OpenLandMap.nc"
end if
end if
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

dimNames = (/"time", "latitude", "longitude", "soil", "patch", "rad", "soil_depth"/)
dimSizes = (/ 12   ,  nlat     ,  nlon      ,  nsoil,  npatch,  nrad,  nsdepth    /)
dimUnlim = (/ False,  False    ,  False     ,  False,  False ,  False, False       /)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

; __________________ 1D ___________________
filevardef( fout, "time", "integer", "time")
fout->time@units     = "months" ;
fout->time@long_name = "time"
fout->time           = (/1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12/)

filevardef( fout, "patch", "double", "patch")
fout->patch@units     = "patch fraction"
fout->patch@long_name = "patch"
fout->patch           = 1.

filevardef( fout, "rad", "integer", "rad")
fout->rad@long_name = "rad"
fout->rad           = (/1, 2, 3/)

filevardef( fout, "soil", "integer", "soil")
fout->soil@units = "soil layers" ;
fout->soil@long_name = "soil" ;
fout->soil           = (/1, 2, 3, 4, 5, 6/)

filevardef( fout, "soil_depth", "float", "soil_depth")
fout->soil_depth@long_name     = "depth of the middle point in the soil layer"
fout->soil_depth@units         = "m"
fout->soil_depth@_FillValue    =  -9999.
fout->soil_depth               = (/0.011, 0.051, 0.157, 0.4385, 1.1855, 3.164/)

filevardef( fout, "latitude", "float", "latitude")
fout->latitude@long_name     = "latitude"
fout->latitude@units         = "degrees_North"
fout->latitude@_FillValue    =  -9999.
fout->latitude               = fspan( lat_s, lat_e, nlat)

filevardef( fout, "longitude", "float", "longitude")
fout->longitude@long_name     = "longitude"
fout->longitude@units         = "degrees_East"
fout->longitude@_FillValue    =  -9999.
fout->longitude               = fspan( lon_s, lon_e, nlon)


do var_num = 0,dimsizes(var_name)-1
    filevardef(fout, var_name, typeof(fin->$var_name(var_num)$),getvardims(fin->$var_name(var_num)$))
    filevarattdef(fout,var_name(var_num),fin->$var_name(var_num)$)
    fout->$var_name(var_num)$ = fin->$var_name(var_num)$
end do

setfileoption(fout,"DefineMode",False)
print("Exit DefineMode")

end
