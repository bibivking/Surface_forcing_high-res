;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

; __________________________________ MMY _______________________________________
; Purpose: regrid LAI data,
;          read soil texture data,
;          calculate soil hydraulic parameters
;          form gridinfo data
; ______________________________________________________________________________

;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 500000000000 ;
end setvalues
;_____________________________________

begin

fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_CSIRO_AU_NAT.nc"
finout  = addfile (fname_inout, "w")     ; open output file

fname_grid = "/srv/ccrc/data45/z3509830/CABLE_runs/CABLE_site_runs/CABLE_AUX-dev/offline/CABLE_UNSW_GSWP3_gridinfo_0.5x0.5_site.nc"
                 ;lat from + to - lon from -180 to 180
fgrid      = addfile (fname_grid,"r")

;fname_LAI  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/lai_climatology_AWAP_grid.nc" ; Gimms
fname_LAI  = "/srv/ccrc/data04/z3509830/Fluxnet_data/All_flux_sites_processed/Copernicus_LAI_time_series/Aus/monthly_climatology.nc" ; Anna's Copernicus
fLAI       = addfile(fname_LAI, "r")

; _________________________ Check Value ____________________________
pic = "check_value"
wks = gsn_open_wks("pdf",pic)
gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")
res            = True
res@cnFillMode = "RasterFill"            ; Raster Mode
res@cnFillOn   = True
res@cnLinesOn  = False

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

soil_depth= (/0.011,0.051,0.157,0.4385,1.1855,3.164/)
latitude  = fspan( lat_s, lat_e, nlat)
longitude = fspan( lon_s, lon_e, nlon)

; ----------------- 3D --------------------
;delete(finout->LAI)

; =======  LAI  ========
filevardef( finout, "LAI", "float", (/"time", "latitude", "longitude" /))

; read LAI, LON and LAT in the input lai file
LAI = fLAI->LAI
LON = fLAI->lon
LAT = fLAI->lat

lai = new((/ntime, nlat, nlon/),  float)

; interpolate to 0.05 degree resolution (AWAP)
lai = area_hi2lores_Wrap( doubletofloat(LON), doubletofloat(LAT), \
      doubletofloat(LAI)*1. , False, 1, finout->longitude,           \
      finout->latitude, False)
; plot
; check lai
;printVarSummary(finout->LAI)
;printVarSummary(finout->LAI&latitude)
; add attributions
finout->LAI               = lai*1.
finout->LAI@long_name     = "Leaf area index"
finout->LAI@_FillValue    = -9999. ; set -9999. because no missing value point in gridinfo
finout->LAI               = lai
;finout->LAI!0             = "time"
;finout->LAI!1             = "latitude"
;finout->LAI!2             = "longitude"
;finout->LAI&time          = ispan(1,ntime,1)
;finout->LAI&latitude      = latitude
;finout->LAI&longitude     = longitude

plot = gsn_csm_contour(wks, LAI(0,:,:)*1.0,res)
plot = gsn_csm_contour(wks,finout->LAI(0,:,:)*1.0,res)
delete(lai)
delete(LON)
delete(LAT)
delete(LAI)


; =======  SOIL  ========
rhosoil_temp = new((/nsdepth, nlat, nlon/), float)
sand_temp    = new((/nsdepth, nlat, nlon/), float)
clay_temp    = new((/nsdepth, nlat, nlon/), float)
silt_temp    = new((/nsdepth, nlat, nlon/), float)
organic_temp = new((/nsdepth, nlat, nlon/), float)

; read soil texture nc file
level_class = (/"000-005","005-015","015-030","030-060","060-100","100-200"/)

