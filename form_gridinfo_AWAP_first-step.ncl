;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************
; __________________________________ MMY _______________________________________
; Purpose: set up the netcdf file,
;          copy the default parameters,
;          update PFT, elevation and slope

; Change History:
; 1. 2-Dec-2019
;    This script (form_gridinfo_AWAP_first-step.ncl) is changed from
;    converge_grid_elev_std_opt_mask_sand+sand2.ncl
;    and AU_gridinfo_AWAP.ncl
; 2. 4-Nov-2020
;    Anna terrain(raster("/srv/ccrc/data45/z3509830/CABLE_runs/Inputs/Elev_data/elev_GTOPO30-1gd4r.nc"), opt="slope", unit="tangent", neighbors=4)
; 3. 6-May-2021
;    Fixing three odd pixels along costal in elevation
; ______________________________________________________________________________


;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 5000000000 ;
end setvalues
;_____________________________________

begin

; ================================== Options ===================================
  soil_data_type = 1 ; 0: CSIRO, 1: OpenLandMap
  iveg_type      = "DLCM" ; Dynamic Land Cover Map across Australia
                   ;"NVIS" ; NVIS iveg only for SE Australia
                   ;"STD"  ; CABLE standard input
  interp_method  = "bilinear"
                   ;"nearest"

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

; ============================== Output File Name ==============================
if soil_data_type .eq. 0 then
  if iveg_type .eq. "STD" then
    fname_out  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_CSIRO_AU_NAT_ELEV.nc"
    system("/bin/rm -f " + fname_out)    ; remove if exists
    fout  = addfile (fname_out, "c")     ; open output file
  else
    fname_out  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_CSIRO_AU_NAT_ELEV_"+iveg_type+".nc"
    system("/bin/rm -f " + fname_out)    ; remove if exists
    fout  = addfile (fname_out, "c")     ; open output file
  end if
else if soil_data_type .eq. 1 then
  if iveg_type .eq. "STD" then
    fname_out  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_OpenLandMap_ELEV.nc"
    system("/bin/rm -f " + fname_out)    ; remove if exists
    fout  = addfile (fname_out, "c")     ; open output file
  else
    fname_out  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_OpenLandMap_ELEV_"+iveg_type+".nc"
    system("/bin/rm -f " + fname_out)    ; remove if exists
    fout  = addfile (fname_out, "c")     ; open output file
  end if
end if
end if

; ============================== Input File Name ===============================

; ---- Gridinfo and Elev file ----
fname_grid = "/srv/ccrc/data25/z5218916/cable/src/CABLE-AUX/offline/CABLE_UNSW_GSWP3_gridinfo_0.5x0.5_site.nc"
                 ;lat from + to - lon from -180 to 180
fgrid      = addfile (fname_grid,"r")

fname_elev = "/srv/ccrc/data25/z5218916/cable/src/CABLE-AUX/offline/GSWP3_gwmodel_parameters.nc"
                 ;lat from - to + lon from 0 to 360
felev      = addfile (fname_elev,"r")

fname_std  = "/srv/ccrc/data25/z5218916/cable/src/CABLE-AUX/offline/gridinfo_CSIRO_1x1.nc"
                 ;lat from + to - lon from -180 to 180
fstd       = addfile (fname_std,"r")

; ---- PFT file ----
if iveg_type .eq. "NVIS" then
    fname_iveg = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/SE_aus_veg_types_AWAP_grid.nc"
    fiveg      = addfile (fname_iveg,"r")
else if iveg_type .eq. "DLCM" then
    fname_iveg = "/srv/ccrc/data25/z5218916/data/Dynamic_land_cover_maps/Dynamic_land_cover_dataset_CABLE_AWAP_resolution.nc"
    fiveg      = addfile (fname_iveg,"r")
end if
end if

