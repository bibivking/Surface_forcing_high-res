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

nlat   = 341
nlon   = 421
ntime  = 12
nsoil  = 6
npatch = 1
nrad   = 3
nsdepth = 6

; ============================== Output File Name ==============================
fname_in  = "./nc_output/gridinfo_AWAP_OpenLandMap_ELEV_DLCM_fix.nc"
fname_out = "./nc_output/gridinfo_AWAP_OpenLandMap_ELEV_DLCM_fix_10km.nc"

fin    = addfile (fname_in, "r")     ; open input file
lat_in = fin->latitude
lon_in = fin->longitude

system("/bin/rm -f " + fname_out)    ; remove if exists
fout   = addfile (fname_out, "c")     ; open output file

; ================================ Edit NetCDF =================================
; explicitly declare file definition mode. Improve efficiency.
setfileoption(fin,"DefineMode",True)

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
filevardef( fout, "time", typeof(fin->time),getvardims(fin->time))
filevarattdef(fout,"time",fin->time)
fout->time  = fin->time

filevardef( fout, "patch", typeof(fin->patch),getvardims(fin->patch))
filevarattdef(fout,"patch",fin->patch)
fout->patch = fin->patch

filevardef( fout, "rad", typeof(fin->rad),getvardims(fin->rad))
filevarattdef(fout,"rad",fin->rad)
fout->rad   = fin->rad

filevardef( fout, "soil", typeof(fin->soil),getvardims(fin->soil))
filevarattdef(fout,"soil",fin->soil)
fout->soil  = fin->soil

filevardef( fout, "soil_depth", typeof(fin->soil_depth),getvardims(fin->soil_depth))
filevarattdef(fout,"soil_depth",fin->soil_depth)
fout->soil_depth = fin->soil_depth

filevardef( fout, "latitude", typeof(fin->latitude),getvardims(fin->latitude))
filevarattdef(fout,"latitude",fin->latitude)
lat_out        = fspan( lat_s, lat_e, nlat)
fout->latitude = lat_out
print(fout->latitude)

filevardef( fout, "longitude", typeof(fin->longitude),getvardims(fin->longitude))
filevarattdef(fout,"longitude",fin->longitude)
lon_out         = fspan( lon_s, lon_e, nlon)
fout->longitude = lon_out
print(fout->longitude)

; _________________ 2D ___________________
filevardef( fout, "landsea", typeof(fin->landsea),getvardims(fin->landsea))
filevarattdef(fout,"landsea",fin->landsea) ; 0:land, 1:sea
landsea = area_hi2lores_Wrap( lon_in, lat_in, fin->landsea, False, 1, lon_out, lat_out, False)
landsea = where(landsea .eq. 0, landsea, 1)
fout->landsea = landsea*1

filevardef( fout, "soil_color", typeof(fin->soil_color),getvardims(fin->soil_color))
filevarattdef(fout,"soil_color",fin->soil_color)
soil_color = area_hi2lores_Wrap( lon_in, lat_in, fin->soil_color, False, 1, lon_out, lat_out, False)
fout->soil_color = where(landsea .eq. 0, soil_color, -9999)*1
delete(soil_color)

filevardef( fout, "Albedo", typeof(fin->Albedo),getvardims(fin->Albedo))
filevarattdef(fout,"Albedo",fin->Albedo)
Albedo = area_hi2lores_Wrap( lon_in, lat_in, fin->Albedo, False, 1, lon_out, lat_out, False)
fout->Albedo = where(landsea .eq. 0, Albedo, -9999)*1
delete(Albedo)

filevardef( fout, "albedo2", typeof(fin->albedo2),getvardims(fin->albedo2))
filevarattdef(fout,"albedo2",fin->albedo2)
albedo2 = area_hi2lores_Wrap( lon_in, lat_in, fin->albedo2, False, 1, lon_out, lat_out, False)
fout->albedo2 = where(landsea .eq. 0, albedo2, -9999)*1
delete(albedo2)

