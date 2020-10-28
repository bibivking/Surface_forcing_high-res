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

; _________________ option __________________
soil_data_type = 4 ; 0: CSIRO, 1: OpenLandMap 2: Old AWAP grid 3: Martin's SE AU

; ________________ file name ________________
if soil_data_type .eq. 0 then
    fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_CSIRO_AU_NAT.nc"
    finout  = addfile (fname_inout, "r")     ; open output file
    pic = "check_value_CSIRO"
    level_class = (/"000-005","005-015","015-030","030-060","060-100","100-200"/)
    file_end_name = "AU_NAT_C.nc"
else if soil_data_type .eq. 1 then
    fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_OpenLandMap.nc"
    finout  = addfile (fname_inout, "r")     ; open output file
    pic = "check_value_OpenLandMap"
    level_class = (/"0cm","10cm","30cm","60cm","100cm","200cm"/)
    file_end_name = "OpenLandMap.nc"
else if soil_data_type .eq. 2 then
    fname_inout  = "/srv/ccrc/data25/z5218916/script/surface_data_for_AWAP/nc_files/MD_elev_orig_std_avg-sand_AWAP_AU_mask.nc"
    finout  = addfile (fname_inout, "r")     ; open output file
    pic = "check_value_old_AWAP_grid"
else if soil_data_type .eq. 3 then
    fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/SE_AU_AWAP_NVIS_iveg_openland_soil_gimms_lai_grid.nc"
    ;SE_AU_AWAP_NVIS_iveg_csiro_soil_coper_lai_grid.nc
    ;SE_AU_AWAP_NVIS_iveg_openland_soil_coper_lai_grid.nc
    ;SE_AU_AWAP_NVIS_iveg_csiro_soil_gimms_lai_grid.nc
    ;SE_AU_AWAP_NVIS_iveg_openland_soil_gimms_lai_grid.nc
    finout  = addfile (fname_inout, "r")     ; open output file
    ;fname_mask  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/SE_AUS_AWAP_OpenLand_soil_landmask.nc"
    fname_mask  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/gridinfo_AWAP_OpenLandMap.nc"
    fmask  = addfile (fname_mask, "r")     ; open output file
    pic = "check_value_Martin_SE_AU"
else if soil_data_type .eq. 4 then
      fname_inout  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/cable_out_2001.nc"
      finout  = addfile (fname_inout, "r")     ; open output file
      pic = "check_value_output"
end if
end if
end if
end if
end if


;fname_LAI  = "/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/lai_climatology_AWAP_grid.nc" ; Gimms
fname_LAI  = "/srv/ccrc/data04/z3509830/Fluxnet_data/All_flux_sites_processed/Copernicus_LAI_time_series/Aus/monthly_climatology.nc" ; Anna's Copernicus
fLAI       = addfile(fname_LAI, "r")

; _________________________ Check Value ____________________________
wks = gsn_open_wks("pdf",pic)
gsn_define_colormap(wks,"WhiteBlueGreenYellowRed")
res            = True
res@cnFillMode = "RasterFill"            ; Raster Mode
res@cnFillOn   = True
res@cnLinesOn  = False
res@cnExplicitLabelBarLabelsOn = True   ;?
res@cnLevelSelectionMode = "ExplicitLevels"
;

; ==================== LAI Compare ====================
;print("a")
;res@tiMainString = "LAI"
;plot = gsn_csm_contour(wks, fLAI->LAI(0,:,:),res)
;plot = gsn_csm_contour(wks,finout->LAI(0,:,:),res)
;print("b")

; ==================== Metadata ====================
;var_name_meta = (/"Sand","Clay","Silt","Organic_C"/)

;;file_name  = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/Bulk_density_"+level_class(level)+"_AU_NAT_C.nc", "r")
;do var_num = 0,dimsizes(var_name_meta)-1
;  do level = 0,5
;    file_name = addfile("/srv/ccrc/data25/z5218916/script/Surface_forcing_high-res/nc_file/" \
;                + var_name_meta(var_num) + "_" + level_class(level) + "_" + file_end_name, "r")
;    res@tiMainString = "Metadata :"+ var_name_meta(var_num)+" "+level
;    res@cnLevels = fspan(0.,1.,11)
;    plot = gsn_csm_contour(wks, file_name->$var_name_meta(var_num)$/100.,res)
;  end do
;end do