do level = 0,5
    print(level_class(level))
    frho  = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/Bulk_density_"+level_class(level)+"_AU_NAT_C.nc", "r")
    fsand = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/Sand_"+level_class(level)+"_AU_NAT_C.nc", "r")
    fclay = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/Clay_"+level_class(level)+"_AU_NAT_C.nc", "r")
    fsilt = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/Silt_"+level_class(level)+"_AU_NAT_C.nc", "r")
    forg  = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/Organic_C_"+level_class(level)+"_AU_NAT_C.nc", "r")

    LAT = frho->lat
    LON = frho->lon

    ; rhosoil g/cm3 -> kg/m3
    rhosoil_temp(level,:,:) = area_hi2lores_Wrap( LON, LAT, frho->Bulk_density*1000.,\
                              False, 1, finout->longitude, finout->latitude, False)
    plot = gsn_csm_contour(wks, frho->Bulk_density*1000.,res)
    plot = gsn_csm_contour(wks, rhosoil_temp(level,:,:)*1.,res)
    ; sand, clay, silt and organic % -> m3/m3
    sand_temp(level,:,:)    = area_hi2lores_Wrap( LON, LAT, fsand->Sand/100.,\
                              False, 1, finout->longitude, finout->latitude, False)
    clay_temp(level,:,:)    = area_hi2lores_Wrap( LON, LAT, fclay->Clay/100.,\
                              False, 1, finout->longitude, finout->latitude, False)
    silt_temp(level,:,:)    = area_hi2lores_Wrap( LON, LAT, fsilt->Silt/100.,\
                              False, 1, finout->longitude, finout->latitude, False)
    organic_temp(level,:,:) = area_hi2lores_Wrap( LON, LAT, forg->Organic_C/100.,\
                              False, 1, finout->longitude, finout->latitude, False)

end do


rhosoil_vec = new((/nsdepth, nlat, nlon/), float)
sand_vec    = new((/nsdepth, nlat, nlon/), float)
clay_vec    = new((/nsdepth, nlat, nlon/), float)
silt_vec    = new((/nsdepth, nlat, nlon/), float)
org_vec     = new((/nsdepth, nlat, nlon/), float)
hyds_vec    = new((/nsdepth, nlat, nlon/), float)
bch_vec     = new((/nsdepth, nlat, nlon/), float)
sucs_vec    = new((/nsdepth, nlat, nlon/), float)
ssat_vec    = new((/nsdepth, nlat, nlon/), float)
swilt_vec   = new((/nsdepth, nlat, nlon/), float)
sfc_vec     = new((/nsdepth, nlat, nlon/), float)
css_vec     = new((/nsdepth, nlat, nlon/), float)
cnsd_vec    = new((/nsdepth, nlat, nlon/), float)
watr        = new((/nsdepth, nlat, nlon/), float)

rhosoil_vec(0,:,:) = rhosoil_temp(0,:,:)
sand_vec(0,:,:)    = sand_temp(0,:,:)
clay_vec(0,:,:)    = clay_temp(0,:,:)
silt_vec(0,:,:)    = silt_temp(0,:,:)
org_vec(0,:,:)     = organic_temp(0,:,:)

rhosoil_vec(1,:,:) = (rhosoil_temp(0,:,:)*0.028 + rhosoil_temp(1,:,:)*0.03)/0.058
sand_vec(1,:,:)    = (sand_temp(0,:,:)*0.028 + sand_temp(1,:,:)*0.03)/0.058
clay_vec(1,:,:)    = (clay_temp(0,:,:)*0.028 + clay_temp(1,:,:)*0.03)/0.058
silt_vec(1,:,:)    = (silt_temp(0,:,:)*0.028 + silt_temp(1,:,:)*0.03)/0.058
org_vec(1,:,:)     = (organic_temp(0,:,:)*0.028 + organic_temp(1,:,:)*0.03)/0.058

rhosoil_vec(2,:,:) = (rhosoil_temp(1,:,:)*0.07 + rhosoil_temp(2,:,:)*0.084)/0.154
sand_vec(2,:,:)    = (sand_temp(1,:,:)*0.07 + sand_temp(2,:,:)*0.084)/0.154
clay_vec(2,:,:)    = (clay_temp(1,:,:)*0.07 + clay_temp(2,:,:)*0.084)/0.154
silt_vec(2,:,:)    = (silt_temp(1,:,:)*0.07 + silt_temp(2,:,:)*0.084)/0.154
org_vec(2,:,:) = (organic_temp(1,:,:)*0.07 + organic_temp(2,:,:)*0.084)/0.154

rhosoil_vec(3,:,:) = (rhosoil_temp(2,:,:)*0.066 + rhosoil_temp(3,:,:)*0.3 + rhosoil_temp(4,:,:)*0.043)/0.409
sand_vec(3,:,:)    = (sand_temp(2,:,:)*0.066 + sand_temp(3,:,:)*0.3 + sand_temp(4,:,:)*0.043)/0.409
clay_vec(3,:,:)    = (clay_temp(2,:,:)*0.066 + clay_temp(3,:,:)*0.3 + clay_temp(4,:,:)*0.043)/0.4091
silt_vec(3,:,:)    = (silt_temp(2,:,:)*0.066 + silt_temp(3,:,:)*0.3 + silt_temp(4,:,:)*0.043)/0.409
org_vec(3,:,:) = (organic_temp(2,:,:)*0.066 + organic_temp(3,:,:)*0.3 + organic_temp(4,:,:)*0.043)/0.409

