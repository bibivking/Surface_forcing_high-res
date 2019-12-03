;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

; Changed from 2-Dec-2019
; This script (converge_grid_elev_for_AWAP.ncl) is changed from converge_grid_elev_std_opt_mask_sand+sand2.ncl
; and AU_gridinfo_AWAP.ncl

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

begin

fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_CSIRO_AU_NAT.nc"
finout  = addfile (fname_inout, "w")     ; open output file

fname_grid = "/srv/ccrc/data45/z3509830/CABLE_runs/CABLE_site_runs/CABLE_AUX-dev/offline/CABLE_UNSW_GSWP3_gridinfo_0.5x0.5_site.nc"
                 ;lat from + to - lon from -180 to 180
fgrid      = addfile (fname_grid,"r")

fname_LAI  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/lai_climatology_AWAP_grid.nc"
fLAI  = addfile(fname_LAI, "r")

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

; ----------------- 3D --------------------


; =======  LAI  ========
; use Mark's gridinfo file to fill default value in Martin's LAI file
filevardef( fout, "LAI", "float", (/"time", "latitude", "longitude" /))

;LAI   = new((/ntime, nlat, nlon/),  "float")
;LAI!0 = "latitude"
;LAI!1 = "longitude"
;LAI&latitude  = fspan( lat_s, lat_e, nlat)
;LAI&longitude = fspan( lon_s, lon_e, nlon)
LAI = fLAI->LAI
lai = new((/ntime, nlat, nlon/),  "float")

do x = lat_s+0.25,lat_e-0.25,0.5
  do y = lon_s+0.25,lon_e-0.25,0.5
    do time = 0, 11
       lai(time,{x-0.25:x+0.25},{y-0.25:y+0.25}) = fgrid->LAI(time,{x},{y}))
    end do
  end do
end do

LAI = where(ismissing(LAI),lai,LAI)
fout->LAI@long_name     = "Leaf area index"
fout->LAI@_FillValue    = -9999. ; set -9999. because no missing value point in gridinfo
fout->LAI               = LAI*1.0
delete(LAI)
delete(lai)


rhosoil = new((/ntime, nlat, nlon/),  "float")
sand    = new((/ntime, nlat, nlon/),  "float")
clay    = new((/ntime, nlat, nlon/),  "float")
silt    = new((/ntime, nlat, nlon/),  "float")
organic = new((/ntime, nlat, nlon/),  "float")
level_class = (/"000_005","005_015","015_030","030_060","060_100","100_200"/)

do level = 0,5
    frho  = addfile("Bulk_density_"+level_class(level)+"_AU_NAT_C.nc", "r")
    fsand = addfile("Sand_"+level_class(level)+"_AU_NAT_C.nc", "r")
    fclay = addfile("Clay_"+level_class(level)+"_AU_NAT_C.nc", "r")
    fsilt = addfile("Silt_"+level_class(level)+"_AU_NAT_C.nc", "r")
    forg  = addfile("Organic_C_"+level_class(level)+"_AU_NAT_C.nc", "r")

    rhosoil(level,:,:) = frho->Bulk_density
    sand(level,:,:)    = fsand->Sand
    clay(level,:,:)    = fclay->Clay
    silt(level,:,:)    = fsilt->Silt
    organic(level,:,:) = forg->Organic_C

    (/0.011, 0.051, 0.157, 0.4385, 1.1855, 3.164/)