; ---- Elevation file ----
fname_elevation = "/srv/ccrc/data25/z5218916/data/elev_slope/elev_GTOPO30-1gd4r.nc"
felevation      = addfile (fname_elevation,"r")

; ---- Slope file ----
fname_slope = "/srv/ccrc/data25/z5218916/data/elev_slope/GTOPO30_slope_in_tangent_4neighbours.nc"
fslope      = addfile (fname_slope,"r")

; ============================== Set Lat and Lon ===============================
felevation_lat  = doubletofloat(felevation->lat({lat_s-0.05:lat_e+0.05}))
felevation_lon  = doubletofloat(felevation->lon({lon_s-0.05:lon_e+0.05}))

fslope_lat  = doubletofloat(fslope->latitude({lat_s-0.05:lat_e+0.05}))
fslope_lon  = doubletofloat(fslope->longitude({lon_s-0.05:lon_e+0.05}))

if interp_method  .eq. "bilinear" then
  fgrid_lat  = doubletofloat(fgrid->latitude({lat_s-0.25:lat_e+0.25}))
  fgrid_lon  = doubletofloat(fgrid->longitude({lon_s-0.25:lon_e+0.25}))

  felev_lat  = felev->latitude({lat_s-0.25:lat_e+0.25})
  felev_lon  = felev->longitude({lon_s-0.25:lon_e+0.25})

  print(fgrid_lat)
  print(fgrid_lon)
  print(felev_lat)
  print(felev_lon)
end if

; ================================ Edit NetCDF =================================
; explicitly declare file definition mode. Improve efficiency.
setfileoption(fout,"DefineMode",True)

; create global attributes of the file
fAtt               = True            ; assign file attributes
fAtt@title         = "CABLE surface forcing data over Australia"

source_file_description = "elevation is from elev_GTOPO30-1gd4r.nc; slope is computed by R function (Fleming and Hoffer, 1979; Ritter, 1987), "
source_file_description = source_file_description + "terrain(raster('/srv/ccrc/data45/z3509830/CABLE_runs/Inputs/Elev_data/elev_GTOPO30-1gd4r.nc'), opt='slope', unit='tangent', neighbors=4)"
source_file_description = source_file_description + "Elevation_std and slope_std are the standard deviation among the 5x5 1km pixels; "
source_file_description = source_file_description + "LAI comes from Copernicus LAI, monthly_climatology.nc; "

if soil_data_type .eq. 0 then
    source_file_description = source_file_description + "rhosoil, sand, clay, silt, and organic come from CSIRO National Soil Attribute Maps; "
else if soil_data_type .eq. 1 then
    source_file_description = source_file_description + "rhosoil, sand, clay, silt, and organic come from OpenLandMap Soil Maps; "
end if
end if

if iveg_type .eq. "NVIS" then
    source_file_description = source_file_description + "iveg comes from NVIS but only covers Southeastern Australia; CABLE_UNSW_GSWP3_gridinfo_0.5x0.5_site.nc; GSWP3_gwmodel_parameters.nc"
else if iveg_type .eq. "DLCM" then
    source_file_description = source_file_description + "iveg comes from Dynamic Land Cover Map; CABLE_UNSW_GSWP3_gridinfo_0.5x0.5_site.nc; GSWP3_gwmodel_parameters.nc"
else
    source_file_description = source_file_description + "CABLE_UNSW_GSWP3_gridinfo_0.5x0.5_site.nc; GSWP3_gwmodel_parameters.nc"
end if
end if

fAtt@source_file = source_file_description

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

