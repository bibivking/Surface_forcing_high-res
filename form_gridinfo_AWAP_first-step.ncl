;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

; Changed from 2-Dec-2019
; This script (form_gridinfo_AWAP_first-step.ncl) is changed from converge_grid_elev_std_opt_mask_sand+sand2.ncl
; and AU_gridinfo_AWAP.ncl

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

begin

; read in metadata
fname_grid = "/srv/ccrc/data45/z3509830/CABLE_runs/CABLE_site_runs/CABLE_AUX-dev/offline/CABLE_UNSW_GSWP3_gridinfo_0.5x0.5_site.nc"
                 ;lat from + to - lon from -180 to 180
fgrid      = addfile (fname_grid,"r")

fname_elev = "/srv/ccrc/data25/z5218916/cable/src/CABLE-AUX/offline/GSWP3_gwmodel_parameters.nc"
                 ;lat from - to + lon from 0 to 360
felev      = addfile (fname_elev,"r")

fname_std  = "/srv/ccrc/data45/z3509830/CABLE_runs/CABLE_site_runs/CABLE_AUX-dev/offline/gridinfo_CSIRO_1x1.nc"
                 ;lat from + to - lon from -180 to 180
fstd       = addfile (fname_std,"r")

; name of output file
fname_out  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_CSIRO_AU_NAT.nc"
system("/bin/rm -f " + fname_out)    ; remove if exists
fout  = addfile (fname_out, "c")     ; open output file


; _________________ set range of lat and lon ______________________
lat_s = -44.
lat_e = -10.
lon_s = 112.
lon_e = 154.

nlat   = 681 ;
nlon   = 841
ntime  = 12 ;
nsoil  = 6 ;
npatch = 1 ;
nrad   = 3 ;
nsdepth = 6

; explicitly declare file definition mode. Improve efficiency.
setfileoption(fout,"DefineMode",True)

; create global attributes of the file
fAtt               = True            ; assign file attributes
fAtt@title         = "CABLE surface forcing data over Australia"
fAtt@source_file   = "rhosoil, sand, clay, silt, and organic come from CSIRO National Soil Attribute Maps; LAI comes from lai_climatology_AWAP_grid.nc, created by Martin De Kauwe; CABLE_UNSW_GSWP3_gridinfo_0.5x0.5_site.nc; GSWP3_gwmodel_parameters.nc"
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( fout, fAtt )            ; copy file attributes

dimNames = (/"time", "latitude", "longitude", "soil", "patch", "rad", "soil_depth"/)
dimSizes = (/ 12   ,  nlat     ,  nlon      ,  nsoil,  npatch,  nrad,  nsdepth    /)
dimUnlim = (/ False,  False    ,  False     ,  False,  False ,  False, False       /)
filedimdef(fout,dimNames,dimSizes,dimUnlim)

; __________________ 1D ___________________
;filevardef( fout, "time", "integer", "time")
;filevardef( fout, "patch", "integer", "patch")
;filevardef( fout, "rad", "integer", "rad")
;filevardef( fout, "soil", "integer", "soil")

filevardef( fout, "soil_depth", "float", "soil_depth")
fout->soil_depth@long_name     = "depth of the middle point in the soil layer"
fout->soil_depth@units         = "m"
fout->soil_depth@_FillValue =  -9999.
fout->soil_depth               = (/0.011, 0.051, 0.157, 0.4385, 1.1855, 3.164/)

filevardef( fout, "latitude", "float", "latitude")
fout->latitude@long_name     = "latitude"
fout->latitude@units         = "degrees_North"
fout->latitude@_FillValue =  -9999.
fout->latitude               = fspan( lat_s, lat_e, nlat)

filevardef( fout, "longitude", "float", "longitude")
fout->longitude@long_name     = "longitude"
fout->longitude@units         = "degrees_East"
fout->longitude@_FillValue =  -9999.
fout->longitude               = fspan( lon_s, lon_e, nlon)

; _________________ 2D ___________________
filevardef( fout, "iveg", "integer", (/ "latitude", "longitude" /))
filevardef( fout, "landsea", "float", (/ "latitude", "longitude" /))
filevardef( fout, "soil_color", "float", (/ "latitude", "longitude" /))
filevardef( fout, "Albedo", "float", (/ "latitude", "longitude" /)) ; three dims in CSIRO std
filevardef( fout, "albedo2", "float", (/ "latitude", "longitude" /))
filevardef( fout, "Sy", "float", (/ "latitude", "longitude" /))
filevardef( fout, "dtb", "float", (/ "latitude", "longitude" /))
filevardef( fout, "drainage_density", "float", (/ "latitude", "longitude" /))
;filevardef( fout, "drainage_dist", "float", (/ "latitude", "longitude" /)) ; this var is not used by CABLE
filevardef( fout, "slope", "float", (/ "latitude", "longitude" /))
filevardef( fout, "slope_std", "float", (/ "latitude", "longitude" /))
filevardef( fout, "elevation", "float", (/ "latitude", "longitude" /))
filevardef( fout, "elevation_std", "float", (/ "latitude", "longitude" /))
filevardef( fout, "permeability", "float", (/ "latitude", "longitude" /))
;filevardef( fout, "permeability_std", "float", (/ "latitude", "longitude" /)) ; this var is not used by CABLE

nml_2D = (/\
    "iveg", "landsea", "soil_color", "Albedo", "albedo2",   \
    "Sy", "dtb", "drainage_density", "slope", "slope_std",  \
    "elevation", "elevation_std", "permeability"            \
    /)