filevardef( fout, "Sy", typeof(fin->Sy),getvardims(fin->Sy))
filevarattdef(fout,"Sy",fin->Sy)
Sy = area_hi2lores_Wrap( lon_in, lat_in, fin->Sy, False, 1, lon_out, lat_out, False)
fout->Sy = where(landsea .eq. 0, Sy, -9999)*1
delete(Sy)

filevardef( fout, "dtb", typeof(fin->dtb),getvardims(fin->dtb))
filevarattdef(fout,"dtb",fin->dtb)
dtb = area_hi2lores_Wrap( lon_in, lat_in, fin->dtb, False, 1, lon_out, lat_out, False)
fout->dtb = where(landsea .eq. 0, dtb, -9999)*1
delete(dtb)

filevardef( fout, "drainage_density", typeof(fin->drainage_density),getvardims(fin->drainage_density))
filevarattdef(fout,"drainage_density",fin->drainage_density)
drainage_density = area_hi2lores_Wrap( lon_in, lat_in, fin->drainage_density, False, 1, lon_out, lat_out, False)
fout->drainage_density = where(landsea .eq. 0, drainage_density, -9999)*1
delete(drainage_density)

filevardef( fout, "slope", typeof(fin->slope),getvardims(fin->slope))
filevarattdef(fout,"slope",fin->slope)
slope = area_hi2lores_Wrap( lon_in, lat_in, fin->slope, False, 1, lon_out, lat_out, False)
fout->slope = where(landsea .eq. 0, slope, -9999)*1
delete(slope)

filevardef( fout, "slope_std", typeof(fin->slope_std),getvardims(fin->slope_std))
filevarattdef(fout,"slope_std",fin->slope_std)
slope_std = area_hi2lores_Wrap( lon_in, lat_in, fin->slope_std, False, 1, lon_out, lat_out, False)
fout->slope_std = where(landsea .eq. 0, slope_std, -9999)*1
delete(slope_std)

filevardef( fout, "elevation", typeof(fin->elevation),getvardims(fin->elevation))
filevarattdef(fout,"elevation",fin->elevation)
elevation = area_hi2lores_Wrap( lon_in, lat_in, fin->elevation, False, 1, lon_out, lat_out, False)
fout->elevation = where(landsea .eq. 0, elevation, -9999)*1
delete(elevation)

filevardef( fout, "elevation_std", typeof(fin->elevation_std),getvardims(fin->elevation_std))
filevarattdef(fout,"elevation_std",fin->elevation_std)
elevation_std = area_hi2lores_Wrap( lon_in, lat_in, fin->elevation_std, False, 1, lon_out, lat_out, False)
fout->elevation_std = where(landsea .eq. 0, elevation_std, -9999)*1
delete(elevation_std)

filevardef( fout, "permeability", typeof(fin->permeability),getvardims(fin->permeability))
filevarattdef(fout,"permeability",fin->permeability)
permeability = area_hi2lores_Wrap( lon_in, lat_in, fin->permeability, False, 1, lon_out, lat_out, False)
fout->permeability = where(landsea .eq. 0, permeability, -9999)*1
delete(permeability)

filevardef(fout, "rhosoil",  typeof(fin->rhosoil),getvardims(fin->rhosoil))
filevarattdef(fout,"rhosoil",fin->rhosoil)
rhosoil = area_hi2lores_Wrap( lon_in, lat_in, fin->rhosoil, False, 1, lon_out, lat_out, False)
fout->rhosoil = where(landsea .eq. 0, rhosoil, -9999)*1
delete(rhosoil)

filevardef(fout, "organic",  typeof(fin->organic),getvardims(fin->organic))
filevarattdef(fout,"organic",fin->organic)
organic = area_hi2lores_Wrap( lon_in, lat_in, fin->organic, False, 1, lon_out, lat_out, False)
fout->organic = where(landsea .eq. 0, organic, -9999)*1
delete(organic)