; iveg
if iveg_type .eq. "STD" then
    var   = new((/nlat,nlon/),  "integer")
    var!0 = "latitude"
    var!1 = "longitude"
    var&latitude  = fspan( lat_s, lat_e, nlat)
    var&longitude = fspan( lon_s, lon_e, nlon)
    do x = lat_s+0.25,lat_e-0.25,0.5
       do y = lon_s+0.25,lon_e-0.25,0.5
         if var_num .eq. 0 then
            var({x-0.25:x+0.25},{y-0.25:y+0.25}) = floattointeger(fgrid->iveg({x},{y}))
         else if var_num .le. 4 then
            var({x-0.25:x+0.25},{y-0.25:y+0.25}) = fgrid->iveg({x},{y})
         else
            var({x-0.25:x+0.25},{y-0.25:y+0.25}) = felev->iveg({x},{y})
         end if
         end if
       end do
    end do
    fout->iveg = var*1
    delete(var)

else
    var   = new((/nlat,nlon/),  "integer")
    var!0 = "latitude"
    var!1 = "longitude"
    var&latitude  = fspan( lat_s, lat_e, nlat)
    var&longitude = fspan( lon_s, lon_e, nlon)

    var = floattointeger(fiveg->iveg({lat_s:lat_e},{lon_s:lon_e}))
    var = where( ismissing(var), -1, var)
    printVarSummary(var)
    fout->iveg = var(:,:)*1
    printVarSummary(fout->iveg)
    delete(var)
end if


nml_2D = (/\
    "landsea", "soil_color", "Albedo", "albedo2",   \
    "Sy", "dtb", "drainage_density", "permeability" \
    /)

do var_num = 0, dimsizes(nml_2D)-1

   print(nml_2D(var_num))
   var   = new((/nlat,nlon/),  "float")
   var!0 = "latitude"
   var!1 = "longitude"
   var&latitude  = fspan( lat_s, lat_e, nlat)
   var&longitude = fspan( lon_s, lon_e, nlon)

   if var_num .eq. 0 then
     do x = lat_s-0.25,lat_e+0.25,0.5
        do y = lon_s-0.25,lon_e+0.25,0.5
          if var_num .le. 3 then
             var({x-0.25:x+0.25},{y-0.25:y+0.25}) = fgrid->$nml_2D(var_num)$({x},{y})
          else
             var({x-0.25:x+0.25},{y-0.25:y+0.25}) = felev->$nml_2D(var_num)$({x},{y})
          end if
        end do
     end do
   else
     if interp_method  .eq. "nearest" then
       do x = lat_s+0.25,lat_e-0.25,0.5
          do y = lon_s+0.25,lon_e-0.25,0.5
            if var_num .le. 3 then
               var({x-0.25:x+0.25},{y-0.25:y+0.25}) = fgrid->$nml_2D(var_num)$({x},{y})
            else
               var({x-0.25:x+0.25},{y-0.25:y+0.25}) = felev->$nml_2D(var_num)$({x},{y})
            end if
          end do
       end do
     else if interp_method  .eq. "bilinear" then
       if var_num .le. 3 then
         var = linint2(fgrid_lon,fgrid_lat,fgrid->$nml_2D(var_num)$({lat_s-0.25:lat_e+0.25},{lon_s-0.25:lon_e+0.25}),True,var&longitude,var&latitude,0)
       else
         var = linint2(felev_lon,felev_lat,felev->$nml_2D(var_num)$({lat_s-0.25:lat_e+0.25},{lon_s-0.25:lon_e+0.25}),True,var&longitude,var&latitude,0)
       end if
     end if
     end if
   end if
   fout->$nml_2D(var_num)$ = var*1
   delete(var)
end do

; elevation and slope
nml_2D_ele_slp = (/ "elevation", "slope" /)

