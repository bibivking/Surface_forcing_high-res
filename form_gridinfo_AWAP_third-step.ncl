;*******************************************
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_code.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/gsn_csm.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/contributed.ncl"
load "$NCARG_ROOT/lib/ncarg/nclscripts/csm/shea_util.ncl"
;*******************************************

; __________________________________ MMY _______________________________________
; Purpose: mask out the missing value pixels, and make mask file
; ______________________________________________________________________________


;______ From Mark Decker's code ______
setvalues NhlGetWorkspaceObjectId()
  "wsMaximumSize" : 500000000000 ;
end setvalues
;_____________________________________

begin

; _________________ option __________________
soil_data_type = 1 ; 0: CSIRO, 1: OpenLandMap
iveg_type       = "DLCM" ; Dynamic Land Cover Map across Australia
                 ;"NVIS" ; NVIS iveg only for SE Australia
                 ;"STD"  ; CABLE standard input

; ________________ file name ________________
if soil_data_type .eq. 0 then
  if iveg_type .eq. "STD" then
    fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_CSIRO_AU_NAT_ELEV.nc"
    finout  = addfile (fname_inout, "w")     ; open output file
    pic = "check_mask_CSIRO"
    fname_mask   = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_CSIRO_AU_NAT_ELEV_mask.nc"
  else
    fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_CSIRO_AU_NAT_ELEV_"+iveg_type+".nc"
    finout  = addfile (fname_inout, "w")     ; open output file
    pic = "check_mask_CSIRO_"+iveg_type
    fname_mask   = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_CSIRO_AU_NAT_ELEV_"+iveg_type+"_mask.nc"
  end if
else if soil_data_type .eq. 1 then
  if iveg_type .eq. "STD" then
    fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_OpenLandMap_ELEV.nc"
    finout  = addfile (fname_inout, "w")     ; open output file
    pic = "check_mask_Openland"
    fname_mask   = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_OpenLandMap_ELEV_mask.nc"
  else
    fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_OpenLandMap_ELEV_"+iveg_type+".nc"
    finout  = addfile (fname_inout, "w")     ; open output file
    pic = "check_mask_Openland_"+iveg_type
    fname_mask   = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/gridinfo_AWAP_OpenLandMap_ELEV_"+iveg_type+"_mask.nc"
  end if
end if
end if

wks = gsn_open_wks("pdf",pic)
gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")
res            = True
res@cnFillMode = "RasterFill"            ; Raster Mode
res@cnFillOn   = True
res@cnLinesOn  = False

var_name_2D = (/"rhosoil", "sand", "clay", "silt", "organic", "bch",\
              "sucs", "ssat", "sfc", "swilt", "css", "cnsd", "hyds", \
              "soil_color", "Albedo", "albedo2",   \
              "Sy", "dtb", "drainage_density", "slope", "slope_std",  \
              "elevation", "elevation_std", "permeability"    /)
var_name_2D_int = (/"iveg", "isoil"/)
var_name_3D = (/ "rhosoil_vec", "sand_vec", "clay_vec", "silt_vec", "org_vec", "bch_vec",\
              "sucs_vec", "ssat_vec", "sfc_vec", "swilt_vec", "css_vec", "cnsd_vec", \
              "hyds_vec", "watr" /)
; "patchfrac" (1,:,:)
var_name_3D_time = (/"LAI", "SnowDepth"/)
var_name_4D = (/"SoilMoist","SoilTemp"/)

mask_out = finout->landsea
mask_out = 0.

; ----------- 2D -----------

do var_num = 0,dimsizes(var_name_2D_int)-1

    res@tiMainString = var_name_2D_int(var_num)

    print(var_name_2D_int(var_num))
    print(finout->$var_name_2D_int(var_num)$@_FillValue)
    print(min(finout->$var_name_2D_int(var_num)$))
    print(max(finout->$var_name_2D_int(var_num)$))

    mask_out = where( ismissing(finout->$var_name_2D_int(var_num)$) , 1., mask_out )
    ;plot = gsn_csm_contour(wks, mask_out, res)

end do


do var_num = 0,dimsizes(var_name_2D)-1

    res@tiMainString = var_name_2D(var_num)

    print(var_name_2D(var_num))
    print(finout->$var_name_2D(var_num)$@_FillValue)
    print(min(finout->$var_name_2D(var_num)$))
    print(max(finout->$var_name_2D(var_num)$))

    mask_out = where( ismissing(finout->$var_name_2D(var_num)$) , 1., mask_out )
    ;plot = gsn_csm_contour(wks, mask_out, res)

end do

; ----------- 3D -----------
tmp = finout->$var_name_3D(0)$
tmp = 0.

do var_num = 0,dimsizes(var_name_3D)-1

    print(var_name_3D(var_num))
    print(finout->$var_name_3D(var_num)$@_FillValue)
    print(min(finout->$var_name_3D(var_num)$))
    print(max(finout->$var_name_3D(var_num)$))

    tmp = where( ismissing(finout->$var_name_3D(var_num)$) , 1., tmp )
end do

do level = 0, 5
   res@tiMainString = "3D level " + level
   mask_out = where( tmp(level,:,:) .eq. 1. , 1., mask_out )
   ;plot = gsn_csm_contour(wks, mask_out, res)
end do

delete(tmp)

; ----------- LAI -----------
tmp = finout->LAI
tmp = 0.

print("LAI")
print(finout->LAI@_FillValue)
print(min(finout->LAI))
print(max(finout->LAI))

tmp = where( ismissing(finout->LAI) , 1., tmp )

do time = 0, 11
   res@tiMainString = "LAI time " + time
   mask_out = where( tmp(time,:,:) .eq. 1. , 1., mask_out )
   ;plot = gsn_csm_contour(wks, mask_out, res)