rhosoil_vec(4,:,:) = (rhosoil_temp(4,:,:)*0.357 + rhosoil_temp(4,:,:)*0.728)/1.085
sand_vec(4,:,:)    = (sand_temp(4,:,:)*0.357 + sand_temp(4,:,:)*0.728)/1.085
clay_vec(4,:,:)    = (clay_temp(4,:,:)*0.357 + clay_temp(4,:,:)*0.728)/1.085
silt_vec(4,:,:)    = (silt_temp(4,:,:)*0.357 + silt_temp(4,:,:)*0.728)/1.085
org_vec(4,:,:) = (organic_temp(4,:,:)*0.357 + organic_temp(4,:,:)*0.728)/1.085

rhosoil_vec(5,:,:) = rhosoil_temp(5,:,:)
sand_vec(5,:,:)    = sand_temp(5,:,:)
clay_vec(5,:,:)    = clay_temp(5,:,:)
silt_vec(5,:,:)    = silt_temp(5,:,:)
org_vec(5,:,:) = organic_temp(5,:,:)

; ________________________________ Mark Decker's equations for elev file ___________________________________
; From /g/data1/w35/mrd561/CABLE2_runs/CMIP6-GM2-testing/ssgw_Feb23.2018/opt/surface_data/add_derived_SWC.py

hyds_vec = (1.0-org_vec) * 0.00706 * ( 10.0 ^ (-0.60 + 1.26*sand_vec - 0.64*clay_vec) ) + org_vec*10^(-4)
bch_vec  = (1.0-org_vec) * ( 3.1 + 15.7*clay_vec - 0.3*sand_vec ) + org_vec*3.0
sucs_vec = (1.0-org_vec) * 10.0 * 10.0^( 1.54 - 0.95*sand_vec + 0.63*silt_vec ) + org_vec*10.3
ssat_vec = (1.0-org_vec) * ( 0.505 - 0.142*sand_vec - 0.037*clay_vec ) + org_vec*0.6
watr     = (1.0-org_vec) * ( 0.02 + 0.018*clay_vec ) + org_vec*0.15

sst_tmp = ssat_vec
sst_tmp = where(sst_tmp .gt. 0.85, 0.85, sst_tmp)
sst_tmp = where(sst_tmp .lt. 0.15, 0.15, sst_tmp)
sst_tmp = 1.0 - sst_tmp

iveg    = finout->iveg

psi_tmp = ssat_vec(0,:,:)
psi_tmp = 2750000.
psi_tmp = where( iveg .le. 3, 2550000.0, psi_tmp)
psi_tmp = where( iveg .eq. 4, 2240000.0, psi_tmp)
psi_tmp = where( iveg .eq. 5, 4280000.0, psi_tmp)
do level = 0,5
    swilt_vec(level,:,:) = (ssat_vec(level,:,:) - watr(level,:,:)) \
                          * ((psi_tmp/sucs_vec(level,:,:)) ^ (-1.0/bch_vec(level,:,:)))\
                          + watr(level,:,:)
end do
sfc_vec  = (ssat_vec - watr) * ( 1.157407 * 10^(-06) / hyds_vec) ^ (1.0 / (2.0*bch_vec + 3.0) ) + watr
css_vec  = (1.0-org_vec) * ( 850*(1.0 - sand_vec - clay_vec) + 865.0*clay_vec + 750.0*sand_vec ) + org_vec*950.0
cnsd_vec = (1.0-org_vec) * ( 0.135*sst_tmp + 0.0239/sst_tmp )  / (1.0 - 0.947*sst_tmp) + org_vec*0.05

; __________________ Note that ! ___________________
; Below are the soil properties for fully organic soil in
; ./Marks_latest_branch_with_fixes/core/biogeophys/cable_common.F90
; They are different from these parameters used in this script!
;        hyds_vec = 1.0e-4,&
;        sucs_vec = 10.3,   &
;        bch_vec  = 2.91,     &
;        ssat_vec = 0.9,    &
;        watr     = 0.1,&
;        css_vec  = 4000.0,&
;        cnsd_vec = 0.1