do var_num = 0, dimsizes(nml_2D)-1
   print(nml_2D(var_num))
   if var_num .eq. 0 then
      var   = new((/nlat,nlon/),  "integer")
   else
      var   = new((/nlat,nlon/),  "float")
   end if
   var!0 = "latitude"
   var!1 = "longitude"
   var&latitude  = fspan( lat_s, lat_e, nlat)
   var&longitude = fspan( lon_s, lon_e, nlon)
   do x = lat_s+0.25,lat_e-0.25,0.5
      do y = lon_s+0.25,lon_e-0.25,0.5
        if var_num .eq. 0 then
           var({x-0.25:x+0.25},{y-0.25:y+0.25}) = floattointeger(fgrid->$nml_2D(var_num)$({x},{y}))
        else if var_num .le. 4 then
           var({x-0.25:x+0.25},{y-0.25:y+0.25}) = fgrid->$nml_2D(var_num)$({x},{y})
        else
           var({x-0.25:x+0.25},{y-0.25:y+0.25}) = felev->$nml_2D(var_num)$({x},{y})
        end if
        end if
      end do
   end do
   fout->$nml_2D(var_num)$ = var*1
   delete(var)
end do

; Edit the attributes of variables

fout->iveg@long_name     = "CSIRO classification of veg type"
fout->iveg@_FillValue = -1

fout->landsea@units         = "0:land, 1:sea";
fout->landsea@_FillValue = -9999.

fout->Albedo@long_name = "unknown sources" ;CSIRO std "ISLSCP2 snow-free bareground albedo";
fout->Albedo@_FillValue = -1.0

fout->albedo2@long_name = "unknown sources" ; CSIRO std "UM SNOW-FREE ALBEDO OF SOIL";
fout->albedo2@_FillValue = -9999.

; "soil_color" information

fout->Sy@long_name = "saturated water content of the aquifer (GWssat_vec)"
fout->Sy@units = "m3/m3";
fout->Sy@_FillValue = -9999.

fout->dtb@long_name = "depth to bedrock";
fout->dtb@units = "m";
fout->dtb@_FillValue = -9999.

fout->drainage_density@long_name = "drainage density"
fout->drainage_density@units = "1/m";
fout->drainage_density@_FillValue = -9999.
fout->drainage_density@filling_method = "missing values north of 60N filled by linearly regressing against soil texture, slope, dtb, top ind, source area";

fout->slope@long_name = "mean slope";
fout->slope@units = "m/m";
fout->slope@_FillValue = -9999.

fout->slope_std@long_name = "stddev of slope"
fout->slope_std@units = "m/m";
fout->slope_std@_FillValue = -9999.

fout->elevation@long_name = "elevation above sea level"
fout->elevation@units = "m";
fout->elevation@_FillValue = -9999.

fout->elevation_std@long_name = "stddev of elevation"
fout->elevation_std@units = "m";
fout->elevation_std@_FillValue = -9999.

fout->permeability@long_name     = "saturated hydraulic conductivity of the aquifer"
fout->permeability@units         = "mm/s"; unconcord to "m2" in Mark's elve file
fout->permeability@_FillValue = -9999.


; ___________________ 3D ______________________
filevardef( fout, "patchfrac", "float", (/ "patch", "latitude", "longitude" /))
fout->patchfrac@long_name     = "Patch fraction; 1.0 for 1x1 grid"
fout->patchfrac@_FillValue    =  -9999.
fout->patchfrac               = 1.

filevardef( fout, "SnowDepth", "float", (/"time", "latitude", "longitude" /))
fout->SnowDepth@long_name     = "Actual depth of snow"
fout->SnowDepth@units         = "m";
fout->SnowDepth@_FillValue    = -1.0
fout->SnowDepth               = 0. ;read from CSIRO std, Mark's grid file is 0


; ___________________ 4D ______________________
filevardef( fout, "SoilMoist", "float", (/"time", "soil", "latitude", "longitude" /))
; the value in Mark's gridinfo is higher than CSIRO std and the variance is less than CSIRO std
; May need to run a 120 years simulation to get equibrilum soil moisture
filevardef( fout, "SoilTemp", "float", (/"time", "soil", "latitude", "longitude" /))
; Both gridinfo and CSIRO have value


nml_4D = (/"SoilMoist","SoilTemp"/)

do var_num = 0,1
   print(nml_4D(var_num))
   var     = new((/ntime,nsoil,nlat,nlon/),  "float") ;(time, soil, lat, lon)
   var!0   = "time"
   var!1   = "soil"
   var!2   = "latitude"
   var!3   = "longitude"
   var&time= ispan(1,ntime,1)
   var&soil= ispan(1,nsoil,1)
   var&latitude  = fspan( lat_s, lat_e, nlat)
   var&longitude = fspan( lon_s, lon_e, nlon)
   do x = -43.75,-10.25,0.5
      do y = 112.25,153.75,0.5
         do time = 0,11
            do soil = 0,5
               var(time,soil,{x-0.25:x+0.25},{y-0.25:y+0.25}) = fgrid->$nml_4D(var_num)$(time,soil,{x},{y})
            end do
         end do
      end do
   end do
   fout->$nml_4D(var_num)$ = var*1.0
   delete(var)
end do

fout->SoilMoist@long_name     = "Soil moisture profile from previous GSWP runs";
fout->SoilMoist@units         = "m3/m3";
fout->SoilMoist@_FillValue = -9999.

fout->SoilTemp@long_name     = "Soil temperature profile from previous GSWP runs";
fout->SoilTemp@units         = "K";
fout->SoilTemp@_FillValue    = 9.96921e+36
fout->SoilTemp               = where(ismissing(fout->SoilTemp), -9999., fout->SoilTemp)
fout->SoilTemp@_FillValue    = -9999.

setfileoption(fout,"DefineMode",False)
print("Exit DefineMode")


end