filevardef(fout, "sucs",  typeof(fin->sucs),getvardims(fin->sucs))
filevarattdef(fout,"sucs",fin->sucs)
sucs = area_hi2lores_Wrap( lon_in, lat_in, fin->sucs, False, 1, lon_out, lat_out, False)
fout->sucs = where(landsea .eq. 0, sucs, -9999)*1
delete(sucs)

filevardef(fout, "ssat",  typeof(fin->ssat),getvardims(fin->ssat))
filevarattdef(fout,"ssat",fin->ssat)
ssat = area_hi2lores_Wrap( lon_in, lat_in, fin->ssat, False, 1, lon_out, lat_out, False)
fout->ssat = where(landsea .eq. 0, ssat, -9999)*1
delete(ssat)

filevardef(fout, "sfc",  typeof(fin->sfc),getvardims(fin->sfc))
filevarattdef(fout,"sfc",fin->sfc)
sfc = area_hi2lores_Wrap( lon_in, lat_in, fin->sfc, False, 1, lon_out, lat_out, False)
fout->sfc = where(landsea .eq. 0, sfc, -9999)*1
delete(sfc)

filevardef(fout, "swilt",  typeof(fin->swilt),getvardims(fin->swilt))
filevarattdef(fout,"swilt",fin->swilt)
swilt = area_hi2lores_Wrap( lon_in, lat_in, fin->swilt, False, 1, lon_out, lat_out, False)
fout->swilt = where(landsea .eq. 0, swilt, -9999)*1
delete(swilt)

filevardef(fout, "css",  typeof(fin->css),getvardims(fin->css))
filevarattdef(fout,"css",fin->css)
css = area_hi2lores_Wrap( lon_in, lat_in, fin->css, False, 1, lon_out, lat_out, False)
fout->css = where(landsea .eq. 0, css, -9999)*1
delete(css)

filevardef(fout, "cnsd",  typeof(fin->cnsd),getvardims(fin->cnsd))
filevarattdef(fout,"cnsd",fin->cnsd)
cnsd = area_hi2lores_Wrap( lon_in, lat_in, fin->cnsd, False, 1, lon_out, lat_out, False)
fout->cnsd = where(landsea .eq. 0, cnsd, -9999)*1
delete(cnsd)

filevardef(fout, "hyds",  typeof(fin->hyds),getvardims(fin->hyds))
filevarattdef(fout,"hyds",fin->hyds)
hyds = area_hi2lores_Wrap( lon_in, lat_in, fin->hyds, False, 1, lon_out, lat_out, False)
fout->hyds = where(landsea .eq. 0, hyds, -9999)*1
delete(hyds)

filevardef(fout, "bch",  typeof(fin->bch),getvardims(fin->bch))
filevarattdef(fout,"bch",fin->bch)
bch = area_hi2lores_Wrap( lon_in, lat_in, fin->bch, False, 1, lon_out, lat_out, False)
fout->bch = where(landsea .eq. 0, bch, -9999)*1
delete(bch)

filevardef(fout, "silt",  typeof(fin->silt),getvardims(fin->silt))
filevarattdef(fout,"silt",fin->silt)
silt = area_hi2lores_Wrap( lon_in, lat_in, fin->silt, False, 1, lon_out, lat_out, False)
fout->silt = where(landsea .eq. 0, silt, -9999)*1

filevardef(fout, "sand",  typeof(fin->sand),getvardims(fin->sand))
filevarattdef(fout,"sand",fin->sand)
sand = area_hi2lores_Wrap( lon_in, lat_in, fin->sand, False, 1, lon_out, lat_out, False)
fout->sand = where(landsea .eq. 0, sand, -9999)*1

filevardef(fout, "clay",  typeof(fin->clay),getvardims(fin->clay))
filevarattdef(fout,"clay",fin->clay)
clay = area_hi2lores_Wrap( lon_in, lat_in, fin->clay, False, 1, lon_out, lat_out, False)
fout->clay = where(landsea .eq. 0, clay, -9999)*1