var_name = (/ "rhosoil_vec", "sand_vec", "clay_vec", "silt_vec", "org_vec", "bch_vec",\
              "sucs_vec", "ssat_vec", "sfc_vec", "swilt_vec", "css_vec", "cnsd_vec", \
              "hyds_vec", "watr" /)

do var_num = 0,dimsizes(var_name)-1
    filevardef(finout, var_name(var_num), "float", (/ "soil_depth", "latitude", "longitude" /))
    ;finout->$var_name(var_num)$!0          = "soil_depth"
    ;finout->$var_name(var_num)$!1          = "latitude"
    ;finout->$var_name(var_num)$!2          = "longitude"
    ;finout->$var_name(var_num)$&soil_depth = soil_depth
    ;finout->$var_name(var_num)$&latitude   = latitude
    ;finout->$var_name(var_num)$&longitude  = longitude
    finout->$var_name(var_num)$@_FillValue = -9999.
end do

finout->rhosoil_vec = rhosoil_vec*1.
finout->sand_vec    = sand_vec*1.
finout->clay_vec    = clay_vec*1.
finout->silt_vec    = silt_vec*1.
finout->org_vec     = org_vec*1.
finout->hyds_vec    = hyds_vec/1000.
finout->bch_vec     = bch_vec*1.
finout->sucs_vec    = sucs_vec*(-1.0)/1000. ; sucs should be positive value?? or negetive value?
finout->ssat_vec    = ssat_vec*1.
finout->swilt_vec   = swilt_vec*1.
finout->sfc_vec     = sfc_vec*1.
finout->css_vec     = css_vec*1.
finout->cnsd_vec    = cnsd_vec*1.
finout->watr        = watr*1.

do var_num = 0,dimsizes(var_name)-1
  plot = gsn_csm_contour(wks,finout->$var_name(var_num)$(0,:,:)*1.0,res)
end do

; ----------------- 2D --------------------

var_name_2D = (/ "rhosoil", "sand", "clay", "silt", "organic", "bch",\
              "sucs", "ssat", "sfc", "swilt", "css", "cnsd", "hyds" /)

do var_num = 0,dimsizes(var_name_2D)-1
    filevardef(finout, var_name_2D(var_num), "float", (/"latitude", "longitude" /))
    ;finout->$var_name_2D(var_num)$!0          = "latitude"
    ;finout->$var_name_2D(var_num)$!1          = "longitude"
    ;finout->$var_name_2D(var_num)$&latitude   = latitude
    ;finout->$var_name_2D(var_num)$&longitude  = longitude
    finout->$var_name_2D(var_num)$@_FillValue = -9999.
end do

finout->rhosoil = (rhosoil_vec(0,:,:)*0.011 + rhosoil_vec(1,:,:)*0.051 \
                  + rhosoil_vec(2,:,:)*0.157 + rhosoil_vec(3,:,:)*0.4385 \
                  + rhosoil_vec(4,:,:)*1.1855 + rhosoil_vec(5,:,:)*3.164)/4.6
finout->sand    = (sand_vec(0,:,:)*0.011 + sand_vec(1,:,:)*0.051 \
                  + sand_vec(2,:,:)*0.157 + sand_vec(3,:,:)*0.4385 \
                  + sand_vec(4,:,:)*1.1855 + sand_vec(5,:,:)*3.164)/4.6
finout->clay    = (clay_vec(0,:,:)*0.011 + clay_vec(1,:,:)*0.051 \
                  + clay_vec(2,:,:)*0.157 + clay_vec(3,:,:)*0.4385 \
                  + clay_vec(4,:,:)*1.1855 + clay_vec(5,:,:)*3.164)/4.6
finout->silt    = (silt_vec(0,:,:)*0.011 + silt_vec(1,:,:)*0.051 \
                  + silt_vec(2,:,:)*0.157 + silt_vec(3,:,:)*0.4385 \
                  + silt_vec(4,:,:)*1.1855 + silt_vec(5,:,:)*3.164)/4.6
finout->organic = (org_vec(0,:,:)*0.011 + org_vec(1,:,:)*0.051 \
                  + org_vec(2,:,:)*0.157 + org_vec(3,:,:)*0.4385 \
                  + org_vec(4,:,:)*1.1855 + org_vec(5,:,:)*3.164)/4.6