filevardef( fout, "rhosoil_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( fout, "sand_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( fout, "clay_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( fout, "silt_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( fout, "org_vec", "float", (/ "soil_depth", "latitude", "longitude" /))

filevardef( fout, "bch_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( fout, "sucs_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( fout, "ssat_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( fout, "sfc_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( fout, "css_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( fout, "cnsd_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( fout, "hyds_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( fout, "watr", "float",     (/ "soil_depth", "latitude", "longitude" /))









; ----------------- 2D --------------------
filevardef( fout, "rhosoil", "float", (/ "latitude", "longitude" /))
filevardef( fout, "sand", "float", (/ "latitude", "longitude" /))
filevardef( fout, "silt", "float", (/ "latitude", "longitude" /))
filevardef( fout, "clay", "float", (/ "latitude", "longitude" /))
filevardef( fout, "organic", "float", (/ "latitude", "longitude" /))

filevardef( fout, "hyds", "float", (/ "latitude", "longitude" /))
filevardef( fout, "bch", "float", (/ "latitude", "longitude" /))
filevardef( fout, "sfc", "float", (/ "latitude", "longitude" /))
filevardef( fout, "ssat", "float", (/ "latitude", "longitude" /))
filevardef( fout, "sucs", "float", (/ "latitude", "longitude" /))
filevardef( fout, "swilt", "float", (/ "latitude", "longitude" /))
filevardef( fout, "css", "float", (/ "latitude", "longitude" /))
filevardef( fout, "cnsd", "float", (/ "latitude", "longitude" /))

filevardef( fout, "isoil", integer, (/ "latitude", "longitude" /)) ; Need to be calculated

fout->isoil@long_name     = "Zobler soil type";
fout->isoil@missing_value = -1

; ----------------- 3D --------------------




------------------------------------------------------


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
      var   = new((/nlat,nlon/),  ""float"")
   end if
   var!0 = "latitude"
   var!1 = "longitude"
   var&latitude  = fspan( lat_s, lat_e, nlat)
   var&longitude = fspan( lon_s, lon_e, nlon)
   do x = lat_s+0.25,lat_e-0.25,0.5
      do y = lon_s+0.25,lon_e-0.25,0.5
        if var_num .eq. 0 then
           var({x-0.25:x+0.25},{y-0.25:y+0.25}) = "float"tointeger(fgrid->$nml_2D(var_num)$({x},{y}))
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

fout->iveg@long_name     = "CSIRO classification of veg type"
fout->iveg@_FillValue = -1

fout->landsea@units         = "0:land, 1:sea";
fout->landsea@_FillValue = -9999.

fout->landsea@_FillValue = -9999.

fout->Albedo@long_name = "unknown sources" ;CSIRO std "ISLSCP2 snow-free bareground albedo";
fout->Albedo@_FillValue = -1.0

fout->Albedo@long_name = "unknown sources" ; CSIRO std "UM SNOW-FREE ALBEDO OF SOIL";
fout->Albedo@_FillValue = -9999.

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
filevardef( fout, "patchfrac", ""float"", (/ "patch", "latitude", "longitude" /))
fout->patchfrac@long_name     = "Patch fraction; 1.0 for 1x1 grid"
fout->patchfrac@_FillValue =  -9999.
fout->patchfrac               = 1.

filevardef( fout, "SnowDepth", ""float"", (/"time", "latitude", "longitude" /))
fout->SnowDepth@long_name     = "Actual depth of snow"
fout->SnowDepth@units         = "m";
fout->SnowDepth@_FillValue = -1.0
fout->SnowDepth               = 0. ;read from CSIRO std, Mark's grid file is 0


; ___________________ 4D ______________________
filevardef( fout, "SoilMoist", ""float"", (/"time", "soil", "latitude", "longitude" /))
; the value in Mark's gridinfo is higher than CSIRO std and the variance is less than CSIRO std
; May need to run a 120 years simulation to get equibrilum soil moisture
filevardef( fout, "SoilTemp", ""float"", (/"time", "soil", "latitude", "longitude" /))
; Both gridinfo and CSIRO have value


nml_4D = (/"SoilMoist","SoilTemp"/)

do var_num = 0,1
   print(nml_4D(var_num))
   var     = new((/ntime,nsoil,nlat,nlon/),  ""float"") ;(time, soil, lat, lon)
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
         ;do time = 0,11
            ;do soil = 0,5
               var(:,:,{x-0.25:x+0.25},{y-0.25:y+0.25}) = fname_grid->$nml_4D(var_num)$(:,:,{x},{y})
            ;end do
         ;end do
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