; ; ==================== Grid File ====================
; var_name =(/ "rhosoil_vec", "sand_vec", "clay_vec", "silt_vec", "org_vec", "bch_vec",\
;              "sucs_vec", "ssat_vec", "sfc_vec", "swilt_vec", "css_vec", "cnsd_vec", \
;              "hyds_vec", "watr", "patchfrac", "SnowDepth" /)
;             ;(/ "sand_vec", "clay_vec", "silt_vec", "org_vec" /)
;
; do var_num = 0,dimsizes(var_name)-1
;   printVarSummary(finout->$var_name(var_num)$)
;   print(min(finout->$var_name(var_num)$))
;   print(max(finout->$var_name(var_num)$))
;   res@cnLevels = fspan(0.,1.,11)
;   do level = 0,5
;     res@tiMainString = var_name(var_num) +" "+ level
;     plot = gsn_csm_contour(wks,finout->$var_name(var_num)$(level,:,:),res)
;     ;plot = gsn_csm_contour(wks,fold->$var_name(var_num)$(level,:,:),res)
;   end do
; end do
; delete(res@cnLevels)
;
; res@cnLevels = (/-0.01,-0.001,0.,0.001,0.01/)
; do level = 0,5
;   res@tiMainString = "sand+clay+silt - 1. in level "+level
;   plot = gsn_csm_contour(wks, (finout->sand_vec(level,:,:) + finout->clay_vec(level,:,:)\
;          + finout->silt_vec(level,:,:)) -1.,res)
;   ;plot = gsn_csm_contour(wks, (fold->sand_vec(level,:,:) + fold->clay_vec(level,:,:)\
;   ;       + fold->silt_vec(level,:,:)) -1.,res)
; end do
; delete(res@cnLevels)
; ----------------- 2D --------------------

var_name_2D = (/"rhosoil", "sand", "clay", "silt", "bch",\
                "sucs", "ssat", "sfc", "swilt", "css", "hyds", "isoil",\
                "iveg"\
              /)

            ; (/ "rhosoil", "sand", "clay", "silt", "organic", "bch",\
            ;  "sucs", "ssat", "sfc", "swilt", "css", "cnsd", "hyds", "isoil",\
            ;  "iveg", "landsea", "soil_color", "Albedo", "albedo2",   \
            ;  "Sy", "dtb", "drainage_density", "slope", "slope_std",  \
            ;  "elevation", "elevation_std", "permeability"             /)

do var_num = 0,dimsizes(var_name_2D)-1
  print(var_name_2D(var_num))
  res@tiMainString = var_name_2D(var_num)
  ;res@cnLevels = fspan(0.,1.,11)
  plot = gsn_csm_contour(wks,finout->$var_name_2D(var_num)$,res)
end do

;delete(res@cnLevels)

plot = gsn_csm_contour(wks,finout->Qle(0,:,:),res)
plot = gsn_csm_contour(wks,finout->Qh(0,:,:),res)
plot = gsn_csm_contour(wks,finout->Qs(0,:,:),res)


; res@cnLevels = (/-0.01,-0.001,0.,0.001,0.01/)
; res@tiMainString = "sand+clay+silt - 1."
; plot = gsn_csm_contour(wks, (finout->sand + finout->clay + finout->silt) -1.,res)
; ;plot = gsn_csm_contour(wks, (fold->sand + fold->clay + fold->silt) -1.,res)
; ;print((finout->sand + finout->clay + finout->silt) -1.)
; delete(res@cnLevels)


; ;print(finout->landsea(320,827))
; ;print(finout->landsea(319,811))
; nml_4D = "SoilMoist";"SoilTemp" ;(/"SoilMoist","SoilTemp"/)
;
; do var_num = 0,dimsizes(nml_4D)-1
;   do time = 0,11
;     do level = 0,5
;       ;print(nml_4D(var_num)+" time "+time+" level "+level)
;       ;print(finout->$nml_4D(var_num)$(time,level,320,827)*1.0)
;       ;print(finout->$nml_4D(var_num)$(time,level,319,811)*1.0)
;       res@tiMainString = nml_4D(var_num)+" time "+time+" level "+level
;       ;plot = gsn_csm_contour(wks,finout->$nml_4D(var_num)$(time,level,:,:)*1.-fmask->$nml_4D(var_num)$(time,level,:,:)*1.,res)
;       res@cnLevels = fspan(-1.,1.,21)
;       plot = gsn_csm_contour(wks,finout->$nml_4D(var_num)$(time,level,:,:)*1.,res)
;       plot = gsn_csm_contour(wks,fmask->$nml_4D(var_num)$(time,level,:,:)*1.,res)
;       print(fmask->SoilMoist@_FillValue)
;       print(finout->SoilMoist@_FillValue)
;       ;tmp  = where( fmask->landsea(:,:) .eq. 0. .and. ismissing(finout->$nml_4D(var_num)$(time,level,:,:)) , -1000., 1.)
;       ;plot = gsn_csm_contour(wks,tmp,res)
;     end do
;   end do
; end do

end