finout->hyds    = (hyds_vec(0,:,:)*0.011 + hyds_vec(1,:,:)*0.051 \
                  + hyds_vec(2,:,:)*0.157 + hyds_vec(3,:,:)*0.4385 \
                  + hyds_vec(4,:,:)*1.1855 + hyds_vec(5,:,:)*3.164)/4.6\
                  /1000.
finout->bch     = (bch_vec(0,:,:)*0.011 + bch_vec(1,:,:)*0.051 \
                  + bch_vec(2,:,:)*0.157 + bch_vec(3,:,:)*0.4385 \
                  + bch_vec(4,:,:)*1.1855 + bch_vec(5,:,:)*3.164)/4.6
finout->sucs    = (sucs_vec(0,:,:)*0.011 + sucs_vec(1,:,:)*0.051 \
                  + sucs_vec(2,:,:)*0.157 + sucs_vec(3,:,:)*0.4385 \
                  + sucs_vec(4,:,:)*1.1855 + sucs_vec(5,:,:)*3.164)/4.6\
                  *(-1.0)/1000. ; sucs should be positive value?? or negetive value?
finout->ssat    = (ssat_vec(0,:,:)*0.011 + ssat_vec(1,:,:)*0.051 \
                  + ssat_vec(2,:,:)*0.157 + ssat_vec(3,:,:)*0.4385 \
                  + ssat_vec(4,:,:)*1.1855 + ssat_vec(5,:,:)*3.164)/4.6
finout->swilt   = (swilt_vec(0,:,:)*0.011 + swilt_vec(1,:,:)*0.051 \
                  + swilt_vec(2,:,:)*0.157 + swilt_vec(3,:,:)*0.4385 \
                  + swilt_vec(4,:,:)*1.1855 + swilt_vec(5,:,:)*3.164)/4.6
finout->sfc     = (sfc_vec(0,:,:)*0.011 + sfc_vec(1,:,:)*0.051 \
                  + sfc_vec(2,:,:)*0.157 + sfc_vec(3,:,:)*0.4385 \
                  + sfc_vec(4,:,:)*1.1855 + sfc_vec(5,:,:)*3.164)/4.6
finout->css     = (css_vec(0,:,:)*0.011 + css_vec(1,:,:)*0.051 \
                  + css_vec(2,:,:)*0.157 + css_vec(3,:,:)*0.4385 \
                  + css_vec(4,:,:)*1.1855 + css_vec(5,:,:)*3.164)/4.6
finout->cnsd    = (cnsd_vec(0,:,:)*0.011 + cnsd_vec(1,:,:)*0.051 \
                  + cnsd_vec(2,:,:)*0.157 + cnsd_vec(3,:,:)*0.4385 \
                  + cnsd_vec(4,:,:)*1.1855 + cnsd_vec(5,:,:)*3.164)/4.6


; Zobler soil type from Mark Decker's /srv/ccrc/data44/z3362708/CABLE/Data_set_codes/gswp3_srf_creation/zobler_type.ncl
filevardef( finout, "isoil", "integer", (/ "latitude", "longitude" /)) ; Need to be calculated
isoil = new(dimsizes(finout->sand*1.0),"integer")
FV    = -9999
isoil = -9999

isoil = where((finout->clay .lt. 0.23) .and. (finout->sand .lt. 0.50)                                ,8 ,isoil)
isoil = where((finout->clay .lt. 0.23) .and. (finout->sand .gt. 0.50) .and. (finout->sand .lt. 0.75) ,4 ,isoil)
isoil = where((finout->clay .lt. 0.23) .and. (finout->sand .ge. 0.75)                                ,1 ,isoil)
isoil = where((finout->clay .ge. 0.23) .and. (finout->clay .lt. 0.28) .and. (finout->sand .lt. 0.45) ,8 ,isoil)
isoil = where((finout->clay .ge. 0.23) .and. (finout->clay .lt. 0.28) .and. (finout->sand .ge. 0.45) ,7 ,isoil)
isoil = where((finout->clay .ge. 0.28) .and. (finout->clay .lt. 0.37) .and. (finout->sand .lt. 0.20) ,2 ,isoil)
isoil = where((finout->clay .ge. 0.28) .and. (finout->clay .lt. 0.37) .and. (finout->sand .ge. 0.20) .and. (finout->sand .lt. 0.43),6 ,isoil)
isoil = where((finout->clay .ge. 0.28) .and. (finout->clay .lt. 0.37) .and. (finout->sand .ge. 0.43) ,7 ,isoil)
isoil = where((finout->clay .ge. 0.37) .and. (finout->clay .lt. 0.41) .and. (finout->sand .lt. 0.20) ,2 ,isoil)
isoil = where((finout->clay .ge. 0.37) .and. (finout->clay .lt. 0.41) .and. (finout->sand .ge. 0.20) .and. (finout->sand .lt. 0.43),6 ,isoil)
isoil = where((finout->clay .ge. 0.37) .and. (finout->clay .lt. 0.41) .and. (finout->sand .ge. 0.43) ,5 ,isoil)
isoil = where((finout->clay .ge. 0.41) .and. (finout->sand .lt. 0.43)                                ,3 ,isoil)
isoil = where((finout->clay .ge. 0.41) .and. (finout->sand .ge. 0.43)                                ,5 ,isoil)
isoil = where((finout->sand.lt.0) .or. (finout->clay.lt.0) .or. (finout->silt .lt. 0)                ,FV,isoil)