; ====== regridding iveg =====
filevardef( fout, "iveg",  typeof(fin->iveg),getvardims(fin->iveg))
filevarattdef(fout,"iveg",fin->iveg)

iveg    = fin->iveg
nLat_in = dimsizes(iveg(:,0))
nLon_in = dimsizes(iveg(0,:))

Lon_in = new((/nLat_in, nLon_in/),float)
Lat_in = new((/nLat_in, nLon_in/),float)

Lon_out = new((/nlat ,nlon/),float)
Lat_out = new((/nlat, nlon/),float)

do lat_num = 0,nLat_in-1
    Lon_in(lat_num,:) = lon_in
end do
do lon_num = 0,nLon_in-1
    Lat_in(:,lon_num) = lat_in
end do

do lat_num = 0,nlat-1
    Lon_out(lat_num,:) = lon_out
end do
do lon_num = 0,nlon-1
    Lat_out(:,lon_num) = lat_out
end do

printVarSummary(iveg)
iveg_temp = triple2grid2d(ndtooned(Lon_in),ndtooned(Lat_in),ndtooned(iveg), Lon_out,Lat_out, False); nearest
printVarSummary(iveg_temp)
fout->iveg = floattointeger(where(landsea .eq. 0, iveg_temp, -9999)*1)
delete(iveg)
delete(iveg_temp)

; ========== calc isoil ==========
filevardef(fout, "isoil", typeof(fin->isoil), getvardims(fin->isoil))
filevarattdef(fout,"isoil",fin->isoil)

isoil = new((/nlat, nlon/),"integer")
isoil@_FillValue = -9999
FV               = -9999
isoil            = -9999

isoil = where((clay .lt. 0.23) .and. (sand .lt. 0.50)                        ,8 ,isoil)
isoil = where((clay .lt. 0.23) .and. (sand .gt. 0.50) .and. (sand .lt. 0.75) ,4 ,isoil)
isoil = where((clay .lt. 0.23) .and. (sand .ge. 0.75)                        ,1 ,isoil)
isoil = where((clay .ge. 0.23) .and. (clay .lt. 0.28) .and. (sand .lt. 0.45) ,8 ,isoil)
isoil = where((clay .ge. 0.23) .and. (clay .lt. 0.28) .and. (sand .ge. 0.45) ,7 ,isoil)
isoil = where((clay .ge. 0.28) .and. (clay .lt. 0.37) .and. (sand .lt. 0.20) ,2 ,isoil)
isoil = where((clay .ge. 0.28) .and. (clay .lt. 0.37) .and. (sand .ge. 0.20) .and. (sand .lt. 0.43),6 ,isoil)
isoil = where((clay .ge. 0.28) .and. (clay .lt. 0.37) .and. (sand .ge. 0.43) ,7 ,isoil)
isoil = where((clay .ge. 0.37) .and. (clay .lt. 0.41) .and. (sand .lt. 0.20) ,2 ,isoil)
isoil = where((clay .ge. 0.37) .and. (clay .lt. 0.41) .and. (sand .ge. 0.20) .and. (sand .lt. 0.43),6 ,isoil)
isoil = where((clay .ge. 0.37) .and. (clay .lt. 0.41) .and. (sand .ge. 0.43) ,5 ,isoil)
isoil = where((clay .ge. 0.41) .and. (sand .lt. 0.43)                        ,3 ,isoil)
isoil = where((clay .ge. 0.41) .and. (sand .ge. 0.43)                        ,5 ,isoil)
isoil = where((sand.lt.0) .or. (clay.lt.0) .or. (silt .lt. 0)                ,FV,isoil)

fout->isoil = isoil(:,:)*1

delete(clay)
delete(sand)
delete(silt)