do var_num = 0, dimsizes(nml_2D_ele_slp)-1
    print(nml_2D_ele_slp(var_num))
    var   = new((/nlat,nlon/),  "float")
    var!0 = "latitude"
    var!1 = "longitude"
    var&latitude  = fspan( lat_s, lat_e, nlat)
    var&longitude = fspan( lon_s, lon_e, nlon)
    if var_num .eq. 0 then
      ; fix the odd stripe at lat: -23.4995 lon: 130.9227-154
      ele_tmp = felevation->elevation({lat_s-0.05:lat_e+0.05},{lon_s-0.05:lon_e+0.05})
      ; since elev&slope is in 1km, don't need to include many boundary pixels
      ele_tmp({-23.4995},{130.9227:154}) = (ele_tmp({-23.5095},{130.9227:154}) + ele_tmp({-23.4895},{130.9227:154}))/2
      var = linint2(felevation_lon,felevation_lat,ele_tmp,True,var&longitude,var&latitude,0)
    else if var_num .eq. 1 then
      ; fix the odd stripe at lat: -23.4995 lon: 130.9227-154
      slp_tmp = fslope->slope({lat_s-0.05:lat_e+0.05},{lon_s-0.05:lon_e+0.05})
      slp_tmp({-23.4895},{130.9227:154}) = (slp_tmp({-23.5195},{130.9227:154}) + slp_tmp({-23.4795},{130.9227:154}))/2
      slp_tmp({-23.4995},{130.9227:154}) = (slp_tmp({-23.5195},{130.9227:154}) + slp_tmp({-23.4795},{130.9227:154}))/2
      slp_tmp({-23.5095},{130.9227:154}) = (slp_tmp({-23.5195},{130.9227:154}) + slp_tmp({-23.4795},{130.9227:154}))/2
      var = linint2(fslope_lon,fslope_lat,slp_tmp,True,var&longitude,var&latitude,0)
    end if
    end if
    fout->$nml_2D_ele_slp(var_num)$ = var*1
    delete(var)
end do

; fix odd pixels in elevation @ 2021/5/6
fout->elevation = where(fout->elevation .gt. 5000, 0, fout->elevation)

; elevation_std and slope_std
nml_2D_std = (/ "elevation_std", "slope_std" /)
do var_num = 0, dimsizes(nml_2D_std)-1
    print(nml_2D_std(var_num))
    var   = new((/nlat,nlon/),  "float")
    var!0 = "latitude"
    var!1 = "longitude"
    var&latitude  = fspan( lat_s, lat_e, nlat)
    var&longitude = fspan( lon_s, lon_e, nlon)
    do x = lat_s,lat_e,0.05
       do y = lon_s,lon_e,0.05
         if var_num .eq. 0 then
            tmp = ele_tmp({x-0.025:x+0.025},{y-0.025:y+0.025})
            if all(ismissing(tmp)) then
              var({x},{y}) =  -9999.
            else
              var({x},{y}) = stddev(tmp)
            end if
            delete(tmp)
         else if var_num .eq. 1 then
            tmp = slp_tmp({x-0.025:x+0.025},{y-0.025:y+0.025})
            if all(ismissing(tmp)) then
              var({x},{y}) =  -9999.
            else
              var({x},{y}) = stddev(tmp)
            end if
            delete(tmp)
         end if
         end if
       end do
    end do
    fout->$nml_2D_std(var_num)$ = var*1
    delete(var)
end do


; Edit the attributes of variables

fout->iveg@long_name     = "CSIRO classification of veg type"
fout->iveg@_FillValue    = -1

fout->landsea@units      = "0:land, 1:sea";
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
fout->patchfrac@long_name     = "Patch fraction" ; 1.0 for 1x1 grid
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

   if interp_method  .eq. "nearest" then
     do x = -43.75,-10.25,0.5
        do y = 112.25,153.75,0.5
           do time = 0,11
              do soil = 0,5
                 var(time,soil,{x-0.25:x+0.25},{y-0.25:y+0.25}) = fgrid->$nml_4D(var_num)$(time,soil,{x},{y})
              end do
           end do
        end do
     end do
   else if interp_method  .eq. "bilinear" then
     var = linint2(fgrid_lon,fgrid_lat,fgrid->$nml_4D(var_num)$(:,:,{lat_s-0.25:lat_e+0.25},{lon_s-0.25:lon_e+0.25}),True,var&longitude,var&latitude,0)
   end if
   end if

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