finout->isoil = isoil

do var_num = 0,dimsizes(var_name_2D)-1
  plot = gsn_csm_contour(wks,finout->$var_name_2D(var_num)$*1.0,res)
end do

; ----------------- add attributes ------------------------

; ================ Soil ===================
finout->rhosoil_vec@long_name = "Soil bulk density"
finout->rhosoil_vec@units     = "kg/m3"
finout->sand_vec@long_name    = "Sand fraction"
finout->sand_vec@units        = "m3/m3"
finout->clay_vec@long_name    = "Clay fraction"
finout->clay_vec@units        = "m3/m3"
finout->silt_vec@long_name    = "Silt fraction"
finout->silt_vec@units        = "m3/m3"
finout->org_vec@long_name     = "Organic carbon fraction"
finout->org_vec@units         = "m3/m3"
finout->hyds_vec@long_name    = "saturated soil conductivity"
finout->hyds_vec@units        = "mm/s"
finout->bch_vec@long_name     = "Clapp-Hornberger b coefficient"
finout->sucs_vec@long_name    = "Saturated soil water suction"
finout->sucs_vec@units        = "m" ; check it with original equation
finout->ssat_vec@long_name    = "Volumetric soil moisture content at saturation"
finout->ssat_vec@units        = "m3/m3"
finout->swilt_vec@long_name   = "Volumetric soil moisture content at wilting point"
finout->swilt_vec@units       = "m3/m3"
finout->sfc_vec@long_name     = "Field capacity (volumetric soil moisture content at critical point)" ;
finout->sfc_vec@units         = "m3/m3"
finout->css_vec@long_name     = "Soil specific heat capacity" ;
finout->css_vec@units         = "J/kg/K" ;
finout->cnsd_vec@long_name    = "Thermal conductivity"
finout->cnsd_vec@units        = "W/m/K" ;
finout->watr@long_name        = "Residual water content of the soil"
finout->watr@units            = "m3/m3"


finout->rhosoil@long_name = "Soil bulk density"
finout->rhosoil@units     = "kg/m3"
finout->sand@long_name    = "Sand fraction"
finout->sand@units        = "m3/m3"
finout->clay@long_name    = "Clay fraction"
finout->clay@units        = "m3/m3"
finout->silt@long_name    = "Silt fraction"
finout->silt@units        = "m3/m3"
finout->organic@long_name = "Organic carbon fraction"
finout->organic@units     = "m3/m3"
finout->hyds@long_name    = "saturated soil conductivity"
finout->hyds@units        = "mm/s"
finout->bch@long_name     = "Clapp-Hornberger b coefficient"
finout->sucs@long_name    = "Saturated soil water suction"
finout->sucs@units        = "m" ; check it with original equation
finout->ssat@long_name    = "Volumetric soil moisture content at saturation"
finout->ssat@units        = "m3/m3"
finout->swilt@long_name   = "Volumetric soil moisture content at wilting point"
finout->swilt@units       = "m3/m3"
finout->sfc@long_name     = "Field capacity (volumetric soil moisture content at critical point)" ;
finout->sfc@units         = "m3/m3"
finout->css@long_name     = "Soil specific heat capacity" ;
finout->css@units         = "J/kg/K" ;
finout->cnsd@long_name    = "Thermal conductivity"
finout->cnsd@units        = "W/m/K" ;


finout->isoil@long_name     = "Zobler soil type";
finout->isoil@missing_value = -9999


end