; ___________________ 3D ______________________
landsea_12 = new((/12,nlat,nlon/),float)
landsea_6  = new((/6,nlat,nlon/),float)
do mth = 0,11
    landsea_12(mth,:,:) = landsea
    if mth .le. 5 then
        landsea_6(mth,:,:) = landsea
    end if
end do

filevardef( fout, "LAI", typeof(fin->LAI),getvardims(fin->LAI))
filevarattdef(fout,"LAI",fin->LAI)
LAI = area_hi2lores_Wrap( lon_in, lat_in, fin->LAI, False, 1, lon_out, lat_out, False)
fout->LAI = where(landsea_12 .eq. 0, LAI, -9999)*1
delete(LAI)

filevardef(fout, "SnowDepth",  typeof(fin->SnowDepth),getvardims(fin->SnowDepth))
filevarattdef(fout,"SnowDepth",fin->SnowDepth)
SnowDepth = area_hi2lores_Wrap( lon_in, lat_in, fin->SnowDepth, False, 1, lon_out, lat_out, False)
fout->SnowDepth = where(landsea_12 .eq. 0, SnowDepth, -9999)*1
delete(SnowDepth)
delete(landsea_12)

filevardef(fout, "rhosoil_vec",  typeof(fin->rhosoil_vec),getvardims(fin->rhosoil_vec))
filevarattdef(fout,"rhosoil_vec",fin->rhosoil_vec)
rhosoil_vec = area_hi2lores_Wrap( lon_in, lat_in, fin->rhosoil_vec, False, 1, lon_out, lat_out, False)
fout->rhosoil_vec = where(landsea_6 .eq. 0, rhosoil_vec, -9999)*1
delete(rhosoil_vec)

filevardef(fout, "sand_vec",  typeof(fin->sand_vec),getvardims(fin->sand_vec))
filevarattdef(fout,"sand_vec",fin->sand_vec)
sand_vec = area_hi2lores_Wrap( lon_in, lat_in, fin->sand_vec, False, 1, lon_out, lat_out, False)
fout->sand_vec = where(landsea_6 .eq. 0, sand_vec, -9999)*1
delete(sand_vec)

filevardef(fout, "clay_vec",  typeof(fin->clay_vec),getvardims(fin->clay_vec))
filevarattdef(fout,"clay_vec",fin->clay_vec)
clay_vec = area_hi2lores_Wrap( lon_in, lat_in, fin->clay_vec, False, 1, lon_out, lat_out, False)
fout->clay_vec = where(landsea_6 .eq. 0, clay_vec, -9999)*1
delete(clay_vec)

filevardef(fout, "silt_vec",  typeof(fin->silt_vec),getvardims(fin->silt_vec))
filevarattdef(fout,"silt_vec",fin->silt_vec)
silt_vec = area_hi2lores_Wrap( lon_in, lat_in, fin->silt_vec, False, 1, lon_out, lat_out, False)
fout->silt_vec = where(landsea_6 .eq. 0, silt_vec, -9999)*1
delete(silt_vec)


filevardef(fout, "org_vec",  typeof(fin->org_vec),getvardims(fin->org_vec))
filevarattdef(fout,"org_vec",fin->org_vec)
org_vec = area_hi2lores_Wrap( lon_in, lat_in, fin->org_vec, False, 1, lon_out, lat_out, False)
fout->org_vec = where(landsea_6 .eq. 0, org_vec, -9999)*1
delete(org_vec)


filevardef(fout, "sucs_vec",  typeof(fin->sucs_vec),getvardims(fin->sucs_vec))
filevarattdef(fout,"sucs_vec",fin->sucs_vec)
sucs_vec = area_hi2lores_Wrap( lon_in, lat_in, fin->sucs_vec, False, 1, lon_out, lat_out, False)
fout->sucs_vec = where(landsea_6 .eq. 0, sucs_vec, -9999)*1
delete(sucs_vec)