end do
delete(tmp)

; ----------- 4D -----------
tmp = finout->SoilTemp
tmp = 0.

print("SoilTemp")
print(finout->SoilTemp@_FillValue)
print(min(finout->SoilTemp))
print(max(finout->SoilTemp))

tmp = where( finout->SoilTemp .lt. 0 , 1., tmp )

do time = 0, 11
  do level = 0, 5
     res@tiMainString = "SoilTemp time "+time+" level " + level
     mask_out = where( tmp(time,level,:,:) .eq. 1. , 1., mask_out )
     ;plot     = gsn_csm_contour(wks, mask_out, res)
  end do
end do

; =============================== Mask Out =====================================

; ------------ landsea -------------
print("landsea")
res@tiMainString = "landsea"
finout->landsea = where(mask_out .eq. 1. , 1., 0. )
plot = gsn_csm_contour(wks, finout->landsea, res)
finout->landsea@_FillValue = -9999.

; ----------- 2D -----------
do var_num = 0,dimsizes(var_name_2D)-1
    print(var_name_2D(var_num))
    res@tiMainString = var_name_2D(var_num)
    finout->$var_name_2D(var_num)$ = where( mask_out .eq. 1. ,\
            -9999., \
            finout->$var_name_2D(var_num)$*1 )
    plot = gsn_csm_contour(wks, finout->$var_name_2D(var_num)$, res)
    finout->$var_name_2D(var_num)$@_FillValue = -9999.
end do

; ----------- 2D_int ----------
do var_num = 0,dimsizes(var_name_2D_int)-1
    print(var_name_2D_int(var_num))
    res@tiMainString = var_name_2D_int(var_num)
    finout->$var_name_2D_int(var_num)$ = where( mask_out .eq. 1. ,\
            -9999, \
            finout->$var_name_2D_int(var_num)$*1 )
    plot = gsn_csm_contour(wks, finout->$var_name_2D_int(var_num)$, res)
    finout->$var_name_2D_int(var_num)$@_FillValue = -9999
end do

; ----------- 3D -----------
do var_num = 0,dimsizes(var_name_3D)-1
    print(var_name_3D(var_num))
    do level = 0, 5
       res@tiMainString = var_name_3D(var_num)+ " level " + level
       finout->$var_name_3D(var_num)$(level,:,:) = where( mask_out .eq. 1. ,\
              -9999.,\
              finout->$var_name_3D(var_num)$(level,:,:) )
       plot = gsn_csm_contour(wks, finout->$var_name_3D(var_num)$(level,:,:), res)
    end do
    finout->$var_name_3D(var_num)$@_FillValue = -9999.
end do

; ----------- 3D_time -----------
do var_num = 0,dimsizes(var_name_3D_time)-1
    print(var_name_3D_time(var_num))
    do time = 0, 11
       res@tiMainString = var_name_3D_time(var_num)+ " time " + time
       finout->$var_name_3D_time(var_num)$(level,:,:) = where( mask_out .eq. 1. ,\
              -9999.,\
              finout->$var_name_3D_time(var_num)$(level,:,:) )
       plot = gsn_csm_contour(wks, finout->$var_name_3D_time(var_num)$(level,:,:), res)
    end do
    finout->$var_name_3D_time(var_num)$@_FillValue = -9999.
end do

; ----------- 4D -----------
do var_num = 0,dimsizes(var_name_4D)-1
    print(var_name_4D(var_num))
    do time = 0, 11
      do level = 0, 5
         res@tiMainString = var_name_4D(var_num)+" time "+time+" level " + level
         finout->$var_name_4D(var_num)$(time,level,:,:) = where( mask_out .eq. 1. ,\
                -9999.,\
                finout->$var_name_4D(var_num)$(time,level,:,:) )
         plot = gsn_csm_contour(wks, finout->$var_name_4D(var_num)$(time,level,:,:), res)
      end do
    end do
    finout->$var_name_4D(var_num)$@_FillValue = -9999.
end do

; _______________________ Forming mask nc data ____________________________
system("/bin/rm -f " + fname_mask)    ; remove if exists
fmask  = addfile (fname_mask, "c")     ; open output file

; explicitly declare file definition mode. Improve efficiency.
setfileoption(fmask,"DefineMode",True)

; create global attributes of the file
fAtt               = True            ; assign file attributes
fAtt@title         = "Australia landmask for " + fname_inout
fAtt@source_file   = fname_inout
fAtt@Conventions   = "None"
fAtt@creation_date = systemfunc ("date")
fileattdef( fmask, fAtt )            ; copy file attributes

nlat   = 681
nlon   = 841

dimNames = (/ "latitude", "longitude" /)
dimSizes = (/ nlat , nlon  /)
dimUnlim = (/ False, False /)
filedimdef(fmask,dimNames,dimSizes,dimUnlim)

; predefine the the dimensionality of the variables to be written out
print("Predefine")

filevardef(fmask, "landsea",typeof(finout->landsea),getvardims(finout->landsea))
filevardef(fmask, "latitude",typeof(finout->latitude),getvardims(finout->latitude))
filevardef(fmask, "longitude",typeof(finout->longitude),getvardims(finout->longitude))
printVarSummary(fmask->landsea)

print("Copy attributes")
filevarattdef(fmask,"landsea",finout->landsea)
filevarattdef(fmask,"latitude",finout->latitude)
filevarattdef(fmask,"longitude",finout->longitude)
setfileoption(fmask,"DefineMode",False)
print("Exit DefineMode")

fmask->landsea   = finout->landsea
fmask->latitude  = finout->latitude
fmask->longitude = finout->longitude

res@gsnAddCyclic       = False
plot = gsn_csm_contour(wks,fmask->landsea,res)


end
