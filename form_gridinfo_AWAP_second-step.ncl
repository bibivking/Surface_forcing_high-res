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
filevardef( finout, "LAI", "float", (/"time", "latitude", "longitude" /))

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
finout->LAI@long_name     = "Leaf area index"
finout->LAI@_FillValue    = -9999. ; set -9999. because no missing value point in gridinfo
finout->LAI               = LAI*1.0
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

;change unit
    rhosoil(level,:,:) = frho->Bulk_density*1.
    sand(level,:,:)    = fsand->Sand*1.
    clay(level,:,:)    = fclay->Clay*1.
    silt(level,:,:)    = fsilt->Silt*1.
    organic(level,:,:) = forg->Organic_C*1.
end do

finout->rhosoil_vec(0,:,:) = rhosoil(0,:,:)
finout->sand_vec(0,:,:)    = sand(0,:,:)
finout->clay_vec(0,:,:)    = clay(0,:,:)
finout->silt_vec(0,:,:)    = silt(0,:,:)
finout->organic_vec(0,:,:) = organic(0,:,:)

finout->rhosoil_vec(1,:,:) = (rhosoil(0,:,:)*0.028 + rhosoil(1,:,:)*0.03)/0.058
finout->sand_vec(1,:,:)    = (sand(0,:,:)*0.028 + sand(1,:,:)*0.03)/0.058
finout->clay_vec(1,:,:)    = (clay(0,:,:)*0.028 + clay(1,:,:)*0.03)/0.058
finout->silt_vec(1,:,:)    = (silt(0,:,:)*0.028 + silt(1,:,:)*0.03)/0.058
finout->organic_vec(1,:,:) = (organic(0,:,:)*0.028 + organic(1,:,:)*0.03)/0.058

finout->rhosoil_vec(2,:,:) = (rhosoil(1,:,:)*0.07 + rhosoil(2,:,:)*0.084)/0.154
finout->sand_vec(2,:,:)    = (sand(1,:,:)*0.07 + sand(2,:,:)*0.084)/0.154
finout->clay_vec(2,:,:)    = (clay(1,:,:)*0.07 + clay(2,:,:)*0.084)/0.154
finout->silt_vec(2,:,:)    = (silt(1,:,:)*0.07 + silt(2,:,:)*0.084)/0.154
finout->organic_vec(2,:,:) = (organic(1,:,:)*0.07 + organic(2,:,:)*0.084)/0.154

finout->rhosoil_vec(3,:,:) = (rhosoil(2,:,:)*0.066 + rhosoil(3,:,:)*0.3 + rhosoil(4,:,:)*0.043)/0.409
finout->sand_vec(3,:,:)    = (sand(2,:,:)*0.066 + sand(3,:,:)*0.3 + sand(4,:,:)*0.043)/0.409
finout->clay_vec(3,:,:)    = (clay(2,:,:)*0.066 + clay(3,:,:)*0.3 + clay(4,:,:)*0.043)/0.409
finout->silt_vec(3,:,:)    = (silt(2,:,:)*0.066 + silt(3,:,:)*0.3 + silt(4,:,:)*0.043)/0.409
finout->organic_vec(3,:,:) = (organic(2,:,:)*0.066 + organic(3,:,:)*0.3 + organic(4,:,:)*0.043)/0.409

finout->rhosoil_vec(4,:,:) = (rhosoil(4,:,:)*0.357 + rhosoil(4,:,:)*0.728)/1.085
finout->sand_vec(4,:,:)    = (sand(4,:,:)*0.357 + sand(4,:,:)*0.728)/1.085
finout->clay_vec(4,:,:)    = (clay(4,:,:)*0.357 + clay(4,:,:)*0.728)/1.085
finout->silt_vec(4,:,:)    = (silt(4,:,:)*0.357 + silt(4,:,:)*0.728)/1.085
finout->organic_vec(4,:,:) = (organic(4,:,:)*0.357 + organic(4,:,:)*0.728)/1.085

finout->rhosoil_vec(5,:,:) = rhosoil(5,:,:)
finout->sand_vec(5,:,:)    = sand(5,:,:)
finout->clay_vec(5,:,:)    = clay(5,:,:)
finout->silt_vec(5,:,:)    = silt(5,:,:)
finout->organic_vec(5,:,:) = organic(5,:,:)