filevardef(fout, "ssat_vec",  typeof(fin->ssat_vec),getvardims(fin->ssat_vec))
filevarattdef(fout,"ssat_vec",fin->ssat_vec)
ssat_vec = area_hi2lores_Wrap( lon_in, lat_in, fin->ssat_vec, False, 1, lon_out, lat_out, False)
fout->ssat_vec = where(landsea_6 .eq. 0, ssat_vec, -9999)*1
delete(ssat_vec)

filevardef(fout, "sfc_vec",  typeof(fin->sfc_vec),getvardims(fin->sfc_vec))
filevarattdef(fout,"sfc_vec",fin->sfc_vec)
sfc_vec = area_hi2lores_Wrap( lon_in, lat_in, fin->sfc_vec, False, 1, lon_out, lat_out, False)
fout->sfc_vec = where(landsea_6 .eq. 0, sfc_vec, -9999)*1
delete(sfc_vec)


filevardef(fout, "swilt_vec",  typeof(fin->swilt_vec),getvardims(fin->swilt_vec))
filevarattdef(fout,"swilt_vec",fin->swilt_vec)
swilt_vec = area_hi2lores_Wrap( lon_in, lat_in, fin->swilt_vec, False, 1, lon_out, lat_out, False)
fout->swilt_vec = where(landsea_6 .eq. 0, swilt_vec, -9999)*1
delete(swilt_vec)


filevardef(fout, "css_vec",  typeof(fin->css_vec),getvardims(fin->css_vec))
filevarattdef(fout,"css_vec",fin->css_vec)
css_vec = area_hi2lores_Wrap( lon_in, lat_in, fin->css_vec, False, 1, lon_out, lat_out, False)
fout->css_vec = where(landsea_6 .eq. 0, css_vec, -9999)*1
delete(css_vec)


filevardef(fout, "cnsd_vec",  typeof(fin->cnsd_vec),getvardims(fin->cnsd_vec))
filevarattdef(fout,"cnsd_vec",fin->cnsd_vec)
cnsd_vec = area_hi2lores_Wrap( lon_in, lat_in, fin->cnsd_vec, False, 1, lon_out, lat_out, False)
fout->cnsd_vec = where(landsea_6 .eq. 0, cnsd_vec, -9999)*1
delete(cnsd_vec)


filevardef(fout, "hyds_vec",  typeof(fin->hyds_vec),getvardims(fin->hyds_vec))
filevarattdef(fout,"hyds_vec",fin->hyds_vec)
hyds_vec = area_hi2lores_Wrap( lon_in, lat_in, fin->hyds_vec, False, 1, lon_out, lat_out, False)
fout->hyds_vec = where(landsea_6 .eq. 0, hyds_vec, -9999)*1
delete(hyds_vec)


filevardef(fout, "bch_vec",  typeof(fin->bch_vec),getvardims(fin->bch_vec))
filevarattdef(fout,"bch_vec",fin->bch_vec)
bch_vec = area_hi2lores_Wrap( lon_in, lat_in, fin->bch_vec, False, 1, lon_out, lat_out, False)
fout->bch_vec = where(landsea_6 .eq. 0, bch_vec, -9999)*1
delete(bch_vec)


filevardef(fout, "watr",  typeof(fin->watr),getvardims(fin->watr))
filevarattdef(fout,"watr",fin->watr)
watr = area_hi2lores_Wrap( lon_in, lat_in, fin->watr, False, 1, lon_out, lat_out, False)
fout->watr = where(landsea_6 .eq. 0, watr, -9999)*1
delete(watr)

filevardef(fout, "patchfrac",  typeof(fin->patchfrac),getvardims(fin->patchfrac))
filevarattdef(fout,"patchfrac",fin->patchfrac)
patchfrac = area_hi2lores_Wrap( lon_in, lat_in, fin->patchfrac, False, 1, lon_out, lat_out, False)
fout->patchfrac(0,:,:) = where(landsea_6(0,:,:) .eq. 0, patchfrac(0,:,:), -9999)*1
delete(patchfrac)

delete(landsea_6)


