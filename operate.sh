#!/bin/bash

cd /srv/ccrc/data25/z5218916/script/Surface_forcing_high-res
nohup ncl form_gridinfo_AWAP_first-step.ncl
nohup ncl form_gridinfo_AWAP_second-step.ncl
nohup ncl form_gridinfo_AWAP_third-step.ncl