filevardef( finout, "rhosoil_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( finout, "sand_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( finout, "clay_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( finout, "silt_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( finout, "org_vec", "float", (/ "soil_depth", "latitude", "longitude" /))

filevardef( finout, "bch_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( finout, "sucs_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( finout, "ssat_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( finout, "sfc_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( finout, "css_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( finout, "cnsd_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( finout, "hyds_vec", "float", (/ "soil_depth", "latitude", "longitude" /))
filevardef( finout, "watr", "float",     (/ "soil_depth", "latitude", "longitude" /))









; ----------------- 2D --------------------
filevardef( finout, "rhosoil", "float", (/ "latitude", "longitude" /))
filevardef( finout, "sand", "float", (/ "latitude", "longitude" /))
filevardef( finout, "silt", "float", (/ "latitude", "longitude" /))
filevardef( finout, "clay", "float", (/ "latitude", "longitude" /))
filevardef( finout, "organic", "float", (/ "latitude", "longitude" /))

filevardef( finout, "hyds", "float", (/ "latitude", "longitude" /))
filevardef( finout, "bch", "float", (/ "latitude", "longitude" /))
filevardef( finout, "sfc", "float", (/ "latitude", "longitude" /))
filevardef( finout, "ssat", "float", (/ "latitude", "longitude" /))
filevardef( finout, "sucs", "float", (/ "latitude", "longitude" /))
filevardef( finout, "swilt", "float", (/ "latitude", "longitude" /))
filevardef( finout, "css", "float", (/ "latitude", "longitude" /))
filevardef( finout, "cnsd", "float", (/ "latitude", "longitude" /))

filevardef( finout, "isoil", integer, (/ "latitude", "longitude" /)) ; Need to be calculated

finout->isoil@long_name     = "Zobler soil type";
finout->isoil@missing_value = -1

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
   finout->$nml_2D(var_num)$ = var*1
   delete(var)
end do

finout->iveg@long_name     = "CSIRO classification of veg type"
finout->iveg@_FillValue = -1

finout->landsea@units         = "0:land, 1:sea";
finout->landsea@_FillValue = -9999.

finout->landsea@_FillValue = -9999.

finout->Albedo@long_name = "unknown sources" ;CSIRO std "ISLSCP2 snow-free bareground albedo";
finout->Albedo@_FillValue = -1.0

finout->Albedo@long_name = "unknown sources" ; CSIRO std "UM SNOW-FREE ALBEDO OF SOIL";
finout->Albedo@_FillValue = -9999.

finout->Sy@long_name = "saturated water content of the aquifer (GWssat_vec)"
finout->Sy@units = "m3/m3";
finout->Sy@_FillValue = -9999.

finout->dtb@long_name = "depth to bedrock";
finout->dtb@units = "m";
finout->dtb@_FillValue = -9999.

finout->drainage_density@long_name = "drainage density"
finout->drainage_density@units = "1/m";
finout->drainage_density@_FillValue = -9999.
finout->drainage_density@filling_method = "missing values north of 60N filled by linearly regressing against soil texture, slope, dtb, top ind, source area";

finout->slope@long_name = "mean slope";
finout->slope@units = "m/m";
finout->slope@_FillValue = -9999.

finout->slope_std@long_name = "stddev of slope"
finout->slope_std@units = "m/m";
finout->slope_std@_FillValue = -9999.

finout->elevation@long_name = "elevation above sea level"
finout->elevation@units = "m";
finout->elevation@_FillValue = -9999.

finout->elevation_std@long_name = "stddev of elevation"
finout->elevation_std@units = "m";
finout->elevation_std@_FillValue = -9999.

finout->permeability@long_name     = "saturated hydraulic conductivity of the aquifer"
finout->permeability@units         = "mm/s"; unconcord to "m2" in Mark's elve file
finout->permeability@_FillValue = -9999.


; ___________________ 3D ______________________
filevardef( finout, "patchfrac", ""float"", (/ "patch", "latitude", "longitude" /))
finout->patchfrac@long_name     = "Patch fraction; 1.0 for 1x1 grid"
finout->patchfrac@_FillValue =  -9999.
finout->patchfrac               = 1.

filevardef( finout, "SnowDepth", ""float"", (/"time", "latitude", "longitude" /))
finout->SnowDepth@long_name     = "Actual depth of snow"
finout->SnowDepth@units         = "m";
finout->SnowDepth@_FillValue = -1.0
finout->SnowDepth               = 0. ;read from CSIRO std, Mark's grid file is 0


; ___________________ 4D ______________________
filevardef( finout, "SoilMoist", ""float"", (/"time", "soil", "latitude", "longitude" /))
; the value in Mark's gridinfo is higher than CSIRO std and the variance is less than CSIRO std
; May need to run a 120 years simulation to get equibrilum soil moisture
filevardef( finout, "SoilTemp", ""float"", (/"time", "soil", "latitude", "longitude" /))
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
   finout->$nml_4D(var_num)$ = var*1.0
   delete(var)
end do

finout->SoilMoist@long_name     = "Soil moisture profile from previous GSWP runs";
finout->SoilMoist@units         = "m3/m3";
finout->SoilMoist@_FillValue = -9999.

finout->SoilTemp@long_name     = "Soil temperature profile from previous GSWP runs";
finout->SoilTemp@units         = "K";
finout->SoilTemp@_FillValue    = 9.96921e+36
finout->SoilTemp               = where(ismissing(finout->SoilTemp), -9999., finout->SoilTemp)
finout->SoilTemp@_FillValue    = -9999.

setfileoption(finout,"DefineMode",False)
print("Exit DefineMode")


end