; ___________________ 4D ______________________
landsea_12_6 = new((/12,6,nlat,nlon/),float)
do mth = 0,11
 do layer = 0,5
    landsea_12_6(mth,layer,:,:) = landsea
 end do
end do

filevardef(fout, "SoilMoist",  typeof(fin->SoilMoist),getvardims(fin->SoilMoist))
filevarattdef(fout,"SoilMoist",fin->SoilMoist)
SoilMoist = area_hi2lores_Wrap( lon_in, lat_in, fin->SoilMoist, False, 1, lon_out, lat_out, False)
fout->SoilMoist = where(landsea_12_6 .eq. 0, SoilMoist, -9999)*1
delete(SoilMoist)

filevardef(fout, "SoilTemp",  typeof(fin->SoilTemp),getvardims(fin->SoilTemp))
filevarattdef(fout,"SoilTemp",fin->SoilTemp)
SoilTemp = area_hi2lores_Wrap( lon_in, lat_in, fin->SoilTemp, False, 1, lon_out, lat_out, False)
fout->SoilTemp = where(landsea_12_6 .eq. 0, SoilTemp, -9999)*1
delete(SoilTemp)

; ============================

; var_name_2D = (/"landsea","rhosoil", "sand", "clay", "silt", "organic", "bch",\
;               "sucs", "ssat", "sfc", "swilt", "css", "cnsd", "hyds", \
;               "soil_color", "Albedo", "albedo2",   \
;               "Sy", "dtb", "drainage_density", "slope", "slope_std",  \
;               "elevation", "elevation_std", "permeability"    /)
; var_name_2D_int = (/"iveg", "isoil"/)
; var_name_3D = (/ "rhosoil_vec", "sand_vec", "clay_vec", "silt_vec", "org_vec", "bch_vec",\
;               "sucs_vec", "ssat_vec", "sfc_vec", "swilt_vec", "css_vec", "cnsd_vec", \
;               "hyds_vec", "watr" /)
; var_name_3D_time = (/"LAI", "SnowDepth"/)
; var_name_4D = (/"SoilMoist","SoilTemp"/)


setfileoption(fout,"DefineMode",False)
print("Exit DefineMode")
delete(fAtt)
delete(dimNames)
delete(dimSizes)
delete(dimUnlim)

; _______________________ Forming mask nc data ____________________________
fname_mask = "./nc_output/gridinfo_AWAP_OpenLandMap_ELEV_DLCM_fix_10km_mask.nc"
system("/bin/rm -f " + fname_mask)    ; remove if exists
fmask  = addfile (fname_mask, "c")     ; open output file

; explicitly declare file definition mode. Improve efficiency.
setfileoption(fmask,"DefineMode",True)

; create global attributes of the file
fAtt               = True            ; assign file attributes
fAtt@title         = "Australia landmask for " + fname_out
fAtt@source_file   = fname_out
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( fmask, fAtt )            ; copy file attributes

dimNames = (/ "latitude", "longitude" /)
dimSizes = (/ nlat , nlon  /)
dimUnlim = (/ False, False /)
filedimdef(fmask,dimNames,dimSizes,dimUnlim)

; predefine the the dimensionality of the variables to be written out
print("Predefine")

filevardef(fmask, "landsea",typeof(fout->landsea),getvardims(fout->landsea))
filevardef(fmask, "latitude",typeof(fout->latitude),getvardims(fout->latitude))
filevardef(fmask, "longitude",typeof(fout->longitude),getvardims(fout->longitude))
printVarSummary(fmask->landsea)

print("Copy attributes")
filevarattdef(fmask,"landsea",fout->landsea)
filevarattdef(fmask,"latitude",fout->latitude)
filevarattdef(fmask,"longitude",fout->longitude)
setfileoption(fmask,"DefineMode",False)
print("Exit DefineMode")

fmask->landsea   = fout->landsea
fmask->latitude  = fout->latitude
fmask->longitude = fout->longitude

end
