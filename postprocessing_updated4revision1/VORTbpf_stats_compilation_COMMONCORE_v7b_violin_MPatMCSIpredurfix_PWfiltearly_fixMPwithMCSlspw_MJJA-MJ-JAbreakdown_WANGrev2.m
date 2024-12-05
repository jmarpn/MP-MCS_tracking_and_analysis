
%%% v5 - renames "SYN", "PSI", etc.  ->  "MP" 
% v5b  -   adds era5 CAPE & VIWVC processing (not yet images, just processing of arrays up to that point).
% v5c  -   adds large scale synoptic feature tracks and filters on MCS population
% v5cc - v5c seems to have been somewhat corrupted. I found a weird maybe-backup of v5c that I am using to recover in this version. 
        % this version NaNs-out MCSstats and MPstats vars if LP is present in a few ways (see code below). 
        % I'm still pondering if I should be deleting (not just nan'ing out) MCs with all NaNs in their MCSstats vars? 
        % I think it's ok to just nan rather than delete, but I should double check this (really, there are a lot of MCS/MP records that are all nans because
        % of the pad-with-Nans strategy to have uniform array sizes over all years. so as long as you do a check for all nans per time in some
        % way and dont count the MP = NAN MCSs in the total MCS population, you should be good - accomplishable with the MP = -1 vs > 0 vs NaN values). 
        %... after some reinvestigation of what past Jim did, I went back into the preceeding track-pairing matlab code and NaN'ed out in MCSstats and MPstats vars 
        %for objects outside of the CONUS sud-dom box. I also now pass in MASK_KEEPERS/TOSSERS_MCS/MP vars to keep track of these in/out of sub-dom box.  

%v5d:  removes environemntal CAPE,VIWVD,PW, which I will do offline in a Zhe python code.    
%  v6    adds environemtnal data from Zhe's MP code
%v6b: adds in filter mask to ditch MPs/MCSs where an Mp-MCSI interaction happens with MPs initiating < 3 hours prior to MCSI

%v6c:   "fix" holefill the LStracks_perMCS_ALLYRS and MPtracks_perMCS_ALLYRS that have stray NaNs in the frst 1-3 times of MCS lifecycle by backward 
%v6d:  copy/pasted all MP/nonMP/LS histogram statements from ...COMMONCORE_v6bviolins.m [2219-11652] to same part of this code for
%      purposes of running along side violin_MCS_metrics.m. Note, you
%      didn't go metric per metric when you copied over, you just mass
%      copy/pasted, so if you changed things between v6b and v6d, you might
%      have to those fix things. 

% MJJA-MJ-JA monthly breakdown: look for "keepmonths" array to prescribe
% what months worth of MPs/MCSs that you want to isolate for analysis.
% the filtering happens circa line 800-100(ish), so I think most/all
% subsequent analyses should be subject to your prescribed kept months

%v7b: just making this the vnumber to be consistent with updated
%preprocssing dataset

clear all

filteroutLS = 1;   %set this to one if you want the final processed MP/MCS stats to exclude those in LSs. 
                   %It will also save a version of the stats for events that do have LSs, but by default, they aren't analyzed by
       

%rootdir = '/Volumes/LaCie/WACCEM/datafiles/Bandpass/png/vor_bpf_sm7pt/dom200-300_20-60_vorttrhesh2e-5/';
rootdir = '/Volumes/LaCie/WACCEM/datafiles/Bandpass/';
% rootdir = '/Volumes/Orange/WACCEM/datafiles/test/';
% rootdir = '/Users/marq789/Downloads/vort_files/';

mkdir(   strcat(rootdir,'/images')  )
imout = strcat(rootdir,'/images');

%just grab a random file for reference
MCSstatfile = '/Volumes/LaCie/WACCEM/datafiles/MCStracks/CONUS/MCS_track_stats/mcs_tracks_final_20040101.0000_20050101.0000.nc' ;
%MCSstatfile = '/Volumes/Orange/WACCEM/datafiles/Bandpass/mcs_tracks_final_20040101.0000_20050101.0000.nc' ;

% ncdisp(MCSstatfile)
pixel_radius_km = ncreadatt(MCSstatfile,'/','pixel_radius_km');
clear MCSstatfile

YEARS  =   ['2004';
            '2005';
            '2006';
            '2007';
            '2008';
            '2009';
            '2010';
            '2011';
            '2012';
            '2013';
            '2014';
            '2015';
            '2016';
            '2017';
            '2018';
            '2019';
            '2020';
            '2021'];
        
[ay by] = size(YEARS); clear by

%%%%%%%%%%%%%%%%%%%%%%%
%%%% load MP env vars
%%%%%%%%%%%%%%%%%%%%%%%

% load('/Volumes/LaCie/WACCEM/datafiles/Bandpass//images/SemiprocessedEnvVars.mat', ...
%     'meanMUCAPE_MPstats_ALLYRS',...
%     'maxMUCAPE_MPstats_ALLYRS',...
%     'meanMUCIN_MPstats_ALLYRS',...
%     'minMUCIN_MPstats_ALLYRS',...
%     'meanMULFC_MPstats_ALLYRS',...
%     'meanMUEL_MPstats_ALLYRS',...
%     'meanPW_MPstats_ALLYRS',...
%     'maxPW_MPstats_ALLYRS',...
%     'minPW_MPstats_ALLYRS',...  
%     'meanshearmag0to2_MPstats_ALLYRS',...
%     'maxshearmag0to2_MPstats_ALLYRS',...
%     'meanshearmag0to6_MPstats_ALLYRS',...
%     'maxshearmag0to6_MPstats_ALLYRS',...
%     'meanshearmag2to9_MPstats_ALLYRS',...
%     'maxshearmag2to9_MPstats_ALLYRS',...
%     'meanOMEGA600_MPstats_ALLYRS',...
%     'minOMEGA600_MPstats_ALLYRS',...
%     'minOMEGAsub600_MPstats_ALLYRS',...
%     'meanVIWVD_MPstats_ALLYRS',...
%     'minVIWVD_MPstats_ALLYRS',...
%     'maxVIWVD_MPstats_ALLYRS',...
%     'meanDIV750_MPstats_ALLYRS',...
%     'minDIV750_MPstats_ALLYRS',...
%     'minDIVsub600_MPstats_ALLYRS',...
%     'meanWNDSPD600_MPstats_ALLYRS',...
%     'meanWNDDIR600_MPstats_ALLYRS');


MP_times = 800;
MP_tracks = 3200;
MP_years = ay;

LS_times = 800;
LS_tracks = 2000;  %may need to adjust this number up or down when you look at the total number of synoptic objects each year
LS_years = ay;

mcs_times = 300;
mcs_tracks = 500;
mcs_years = ay;

%MP
duration_MPstats_ALLYRS = zeros(MP_tracks,MP_years);
area_MPstats_ALLYRS = zeros(MP_times,MP_tracks,MP_years);
basetime_MPstats_ALLYRS = zeros(MP_times,MP_tracks,MP_years);
meanlat_MPstats_ALLYRS = zeros(MP_times,MP_tracks,MP_years);
meanlon_MPstats_ALLYRS = zeros(MP_times,MP_tracks,MP_years);
status_MPstats_ALLYRS = zeros(MP_times,MP_tracks,MP_years);
dAdt_MPstats_ALLYRS = zeros(MP_times,MP_tracks,MP_years);
MotionX_MPstats_ALLYRS = zeros(MP_times,MP_tracks,MP_years);
MotionY_MPstats_ALLYRS = zeros(MP_times,MP_tracks,MP_years);
maxVOR600_MPstats_ALLYRS = zeros(MP_times,MP_tracks,MP_years);
maxW600bpf_MPstats_ALLYRS = zeros(MP_times,MP_tracks,MP_years);
maxW600_MPstats_ALLYRS = zeros(MP_times,MP_tracks,MP_years);    
LStracks_perMP_ALLYRS = zeros(MP_times,MP_tracks,MP_years);
%MPenvs
meanMUCAPE_MPstats_ALLYRS          = zeros(MP_times,MP_tracks,MP_years);  
maxMUCAPE_MPstats_ALLYRS           = zeros(MP_times,MP_tracks,MP_years);  
meanMUCIN_MPstats_ALLYRS           = zeros(MP_times,MP_tracks,MP_years);  
minMUCIN_MPstats_ALLYRS            = zeros(MP_times,MP_tracks,MP_years);  
meanMULFC_MPstats_ALLYRS           = zeros(MP_times,MP_tracks,MP_years);  
meanMUEL_MPstats_ALLYRS            = zeros(MP_times,MP_tracks,MP_years);  
meanPW_MPstats_ALLYRS              = zeros(MP_times,MP_tracks,MP_years);  
maxPW_MPstats_ALLYRS               = zeros(MP_times,MP_tracks,MP_years);  
minPW_MPstats_ALLYRS               = zeros(MP_times,MP_tracks,MP_years);  
meanshearmag0to2_MPstats_ALLYRS    = zeros(MP_times,MP_tracks,MP_years);
maxshearmag0to2_MPstats_ALLYRS     = zeros(MP_times,MP_tracks,MP_years);
meanshearmag0to6_MPstats_ALLYRS    = zeros(MP_times,MP_tracks,MP_years);
maxshearmag0to6_MPstats_ALLYRS     = zeros(MP_times,MP_tracks,MP_years);
meanshearmag2to9_MPstats_ALLYRS    = zeros(MP_times,MP_tracks,MP_years);
maxshearmag2to9_MPstats_ALLYRS     = zeros(MP_times,MP_tracks,MP_years);
meanOMEGA600_MPstats_ALLYRS        = zeros(MP_times,MP_tracks,MP_years);
minOMEGA600_MPstats_ALLYRS         = zeros(MP_times,MP_tracks,MP_years);
minOMEGAsub600_MPstats_ALLYRS      = zeros(MP_times,MP_tracks,MP_years);
meanVIWVD_MPstats_ALLYRS           = zeros(MP_times,MP_tracks,MP_years);
minVIWVD_MPstats_ALLYRS            = zeros(MP_times,MP_tracks,MP_years);
maxVIWVD_MPstats_ALLYRS            = zeros(MP_times,MP_tracks,MP_years);
meanDIV750_MPstats_ALLYRS          = zeros(MP_times,MP_tracks,MP_years);
minDIV750_MPstats_ALLYRS           = zeros(MP_times,MP_tracks,MP_years);
minDIVsub600_MPstats_ALLYRS        = zeros(MP_times,MP_tracks,MP_years);
meanWNDSPD600_MPstats_ALLYRS       = zeros(MP_times,MP_tracks,MP_years);  
meanWNDDIR600_MPstats_ALLYRS       = zeros(MP_times,MP_tracks,MP_years);  


%LS
duration_LSstats_ALLYRS = zeros(LS_tracks,LS_years);
area_LSstats_ALLYRS = zeros(LS_times,LS_tracks,LS_years);
basetime_LSstats_ALLYRS = zeros(LS_times,LS_tracks,LS_years);
meanlat_LSstats_ALLYRS = zeros(LS_times,LS_tracks,LS_years);
meanlon_LSstats_ALLYRS = zeros(LS_times,LS_tracks,LS_years);
status_LSstats_ALLYRS = zeros(LS_times,LS_tracks,LS_years);
maxVOR600_LSstats_ALLYRS = zeros(LS_times,LS_tracks,LS_years);

%MCSs
duration_MCSstats_ALLYRS = zeros(mcs_tracks,mcs_years);
basetime_MCSstats_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);
status_MCSstats_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);
dAdt_MCSstats_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);
MotionX_MCSstats_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);
MotionY_MCSstats_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);
meanlat_MCSstats_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);
meanlon_MCSstats_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);
speed_MCSstats_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);
dirmotion_MCSstats_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);
MPtracks_perMCS_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);
LStracks_perMCS_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);
pflon_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);
pflat_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);
pfarea_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);
pfrainrate_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);
totalrain_MCSstats_ALLYRS           = zeros(mcs_times,mcs_tracks,mcs_years); 
totalheavyrain_MCSstats_ALLYRS      = zeros(mcs_times,mcs_tracks,mcs_years);

totalrain6HR_MCSstats_ALLYRS           = zeros(mcs_times,mcs_tracks,mcs_years); 
totalheavyrain6HR_MCSstats_ALLYRS      = zeros(mcs_times,mcs_tracks,mcs_years);

convrain_MCSstats_ALLYRS            = zeros(mcs_times,mcs_tracks,mcs_years); 
stratrain_MCSstats_ALLYRS           = zeros(mcs_times,mcs_tracks,mcs_years); 
rainrate_heavyrain_MCSstats_ALLYRS  = zeros(mcs_times,mcs_tracks,mcs_years); 
pf_maxrainrate_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years); 
pf_accumrain_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years); 
pf_accumrainheavy_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);

pf_convrate_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);
pf_stratrate_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);
pf_convarea_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);
pf_stratarea_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);
pf_ETH10_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);
pf_ETH30_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);
pf_ETH40_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);
pf_ETH45_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);
pf_ETH50_MCSstats_ALLYRS = zeros(5,mcs_times,mcs_tracks,mcs_years);

totalrainmass_MCSstats_ALLYRS = zeros(mcs_tracks,mcs_years); 
MCSspeed_MCSstats_ALLYRS = zeros(mcs_tracks,mcs_years); 
maxW600bpf_MCSstats_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years); 
maxW600_MCSstats_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);         
% meanPW_MCSstats_ALLYRS= zeros(mcs_times,mcs_tracks,mcs_years); 
% maxMUCAPE_MCSstats_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);
% maxVIWVConv_MCSstats_ALLYRS = zeros(mcs_times,mcs_tracks,mcs_years);
MASK_KEEPERS_MCS_ALLYRS  = zeros(mcs_tracks,mcs_years);
MASK_TOSSERS_MCS_ALLYRS  = zeros(mcs_tracks,mcs_years);


%MP
MCSI_with_MP_ALLYRS = zeros(mcs_tracks,mcs_years); 
MASK_KEEPERS_MP_ALLYRS  = zeros(MP_tracks,MP_years);
MASK_TOSSERS_MP_ALLYRS  = zeros(MP_tracks,MP_years);
%MASK_zone_ALLYRS = zeros(MP_tracks,MP_years);
MASK_no_merge_or_split_ALLYRS = zeros(MP_tracks,MP_years);
MASKS_ALL_ALLYRS = zeros(MP_tracks,MP_years);
MP_with_MCSs_ALLYRS = zeros(MP_tracks,MP_years);
%MP_with_MCSs_ALLYRS = zeros(mcs_tracks,mcs_years);  %why did I do this in MCS sizes? is that right?
MP_without_MCSs_ALLYRS = zeros(MP_tracks,MP_years);
MP_other_ALLYRS = zeros(MP_tracks,MP_years);
MP_no_merge_or_split_ALLYRS = zeros(mcs_tracks,mcs_years);
%MP_no_merge_or_split_ALLYRS = zeros(mcs_tracks,mcs_years); %why did I do this in MCS sizes? is that right?

%LS
MCSI_with_LS_ALLYRS = zeros(mcs_tracks,mcs_years);
MASK_KEEPERS_LS_ALLYRS  = zeros(LS_tracks,LS_years);
MASK_TOSSERS_LS_ALLYRS  = zeros(LS_tracks,LS_years);
%MASK_zone_LS_ALLYRS = zeros(LS_tracks,LS_years);
MASK_no_merge_or_split_LS_ALLYRS = zeros(LS_tracks,LS_years);
MASKS_ALL_LS_ALLYRS = zeros(LS_tracks,LS_years);
LS_with_MCSs_ALLYRS = zeros(LS_tracks,LS_years);
%LS_with_MCSs_ALLYRS = zeros(mcs_tracks,mcs_years);  %why did I do this in MCS sizes? is that right?
LS_without_MCSs_ALLYRS = zeros(LS_tracks,LS_years);
LS_other_ALLYRS = zeros(LS_tracks,LS_years);
LS_no_merge_or_split_ALLYRS = zeros(LS_tracks,LS_years);
LSs_with_MP_ALLYRS = zeros(LS_tracks,LS_years);
LSs_without_MP_ALLYRS = zeros(LS_tracks,LS_years);
%LS_no_merge_or_split_ALLYRS = zeros(mcs_tracks,mcs_years);  %why did I do this in MCS sizes? is that right?


%%%%%%%%%  Nan 'em:

%MPs
duration_MPstats_ALLYRS(:) = NaN;
area_MPstats_ALLYRS(:)  = NaN;
% basetime_MPstatsarea_ALLYRS(:)  = NaN;
basetime_MPstats_ALLYRS(:)  = NaN;
meanlat_MPstats_ALLYRS(:)  = NaN;
meanlon_MPstats_ALLYRS(:)  = NaN;
status_MPstats_ALLYRS(:)  = NaN;
basetime_MPstats_met_yymmddhhmmss_ALLYRS(:)  = NaN;
dAdt_MPstats_ALLYRS(:)  = NaN;
MotionX_MPstats_ALLYRS(:)  = NaN;
MotionY_MPstats_ALLYRS(:)  = NaN;
maxVOR600_MPstats_ALLYRS(:)  = NaN;
maxW600bpf_MPstats_ALLYRS(:) = NaN;
maxW600_MPstats_ALLYRS(:)= NaN;                 
LStracks_perMP_ALLYRS(:)= NaN;
%MPenvs
meanMUCAPE_MPstats_ALLYRS(:)= NaN;   
maxMUCAPE_MPstats_ALLYRS(:)= NaN;    
meanMUCIN_MPstats_ALLYRS(:)= NaN;    
minMUCIN_MPstats_ALLYRS(:)= NaN;  
meanMULFC_MPstats_ALLYRS(:)= NaN;   
meanMUEL_MPstats_ALLYRS(:)= NaN;   
meanPW_MPstats_ALLYRS(:)= NaN;   
maxPW_MPstats_ALLYRS(:)= NaN;   
minPW_MPstats_ALLYRS(:)= NaN;  
meanshearmag0to2_MPstats_ALLYRS(:)= NaN;  
maxshearmag0to2_MPstats_ALLYRS(:)= NaN;  
meanshearmag0to6_MPstats_ALLYRS(:)= NaN;  
maxshearmag0to6_MPstats_ALLYRS(:)= NaN;  
meanshearmag2to9_MPstats_ALLYRSs(:)= NaN;  
maxshearmag2to9_MPstats_ALLYRS(:)= NaN;  
meanOMEGA600_MPstats_ALLYRS(:)= NaN;  
minOMEGA600_MPstats_ALLYRS(:)= NaN;  
minOMEGAsub600_MPstats_ALLYRS(:)= NaN;  
meanVIWVD_MPstats_ALLYRS(:)= NaN;  
minVIWVD_MPstats_ALLYRS(:)= NaN;  
maxVIWVD_MPstats_ALLYRS(:)= NaN;  
meanDIV750_MPstats_ALLYRS(:)= NaN;  
minDIV750_MPstats_ALLYRS(:)= NaN;  
minDIVsub600_MPstats_ALLYRS(:)= NaN;  
meanWNDSPD600_MPstats_ALLYRS(:)= NaN;    
meanWNDDIR600_MPstats_ALLYRS(:)= NaN;  



%LSs
duration_LSstats_ALLYRS(:)  = NaN; 
area_LSstats_ALLYRS(:)      = NaN; 
basetime_LSstats_ALLYRS(:)  = NaN; 
meanlat_LSstats_ALLYRS(:)   = NaN; 
meanlon_LSstats_ALLYRS(:)   = NaN; 
status_LSstats_ALLYRS(:)    = NaN; 
maxVOR600_LSstats_ALLYRS(:) = NaN; 

duration_MCSstats_ALLYRS(:)  = NaN;
basetime_MCSstats_ALLYRS(:)  = NaN;
status_MCSstats_ALLYRS(:)  = NaN;
%basetime_MCSstats_met_yymmddhhmmss_ALLYRS(:)  = NaN;
dAdt_MCSstats_ALLYRS(:)  = NaN;
MotionX_MCSstats_ALLYRS(:)  = NaN;
MotionY_MCSstats_ALLYRS(:)  = NaN;
meanlat_MCSstats_ALLYRS(:)  = NaN;
meanlon_MCSstats_ALLYRS(:)  = NaN;
speed_MCSstats_ALLYRS(:)  = NaN;
dirmotion_MCSstats_ALLYRS(:)  = NaN;
MPtracks_perMCS_ALLYRS(:)  = NaN;
pflon_MCSstats_ALLYRS(:)  = NaN;
pflat_MCSstats_ALLYRS(:)  = NaN;
pfarea_MCSstats_ALLYRS(:)  = NaN;
pfrainrate_MCSstats_ALLYRS(:)  = NaN;
pf_ETH10_MCSstats_ALLYRS(:)  = NaN;
pf_ETH30_MCSstats_ALLYRS(:)  = NaN;
pf_ETH40_MCSstats_ALLYRS(:)  = NaN;
pf_ETH45_MCSstats_ALLYRS(:)  = NaN;
pf_ETH50_MCSstats_ALLYRS(:)  = NaN;

totalrain_MCSstats_ALLYRS(:)  = NaN;
totalheavyrain_MCSstats_ALLYRS(:)  = NaN;
convrain_MCSstats_ALLYRS(:)  = NaN;
stratrain_MCSstats_ALLYRS(:)  = NaN;
pf_maxrainrate_MCSstats_ALLYRS(:)  = NaN;

totalrain6HR_MCSstats_ALLYRS(:)  = NaN;
totalheavyrain6HR_MCSstats_ALLYRS(:)  = NaN;

pf_convrate_MCSstats_ALLYRS(:)  = NaN;
pf_stratrate_MCSstats_ALLYRS(:)  = NaN;
pf_convarea_MCSstats_ALLYRS(:)  = NaN;
pf_stratarea_MCSstats_ALLYRS(:)  = NaN;

pf_accumrain_MCSstats_ALLYRS(:)  = NaN;
pf_accumrainheavy_MCSstats_ALLYRS(:)  = NaN; 
rainrate_heavyrain_MCSstats_ALLYRS(:)  = NaN;
MCSspeed_MCSstats_ALLYRS(:) = NaN;
MCSI_with_MP_ALLYRS(:) = NaN;
maxW600bpf_MCSstats_ALLYRS(:) = NaN;
maxW600_MCSstats_ALLYRS(:)= NaN;                 
% meanPW_MCSstats_ALLYRS(:)= NaN;   
% maxMUCAPE_MCSstats_ALLYRS(:)= NaN;   
% maxVIWVConv_MCSstats_ALLYRS(:)= NaN;   


MASK_KEEPERS_MP_ALLYRS(:)  = NaN;
MASK_TOSSERS_MP_ALLYRS(:)  = NaN;
%MASK_zone_ALLYRS(:)  = NaN;
MASK_no_merge_or_split_ALLYRS(:)  = NaN;
MASKS_ALL_ALLYRS(:)  = NaN;
MP_with_MCSs_ALLYRS(:)  = NaN;
MP_without_MCSs_ALLYRS(:)  = NaN;
MP_other_ALLYRS(:)  = NaN;
MP_no_merge_or_split_ALLYRS(:)  = NaN;

LSs_with_MP_ALLYRS(:)  = NaN;
LSs_without_MP_ALLYRS(:)  = NaN;
LS_with_MCSs_ALLYRS(:)  = NaN;
LS_without_MCSs_ALLYRS(:)  = NaN;
LStracks_perMCS_ALLYRS(:)  = NaN;

MASK_KEEPERS_MCS_ALLYRS(:)  = NaN;
MASK_TOSSERS_MCS_ALLYRS(:)  = NaN;


for yr = 1 : ay
    
    %  yr = 3 ;   %vorstats_masks_zone_v5b_justmatchupandW.mat
    

    %matout =  strcat(rootdir,'/matlab/',YEARS(yr,:),'_vorstats_masks_zone_v7b_MatchupEnvs_objoverlap0.001percent.mat')   ;
    matout =  strcat(rootdir,'/matlab/',YEARS(yr,:),'_vorstats_masks_zone_v7_rev2wangclone_MatchupEnvs_objoverlap0.001percent.mat')   ;


    load(matout,'duration_MPstats','area_MPstats','basetime_MPstats','meanlat_MPstats','meanlon_MPstats','status_MPstats',...
        'dAdt_MPstats','MPtracks_perMCS','maxVOR600_MPstats',...
        'duration_MCSstats','basetime_MCSstats','status_MCSstats','pflon_MCSstats','pflat_MCSstats','pfarea_MCSstats', ...
        'dAdt_MCSstats','pfrainrate_MCSstats','speed_MCSstats','dirmotion_MCSstats',...
        'MASK_KEEPERS_MP','MASK_TOSSERS_MP','MASK_no_merge_or_split','MASKS_ALL',...
        'MP_with_MCSs','MP_without_MCSs','MP_other','MP_no_merge_or_split','meanlat_MCSstats','meanlon_MCSstats',...
        'totalrain_MCSstats','totalheavyrain_MCSstats','convrain_MCSstats','stratrain_MCSstats','pf_maxrainrate_MCSstats',...
        'pf_convrate_MCSstats', 'pf_stratrate_MCSstats', 'pf_convarea_MCSstats', 'pf_stratarea_MCSstats', ... 
        'pf_accumrain_MCSstats','pf_accumrainheavy_MCSstats','rainrate_heavyrain_MCSstats',...
        'maxW600bpf_MPstats', 'maxW600_MPstats','maxW600bpf_MCSstats','maxW600_MCSstats',...
        'MASK_KEEPERS_MCS','MASK_TOSSERS_MCS',...
        'duration_LSstats','area_LSstats','basetime_LSstats','meanlat_LSstats','meanlon_LSstats','status_LSstats','basetime_LSstats_met_yymmddhhmmss', 'maxVOR600_LSstats', ...
        'MASK_KEEPERS_LS','MASK_TOSSERS_LS','LStracks_perMCS','LS_with_MCSs','LS_without_MCSs','LSmasks_masked','LSmasks_masked_withmcs',...
        'LStracks_perMP','LSs_with_MP','LSs_without_MP','MotionX_MPstats','MotionY_MPstats', 'MotionX_MCSstats','MotionY_MCSstats',...
        'pfETH10_MCSstats', 'pfETH30_MCSstats', 'pfETH40_MCSstats', 'pfETH45_MCSstats', 'pfETH50_MCSstats',...
        'meanMUCAPE_MPstats', 'maxMUCAPE_MPstats', 'meanMUCIN_MPstats', 'minMUCIN_MPstats', 'meanMULFC_MPstats', 'meanMUEL_MPstats', ...
        'meanPW_MPstats', 'maxPW_MPstats', 'minPW_MPstats', 'meanshearmag0to2_MPstats', 'maxshearmag0to2_MPstats', ...
        'meanshearmag0to6_MPstats', 'maxshearmag0to6_MPstats', 'meanshearmag2to9_MPstats', 'maxshearmag2to9_MPstats', ...
        'meanOMEGA600_MPstats',  'minOMEGA600_MPstats', 'minOMEGAsub600_MPstats', 'meanVIWVD_MPstats', 'minVIWVD_MPstats', ...
        'maxVIWVD_MPstats', 'meanDIV750_MPstats', 'minDIV750_MPstats','minDIVsub600_MPstats', 'meanWNDSPD600', 'meanWNDDIR600' )


   
    % get sizes
    [stimes,stracks] = size(basetime_MPstats) ;
    [ltimes,ltracks] = size(basetime_LSstats) ;
    [mtimes,mtracks] = size(basetime_MCSstats) ;
    [p1,mtimes,mtracks] = size(pflat_MCSstats) ;
    
    %populate MP arrays
    duration_MPstats_ALLYRS(1:stracks,yr)                           = duration_MPstats;
    area_MPstats_ALLYRS(1:stimes,1:stracks,yr)                      = area_MPstats;
    basetime_MPstats_ALLYRS(1:stimes,1:stracks,yr)                  = basetime_MPstats;
    meanlat_MPstats_ALLYRS(1:stimes,1:stracks,yr)                   = meanlat_MPstats;
    meanlon_MPstats_ALLYRS(1:stimes,1:stracks,yr)                   = meanlon_MPstats;
    status_MPstats_ALLYRS(1:stimes,1:stracks,yr)                    = status_MPstats;
    dAdt_MPstats_ALLYRS(1:stimes,1:stracks,yr)                      = dAdt_MPstats;
    MotionX_MPstats_ALLYRS(1:stimes,1:stracks,yr)                   = MotionX_MPstats;
    MotionY_MPstats_ALLYRS(1:stimes,1:stracks,yr)                   = MotionY_MPstats;
    maxVOR600_MPstats_ALLYRS(1:stimes,1:stracks,yr)                 = maxVOR600_MPstats; 
    maxW600bpf_MPstats_ALLYRS(1:stimes,1:stracks,yr)                = maxW600bpf_MPstats;
    maxW600_MPstats_ALLYRS(1:stimes,1:stracks,yr)                   = maxW600_MPstats;
    LStracks_perMP_ALLYRS(1:stimes,1:stracks,yr)                    = LStracks_perMP;
    %MPenvs
    meanMUCAPE_MPstats_ALLYRS(1:stimes,1:stracks,yr)            =  meanMUCAPE_MPstats;
    maxMUCAPE_MPstats_ALLYRS(1:stimes,1:stracks,yr)             =  maxMUCAPE_MPstats;
    meanMUCIN_MPstats_ALLYRS(1:stimes,1:stracks,yr)             =  meanMUCIN_MPstats;
    minMUCIN_MPstats_ALLYRS(1:stimes,1:stracks,yr)              =  minMUCIN_MPstats;
    meanMULFC_MPstats_ALLYRS(1:stimes,1:stracks,yr)             =  meanMULFC_MPstats;
    meanMUEL_MPstats_ALLYRS(1:stimes,1:stracks,yr)              =  meanMUEL_MPstats;
    meanPW_MPstats_ALLYRS(1:stimes,1:stracks,yr)                =  meanPW_MPstats;
    maxPW_MPstats_ALLYRS(1:stimes,1:stracks,yr)                 =  maxPW_MPstats;
    minPW_MPstats_ALLYRS(1:stimes,1:stracks,yr)                 =  minPW_MPstats;
    meanshearmag0to2_MPstats_ALLYRS(1:stimes,1:stracks,yr)      =  meanshearmag0to2_MPstats;
    maxshearmag0to2_MPstats_ALLYRS(1:stimes,1:stracks,yr)       =  maxshearmag0to2_MPstats;
    meanshearmag0to6_MPstats_ALLYRS(1:stimes,1:stracks,yr)      =  meanshearmag0to6_MPstats;
    maxshearmag0to6_MPstats_ALLYRS(1:stimes,1:stracks,yr)       =  maxshearmag0to6_MPstats;
    meanshearmag2to9_MPstats_ALLYRS(1:stimes,1:stracks,yr)      =  meanshearmag2to9_MPstats;
    maxshearmag2to9_MPstats_ALLYRS(1:stimes,1:stracks,yr)       =  maxshearmag2to9_MPstats;
    meanOMEGA600_MPstats_ALLYRS(1:stimes,1:stracks,yr)          =  meanOMEGA600_MPstats;
    minOMEGA600_MPstats_ALLYRS(1:stimes,1:stracks,yr)           =  minOMEGA600_MPstats;
    minOMEGAsub600_MPstats_ALLYRS(1:stimes,1:stracks,yr)        =  minOMEGAsub600_MPstats;
    meanVIWVD_MPstats_ALLYRS(1:stimes,1:stracks,yr)             =  meanVIWVD_MPstats;
    minVIWVD_MPstats_ALLYRS(1:stimes,1:stracks,yr)              =  minVIWVD_MPstats;
    maxVIWVD_MPstats_ALLYRS(1:stimes,1:stracks,yr)              =  maxVIWVD_MPstats;
    meanDIV750_MPstats_ALLYRS(1:stimes,1:stracks,yr)            =  meanDIV750_MPstats;
    minDIV750_MPstats_ALLYRS(1:stimes,1:stracks,yr)             =  minDIV750_MPstats;
    minDIVsub600_MPstats_ALLYRS(1:stimes,1:stracks,yr)          =  minDIVsub600_MPstats;
    meanWNDSPD600_MPstats_ALLYRS(1:stimes,1:stracks,yr)         =  meanWNDSPD600 ;
    meanWNDDIR600_MPstats_ALLYRS(1:stimes,1:stracks,yr)         =  meanWNDDIR600 ;


    %populate LS arrays
    duration_LSstats_ALLYRS(1:ltracks,yr)                           = duration_LSstats;
    area_LSstats_ALLYRS(1:ltimes,1:ltracks,yr)                      = area_LSstats;
    basetime_LSstats_ALLYRS(1:ltimes,1:ltracks,yr)                  = basetime_LSstats;
    meanlat_LSstats_ALLYRS(1:ltimes,1:ltracks,yr)                   = meanlat_LSstats;
    meanlon_LSstats_ALLYRS(1:ltimes,1:ltracks,yr)                   = meanlon_LSstats;
    status_LSstats_ALLYRS(1:ltimes,1:ltracks,yr)                    = status_LSstats;
    maxVOR600_LSstats_ALLYRS(1:ltimes,1:ltracks,yr)                 = maxVOR600_LSstats; 

    %populate MCS arrays
    duration_MCSstats_ALLYRS(1:mtracks,yr)                           = duration_MCSstats;
    basetime_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                  = basetime_MCSstats;
    status_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                    = status_MCSstats;
    dAdt_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                      = dAdt_MCSstats;
    MotionX_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                   = MotionX_MCSstats;
    MotionY_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                   = MotionY_MCSstats;
    meanlat_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                   = meanlat_MCSstats;
    meanlon_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                   = meanlon_MCSstats;
    speed_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                     = speed_MCSstats;
    dirmotion_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                 = dirmotion_MCSstats;
    pflon_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)                = pflon_MCSstats;
    pflat_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)                = pflat_MCSstats;
    pfarea_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)               = pfarea_MCSstats;
    pfrainrate_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)           = pfrainrate_MCSstats;
    MPtracks_perMCS_ALLYRS(1:mtimes,1:mtracks,yr)                    = MPtracks_perMCS; 
    LStracks_perMCS_ALLYRS(1:mtimes,1:mtracks,yr)                    = LStracks_perMCS;
    totalrain_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                 = totalrain_MCSstats;
    totalheavyrain_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)            = totalheavyrain_MCSstats ;
    convrain_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                  = convrain_MCSstats ;
    stratrain_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                 = stratrain_MCSstats ;
    pf_maxrainrate_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)       = pf_maxrainrate_MCSstats ;
    pf_accumrain_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)         = pf_accumrain_MCSstats ;
    pf_accumrainheavy_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)    = pf_accumrainheavy_MCSstats ;

    pf_convrate_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)          = pf_convrate_MCSstats;
    pf_stratrate_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)         = pf_stratrate_MCSstats;
    pf_convarea_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)          = pf_convarea_MCSstats;
    pf_stratarea_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)         = pf_stratarea_MCSstats;  
    pf_ETH10_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)             = pfETH10_MCSstats;
    pf_ETH30_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)             = pfETH30_MCSstats;
    pf_ETH40_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)             = pfETH40_MCSstats;
    pf_ETH45_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)             = pfETH45_MCSstats;
    pf_ETH50_MCSstats_ALLYRS(1:p1,1:mtimes,1:mtracks,yr)             = pfETH50_MCSstats; 

    rainrate_heavyrain_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)        = rainrate_heavyrain_MCSstats ;
    maxW600bpf_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                = maxW600bpf_MCSstats;
    maxW600_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                   = maxW600_MCSstats;
%     meanPW_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                    = meanPW_MCSstats;
%     maxMUCAPE_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)                 = maxMUCAPE_MCSstats;   
%     maxVIWVConv_MCSstats_ALLYRS(1:mtimes,1:mtracks,yr)               = maxVIWVConv_MCSstats;  
    MASK_KEEPERS_MCS_ALLYRS(1:length(MASK_KEEPERS_MCS),yr)           = MASK_KEEPERS_MCS;   
    MASK_TOSSERS_MCS_ALLYRS(1:length(MASK_TOSSERS_MCS),yr)           = MASK_TOSSERS_MCS;

    %populate MP masks
    MASK_KEEPERS_MP_ALLYRS(1:length(MASK_KEEPERS_MP),yr)                 = MASK_KEEPERS_MP;
    MASK_TOSSERS_MP_ALLYRS(1:length(MASK_TOSSERS_MP),yr)                 = MASK_TOSSERS_MP;
    %MASK_zone_ALLYRS(1:length(MASK_zone'),yr)                            = MASK_zone';
    MASK_no_merge_or_split_ALLYRS(1:length(MASK_no_merge_or_split'),yr)  = MASK_no_merge_or_split';
    MASKS_ALL_ALLYRS(1:length(MASKS_ALL),yr)                             = MASKS_ALL;
    MP_with_MCSs_ALLYRS(1:length(MP_with_MCSs),yr)                       = MP_with_MCSs;
    MP_without_MCSs_ALLYRS(1:length(MP_without_MCSs),yr)                 = MP_without_MCSs;
    MP_other_ALLYRS(1:length(MP_other'),yr)                              = MP_other';
    MP_no_merge_or_split_ALLYRS(1:length(MP_no_merge_or_split'),yr)      = MP_no_merge_or_split';
    % psimasks_masked_withmcs_ALLYRS(1:length(psimasks_masked_withmcs),yr) = psimasks_masked_withmcs;
    % psimasks_masked_ALLYRS(1:length(psimasks_masked),yr)                 = psimasks_masked;
    
    %populate LS masks
    MASK_KEEPERS_LS_ALLYRS(1:length(MASK_KEEPERS_LS),yr)                 = MASK_KEEPERS_LS;
    MASK_TOSSERS_LS_ALLYRS(1:length(MASK_TOSSERS_LS),yr)                 = MASK_TOSSERS_LS;
    %MASK_zone_ALLYRS(1:length(MASK_zone'),yr)                            = MASK_zone';
    %MASK_no_merge_or_split_ALLYRS(1:length(MASK_no_merge_or_split'),yr)  = MASK_no_merge_or_split';
    %MASKS_ALL_ALLYRS(1:length(MASKS_ALL),yr)                             = MASKS_ALL;
    LS_with_MCSs_ALLYRS(1:length(LS_with_MCSs),yr)                       = LS_with_MCSs;
    LS_without_MCSs_ALLYRS(1:length(LS_without_MCSs),yr)                 = LS_without_MCSs;
    %LS_other_ALLYRS(1:length(LS_other'),yr)                              = LS_other';
    LSs_with_MP_ALLYRS(1:length(LSs_with_MP'),yr)                        = LSs_with_MP;
    %MP_no_merge_or_split_ALLYRS(1:length(LS_no_merge_or_split'),yr)      = LS_no_merge_or_split';
    LSs_without_MP_ALLYRS(1:length(LSs_without_MP'),yr)                        = LSs_without_MP;


    clear duration_MPstats  area_MPstats  basetime_MPstats  meanlat_MPstats  meanlon_MPstats  status_MPstats  basetime_MPstats_met_yymmddhhmmss  ...
        dAdt_MPstats  MPtracks_perMCS    maxVOR600_MPstats   ...
        duration_LSstats  area_LSstats  basetime_LSstats  meanlat_LSstats  meanlon_LSstats  status_LSstats  basetime_LSstats_met_yymmddhhmmss  maxVOR600_LSstats   ...
        duration_MCSstats  basetime_MCSstats  status_MCSstats  basetime_MCSstats_met_yymmddhhmmss  pflon_MCSstats  pflat_MCSstats  pfarea_MCSstats   ...
        dAdt_MCSstats  pfrainrate_MCSstats  speed_MCSstats  dirmotion_MCSstats  ...
        MASK_KEEPERS_MP  MASK_TOSSERS_MP  MASK_no_merge_or_split  MASKS_ALL ... %  psimasks_masked_withmcs  psimasks_masked  ...
        MP_with_MCSs  MP_without_MCSs  MP_other  MP_no_merge_or_split meanlat_MCSstats meanlon_MCSstats ...
        totalheavyrain_MCSstats convrain_MCSstats stratrain_MCSstats  pf_maxrainrate_MCSstats pf_accumrain_MCSstats pf_accumrainheavy_MCSstats rainrate_heavyrain_MCSstats...
        maxW600bpf_MCSstats maxW600_MCSstats meanPW_MCSstats maxW600bpf_MPstats maxW600_MPstats meanPW_MPstats MASK_KEEPERS_LS MASK_TOSSERS_LS LS_with_MCSs LS_without_MCSs LS_other LStracks_perMCS LStracks_perMP ...
        LSs_with_MP LSs_without_MP MASK_KEEPERS_MCS  MASK_TOSSERS_MCS  MotionX_MPstats  MotionY_MPstats MotionX_MCSstats  MotionY_MCSstats...  
        pf_convrate_MCSstats  pf_stratrate_MCSstats pf_convarea_MCSstats pf_stratarea_MCSstats...
        meanMUCAPE_MPstats maxMUCAPE_MPstats meanMUCIN_MPstats minMUCIN_MPstats meanMULFC_MPstats meanMUEL_MPstats...
        meanPW_MPstats maxPW_MPstats minPW_MPstats meanshearmag0to2_MPstats maxshearmag0to2_MPstats meanshearmag0to6_MPstats...
        maxshearmag0to6_MPstats meanshearmag2to9_MPstats maxshearmag2to9_MPstats meanOMEGA600_MPstats minOMEGA600_MPstats minOMEGAsub600_MPstats...
        meanVIWVD_MPstats minVIWVD_MPstats maxVIWVD_MPstats meanDIV750_MPstats minDIV750_MPstats minDIVsub600_MPstats meanWNDSPD600 meanWNDDIR600

end

basetime_MCSstats_met_yymmddhhmmss_ALLYRS = datetime(basetime_MCSstats_ALLYRS, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;
basetime_MPstats_met_yymmddhhmmss_ALLYRS = datetime(basetime_MPstats_ALLYRS, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;
basetime_LSstats_met_yymmddhhmmss_ALLYRS = datetime(basetime_LSstats_ALLYRS, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;


%running sum 
for t = 1 : mtimes
    tback = t-6;
    if(tback < 1)
        tback = 1;
    end
    totalrain6HR_MCSstats_ALLYRS(t,:,:)           =  sum(    totalrain_MCSstats_ALLYRS(tback:t, :, :),1          )  ;
    totalheavyrain6HR_MCSstats_ALLYRS(t,:,:)      =  sum(    totalheavyrain_MCSstats_ALLYRS(tback:t, :, :),1     )  ;
end

% blah = sum(pf_accumrain_MCSstats_ALLYRS,1,'omitnan');   
% blah = permute(blah,[2 3 4 1]);  blahtest = blah(:,:,1); 
% blah2test = totalrain_MCSstats_ALLYRS(:,:,1);

% TEST = totalrain_MCSstats_ALLYRS(:,100,1);
% TEST6 = totalrain6HR_MCSstats_ALLYRS(:,100,1);




%%%%%
[aa ss dd] = size(meanPW_MPstats_ALLYRS);
PW24mmMask_MPstats = zeros(aa,ss,dd); PW24mmMask_MPstats(:) = NaN; 
PWMEAN = mean( meanPW_MPstats_ALLYRS,1,'omitnan' );  PWMEAN = permute(PWMEAN,[2 3 1]);
for n = 1:ss
    for y = 1:dd
        if( PWMEAN(n,y) >= 24.0 )
            PW24mmMask_MPstats(:,n,y) = 1;
        end
    end
end

% pblah = PW24mmMask_MPstats(:,:,1);
% pwblah = meanPW_MPstats_ALLYRS(:,:,1);



%kill the MCSs/MPs with 0-hr duration  (looks like only duration has this? - other fields have nan at these times, i think):

kill_MCS0 = find(  duration_MCSstats_ALLYRS==0  );
duration_MCSstats_ALLYRS(kill_MCS0) = NaN ;

duration_MPstats_ALLYRS(duration_MPstats_ALLYRS==0) = NaN;




%total objects tracked all years in May-Aug  (I only track then, so no need to purge pre/post these months):
num_all_MPs = length( find( isnan(duration_MPstats_ALLYRS)==0 )  )




% Need to purge the MCS #'s in MASK_KEEPERS/TOSSERS before May1 and after Aug 31, otherwise, be counting MCSs outside of MJJA in the population:

basetime_1may_00z = [1083369600;  %2004
                     1114905600;
                     1146441600; %2006
                     1177977600;
                     1209600000;
                     1241136000;  %2009
                     1272672000;
                     1304208000;
                     1335830400;  %2012
                     1367366400;
                     1398902400;
                     1430438400;  %2015
                     1462060800;  %2016
                     1493596800;   %2017
                     1525132800;  %2018
                     1556668800;  %2019
                     1588291200;  %2020
                     1619827200];  %2021
     
basetime_31aug_23z = [1093993200;  %2004
                     1125529200;
                     1157065200; %2006
                     1188601200;
                     1220223600;
                     1251759600;  %2009
                     1283295600;
                     1314831600;
                     1346454000;  %2012
                     1377990000;
                     1409526000;
                     1441062000;  %2015
                     1472684400;  %2016
                     1504220400;   %2017
                     1535756400;  %2018
                     1567292400;  %2019
                     1598914800;  %2020
                     1630450800];  %2021
% pres_MASK_KEEPERS_MCS_ALLYRS = MASK_KEEPERS_MCS_ALLYRS;
% 
% MASK_KEEPERS_MCS_ALLYRS = pres_MASK_KEEPERS_MCS_ALLYRS;

%find MCS in each year that happens before 1 may or after 31 aug and NAN them from some MCS fields that weren't filtered
[amk bmk] = size(MASK_KEEPERS_MCS_ALLYRS) ;
for n = 1:amk
    for y = 1:bmk
        % y = 1; n = 1;
        if( isnan(MASK_KEEPERS_MCS_ALLYRS(n,y))==0 )
            firsttime = basetime_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) < basetime_1may_00z(y);
            lasttime  = basetime_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) > basetime_31aug_23z(y);
            firstyes = find(firsttime==1);
            lastyes = find(lasttime==1);
                if( isempty(firstyes)==0 | isempty(lastyes)==0  )
                    meanlat_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    meanlon_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    basetime_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    convrain_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    dAdt_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    dirmotion_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
%                     maxMUCAPE_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
%                     maxVIWVConv_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    maxW600_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    maxW600bpf_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    %meanPW_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    rainrate_heavyrain_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    speed_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    status_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    stratrain_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    totalrain_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 

                    totalrain6HR_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    totalheavyrain6HR_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 

                    pf_accumrain_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;
                    pf_maxrainrate_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;

                    pf_convrate_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;
                    pf_stratrate_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;
                    pf_convarea_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;
                    pf_stratarea_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;

                    pf_ETH10_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;
                    pf_ETH30_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;
                    pf_ETH40_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;
                    pf_ETH45_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;
                    pf_ETH50_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;

                    pfarea_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;
                    pflat_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;
                    pflon_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;
                    pfrainrate_MCSstats_ALLYRS(:,:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN;

                    totalrainmass_MCSstats_ALLYRS(MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    duration_MCSstats_ALLYRS(MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    MCSspeed_MCSstats_ALLYRS(MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    %LStracks_perMCS_ALLYRS  %done already
                    %MPtracks_perMCS_ALLYRS  %done already
                    MASK_KEEPERS_MCS_ALLYRS(n,y) = NaN; 
                end
        end
    end
end

% % found a mcs track or so per year (I think always the last one, spanning 8/31 23hr - 9/1 00hr ?)
for yr = 1:ay
    yr
    tracktokill = find( (isnan(MPtracks_perMCS_ALLYRS(1,:,yr))==0   &  isnan(convrain_MCSstats_ALLYRS(1,:,yr))==1)==1  ) 
    MPtracks_perMCS_ALLYRS(:,tracktokill,yr) = NaN;
end




%  blah = convrain_MCSstats_ALLYRS(:,:,18);
%  blah2 = MPtracks_perMCS_ALLYRS(:,:,18);
%  blah1 = basetime_MCSstats_met_yymmddhhmmss_ALLYRS(:,:,18);
%  blah3 = basetime_MCSstats_ALLYRS(:,:,15);


% figure; contourf( permute(pf_accumrain_MCSstats_ALLYRS(1,:,:,1),[2 3 1 4]),20 );
% figure; contourf( basetime_MCSstats_ALLYRS(:,:,1),20 );
% figure; plot( duration_MCSstats_ALLYRS(:,1) );

% hopefully I dont need the TOSSERS_MCS numbers fixed too because I cant get this working - I think i npart (or whole) because basetimes appear to be are already naned for tossers? 
% pres_MASK_TOSSERS_MCS_ALLYRS = MASK_TOSSERS_MCS_ALLYRS;
% MASK_TOSSERS_MCS_ALLYRS = pres_MASK_TOSSERS_MCS_ALLYRS;
% [amk bmk] = size(MASK_TOSSERS_MCS_ALLYRS) ;
% for n = 1:amk
%     for y = 1:bmk
%         %  y = 1; n = 1;
%         if( isnan(MASK_TOSSERS_MCS_ALLYRS(n,y))==0 )
% 
%             alreadydead = isnan(basetime_MCSstats_ALLYRS(1,MASK_TOSSERS_MCS_ALLYRS(n,y),y))    %where basetime is already filtered to NAT
%             if( alreadydead )
%                 MASK_TOSSERS_MCS_ALLYRS(n,y) = -767;
%             else
% 
%                 firsttime = basetime_MCSstats_ALLYRS(:,MASK_TOSSERS_MCS_ALLYRS(n,y),y) < basetime_1may_00z(y);
%                 lasttime  = basetime_MCSstats_ALLYRS(:,MASK_TOSSERS_MCS_ALLYRS(n,y),y) > basetime_31aug_23z(y);
%                 firstyes = find(firsttime==1);
%                 lastyes = find(lasttime==1);
% 
%                 if( isempty(firstyes)==0 | isempty(lastyes)==0  )
%                     MASK_TOSSERS_MCS_ALLYRS(n,y) = -989;
%                 end
% 
%             end
%         end
%     end
% 
% end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

%%%%%%%%%%%%%      More ANALYSIS. FIlter out LSs, etc.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% 0) filter MPs and MCSs on those that have an LS present 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%define mask in MCSstats space to NaN-out MCSs when an LS is present in first "Xhrs" hours
Xhrs = 6;
mask_kill_mcs_because_LS_present_early = zeros(mcs_times,mcs_tracks,ay); 
mask_kill_mcs_because_LS_present_early(:) = 1;
for Y = 1:ay
    for n = 1:mcs_tracks
        lsp = find(  LStracks_perMCS_ALLYRS(1:Xhrs,n,Y) > 0 );
        if( isempty(lsp)==0 ) %there's a LS present, so nan the mask!
            mask_kill_mcs_because_LS_present_early(:,n,Y) = NaN;
        end
    end
end
% blah = LStracks_perMCS_ALLYRS(:,:,2);
% blah2 = mask_kill_mcs_because_LS_present_early(:,:,2);


%define mask in MPstats space to nan-out MPs when an LS is present at any point in their life
mask_kill_mp_because_LS_present = zeros(MP_tracks,ay); mask_kill_mp_because_LS_present(:) = 1;
for Y = 1:ay
    for n = 1:MP_tracks
        lsp = find( LStracks_perMP_ALLYRS(:,n,Y) > 0 ) ;
        if( isempty(lsp)==0 ) % if not empty, then a LS present. so nan the mask here!
            mask_kill_mp_because_LS_present(n,Y) = NaN;
        end
    end
end


% blah = LStracks_perMP_ALLYRS(:,:,1);
% blah = meanlon_MPstats_ALLYRS(:,:,1);
%%%% wait... applying this independtenly to MP field will just ditch the MPs, resulting in more MCSs that dont have MPs... Do I need to loop through the MPs with the LSs and then nan-out the MCSs that have them?
% % or, is this just the same as killing MCSs with LSs? I think so? Regardless, but if you want to report on stats of just MPs (without LSs), you want to implement this mask


%loop thru the MPs with LSs and chop out the MCSs that overlap with them:
mask_kill_mcs_because_MP_has_an_LS = mask_kill_mcs_because_LS_present_early;  %mask that will do this and has already killed MCSs with LSs present
for Y = 1:ay

    % build list of MPs in current year touched by LSs:
    mp_hitlist = [];
    for n = 1:MP_tracks
        badmps = LStracks_perMP_ALLYRS(:,n,Y); badmps = unique(badmps); badmps(isnan(badmps))=[]; badmps(badmps<1)=[]; % LS numbers corrupting current MP
        if( isempty(badmps)==0 ) %there's a corrupted MP, then log its number
            mp_hitlist = vertcat(mp_hitlist,n);  %current year's list of MPs rotted by LSs
        end
    end %MP number

    % then find MCS influenced by MPs on the mp_hitlist in the MPtracks_perMCS array and NaN them in a mask:
    %  Y = 1; n = 120;

    for n = 1:mcs_tracks

        mps = MPtracks_perMCS_ALLYRS(:,n,Y) ;
        mps(find( mps > 0));  mps = unique(mps); mps(mps<1)=[];  mps(isnan(mps))=[];  %list of MPs touching current mcs

        %look thru mp list in this Mcs and if present in mp_hitlist, mark the MCS as a hit
        for  m = 1:length(mps)
            % m = 2;
            mmm = (mps(m) == mp_hitlist) ;
            hit = find(mmm==1) ;
            if( isempty(hit)==0 ) 
                mask_kill_mcs_because_MP_has_an_LS(:,n,Y) = NaN;
                %disp('hit')
            end
        end
    end

end %year

% blah = mask_kill_mcs_because_MP_has_an_LS(:,:,1);
% blah2 = MPtracks_perMCS_ALLYRS(:,:,1);


%define mask in MCSstats space to keep MCSs when an LS is present in MCSs' first "Xhrs" hours
Xhrs = 6;
mask_kept_mcsi_because_LS_present_early = zeros(mcs_times,mcs_tracks,ay); 
mask_kept_mcsi_because_LS_present_early(:) = NaN;
for Y = 1:ay
    for n = 1:mcs_tracks
        lsp = find(  LStracks_perMCS_ALLYRS(1:Xhrs,n,Y) > 0 );
        if( isempty(lsp)==0 ) %there's a LS present, so 1 the mask!
            mask_kept_mcsi_because_LS_present_early(:,n,Y) = 1;
        end
    end
end


%define mask in MCSstats space to keep MCSs when an LS is present at any point in MCSs' lifetime
mask_kept_mcsfull_because_LS_present = zeros(mcs_times,mcs_tracks,ay); 
mask_kept_mcsfull_because_LS_present(:) = NaN;
for Y = 1:ay
    for n = 1:mcs_tracks
        lsp = find(  LStracks_perMCS_ALLYRS(1:end,n,Y) > 0 );
        if( isempty(lsp)==0 ) %there's a LS present, so 1 the mask!
            mask_kept_mcsfull_because_LS_present(:,n,Y) = 1;
        end
    end
end

% blah = mask_kept_mcsfull_because_LS_present_early(:,:,1);

%mblah = MPtracks_perMCS_ALLYRS(:,:,6) 




%%%%%%%%%
%%% "fix" holefill the LStracks_perMCS_ALLYRS and MPtracks_perMCS_ALLYRS that have
%%% NaNs in the frst few times of MCS lifecycle by backward 
%%% to time=1 via nearest neighbor extrap
%%%%%%%%%
[l1 l2 l3] = size(LStracks_perMCS_ALLYRS);
for n = 1:l2
    for y = 1:l3
        % n = 178; y = 2;
        track = LStracks_perMCS_ALLYRS(:,n,y);
        goods = find( isnan(track)==0 ) ;
        if( length( goods ) > 0  &  goods(1) < 5 )  %if not allnans
            if( goods(1) > 1 )
                LStracks_perMCS_ALLYRS(1:goods(1)-1,n,y) = LStracks_perMCS_ALLYRS(goods(1),n,y) ;
            end
        end
    end
end
% lblah = LStracks_perMCS_ALLYRS(:,:,2);
[l1 l2 l3] = size(MPtracks_perMCS_ALLYRS);
for n = 1:l2
    for y = 1:l3
        % n = 78; y = 6;
        track = MPtracks_perMCS_ALLYRS(:,n,y);
        goods = find( isnan(track)==0 ) ;
        if( length( goods ) > 0  & goods(1) < 5 )  %if not allnans and the first good value ist too far into the MCSs record
            if( goods(1) > 1 )
                MPtracks_perMCS_ALLYRS(1:goods(1)-1,n,y) = MPtracks_perMCS_ALLYRS(goods(1),n,y) ;
            end
        end
    end
end
% mblah = MPtracks_perMCS_ALLYRS(:,78,6) 



%%%%%%%%%%%%%%%%%%%% month chunk filtering %%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%% filter MCSs by month:

%the months you want to include in the analysis:
keepmonths = ['05';'06';'07';'08'];   
%keepmonths = ['05';'06';'  ';'  '];
%keepmonths = ['07';'08';'  ';'  '];
%keepmonths = ['05';'  ';'  ';'  '];

[bl1 bl2] = find(keepmonths=='  '); bl1 = unique(bl1);
kms = keepmonths;  kms(bl1,:) = []  ;
keptmonslab = strcat('mon',kms(1,:),'to',kms(end,:))

% note: a section down below (VAR_atMCSI) will choke when you break down by
% month, so you will have to comment that section (commented below) and
% just use this break down for table statistics

%%% filter MCS fields by month periods:

MCSmonth = string( datetime(basetime_MCSstats_ALLYRS(1,:,:), 'convertfrom','posixtime','Format','MM') );   MCSmonth = permute(MCSmonth,[ 2 3 1]);
mask_MCS_keepermonths = basetime_MCSstats_ALLYRS;   mask_MCS_keepermonths(:) = NaN;
for y = 1 : mcs_years
    keep = find(MCSmonth(:,y) == keepmonths(1,:) | MCSmonth(:,y) == keepmonths(2,:) | MCSmonth(:,y) == keepmonths(3,:) | MCSmonth(:,y) == keepmonths(4,:));
    mask_MCS_keepermonths(:,keep,y) = 1;
end
% MCSmonth = string( datetime(basetime_MCSstats_ALLYRS, 'convertfrom','posixtime','Format','MM') );
% mask_MCS_keepermonths = basetime_MCSstats_ALLYRS;   mask_MCS_keepermonths(:) = NaN;
% keep= find(MCSmonth == keepmonths(1,:) | MCSmonth == keepmonths(2,:) | MCSmonth == keepmonths(3,:) | MCSmonth == keepmonths(4,:));
% mask_MCS_keepermonths(keep) = 1;

mp1 = MPtracks_perMCS_ALLYRS ;   % mp1b = MPtracks_perMCS_ALLYRS(:,:,1) ;
b1 = basetime_MCSstats_ALLYRS ;

%MCS vars:
MPtracks_perMCS_ALLYRS              = MPtracks_perMCS_ALLYRS .* mask_MCS_keepermonths ;   %filter this again(?) after you have an MP filter
LStracks_perMCS_ALLYRS              = LStracks_perMCS_ALLYRS .* mask_MCS_keepermonths ; 
meanlat_MCSstats_ALLYRS             = meanlat_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
meanlon_MCSstats_ALLYRS             = meanlon_MCSstats_ALLYRS .* mask_MCS_keepermonths ; 
basetime_MCSstats_ALLYRS            = basetime_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
convrain_MCSstats_ALLYRS            = convrain_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
dAdt_MCSstats_ALLYRS                = dAdt_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
dirmotion_MCSstats_ALLYRS           = dirmotion_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
maxW600_MCSstats_ALLYRS             = maxW600_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
maxW600bpf_MCSstats_ALLYRS          = maxW600bpf_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
rainrate_heavyrain_MCSstats_ALLYRS  = rainrate_heavyrain_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
speed_MCSstats_ALLYRS               = speed_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
status_MCSstats_ALLYRS              = status_MCSstats_ALLYRS .* mask_MCS_keepermonths ; 
stratrain_MCSstats_ALLYRS           = stratrain_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
totalrain_MCSstats_ALLYRS           = totalrain_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
totalrain6HR_MCSstats_ALLYRS        = totalrain6HR_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
totalheavyrain6HR_MCSstats_ALLYRS   = totalheavyrain6HR_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
MotionX_MCSstats_ALLYRS             = MotionX_MCSstats_ALLYRS .* mask_MCS_keepermonths ;
MotionY_MCSstats_ALLYRS             = MotionY_MCSstats_ALLYRS .* mask_MCS_keepermonths ;

      mask_pfMCS_keepermonths =  permute( cat(4,mask_MCS_keepermonths,mask_MCS_keepermonths,mask_MCS_keepermonths,mask_MCS_keepermonths,mask_MCS_keepermonths ),[4 1 2 3]) ;
pf_accumrain_MCSstats_ALLYRS        = pf_accumrain_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ; 
pf_maxrainrate_MCSstats_ALLYRS      = pf_maxrainrate_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;
pf_convrate_MCSstats_ALLYRS         = pf_convrate_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;
pf_stratrate_MCSstats_ALLYRS        = pf_stratrate_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;
pf_convarea_MCSstats_ALLYRS         = pf_convarea_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;
pf_stratarea_MCSstats_ALLYRS        = pf_stratarea_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;
pf_ETH10_MCSstats_ALLYRS            = pf_ETH10_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;
pf_ETH30_MCSstats_ALLYRS            = pf_ETH30_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;
pf_ETH40_MCSstats_ALLYRS            = pf_ETH40_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;
pf_ETH45_MCSstats_ALLYRS            = pf_ETH45_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;
pf_ETH50_MCSstats_ALLYRS            = pf_ETH50_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;
pfarea_MCSstats_ALLYRS              = pfarea_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;
pflat_MCSstats_ALLYRS               = pflat_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;
pflon_MCSstats_ALLYRS               = pflon_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;
pfrainrate_MCSstats_ALLYRS          = pfrainrate_MCSstats_ALLYRS .* mask_pfMCS_keepermonths ;

    mask_nMCS_keepermonths =  mask_MCS_keepermonths(1,:,:) ;    mask_nMCS_keepermonths = permute(mask_nMCS_keepermonths,[2 3 1]);
duration_MCSstats_ALLYRS            = duration_MCSstats_ALLYRS .* mask_nMCS_keepermonths ;
MCSspeed_MCSstats_ALLYRS            = MCSspeed_MCSstats_ALLYRS .* mask_nMCS_keepermonths ;
totalrainmass_MCSstats_ALLYRS       = totalrainmass_MCSstats_ALLYRS .* mask_nMCS_keepermonths ;

MASK_KEEPERS_MCS_ALLYRS             = MASK_KEEPERS_MCS_ALLYRS .* mask_nMCS_keepermonths ;


% mp2 = MPtracks_perMCS_ALLYRS;



%%%%%%%%%%%%%%%%%%%% filter MPs by month chunks: %%%%%%%%%%%%%%%%%%%%



%%% filter MP fields by month periods:
MPmonth = string( datetime(basetime_MPstats_ALLYRS(1,:,:), 'convertfrom','posixtime','Format','MM') );   MPmonth = permute(MPmonth,[ 2 3 1]);
mask_MP_keepermonths = basetime_MPstats_ALLYRS;   mask_MP_keepermonths(:) = NaN;
for y = 1 : MP_years
    keep = find(MPmonth(:,y) == keepmonths(1,:) | MPmonth(:,y) == keepmonths(2,:) | MPmonth(:,y) == keepmonths(3,:) | MPmonth(:,y) == keepmonths(4,:) );
    mask_MP_keepermonths(:,keep,y) = 1;
end
% for y = 1 : MP_years
%     %add back those few still in month-filtered MPtracks_perMCS record?
%     touchedmcs = unique(MPtracks_perMCS_ALLYRS(:,:,y));  touchedmcs(isnan(touchedmcs)) = []; touchedmcs(touchedmcs==-1) = [];
%     for h = 1:length(touchedmcs)
%         mask_MP_keepermonths(:,touchedmcs(h),y) = 1;
%     end
% 
% end

%%% now filter out MP fields if the MP mean wind is N-E-S-W (keep NWflow quadrant):
mask_MP_keeperNWwinds = meanWNDDIR600_MPstats_ALLYRS;   mask_MP_keeperNWwinds(:) = NaN;
for y = 1 : MP_years
    for n = 1 : MP_tracks
        %  n = 673;   y = 1;
        if( mean(meanWNDDIR600_MPstats_ALLYRS(:,n,y),'omitnan') >= 270.   &   mean(meanWNDDIR600_MPstats_ALLYRS(:,n,y),'omitnan') <= 360. )
            mask_MP_keeperNWwinds(:,n,y) = 1;
        end
    end
end

%%% now filter out MP fields if MPI is east of -100.0 longitude:
mask_MP_keeperMPIGATE = meanlon_MPstats_ALLYRS - 360.;   mask_MP_keeperMPIGATE(:) = NaN;
for y = 1 : MP_years
    for n = 1 : MP_tracks
        %  n = 673;   y = 1;
        if( (meanlon_MPstats_ALLYRS(1,n,y) - 360) <= -100. )
            mask_MP_keeperMPIGATE(:,n,y) = 1;
        end
    end
end

mask_MP_alldesired = mask_MP_keepermonths .* mask_MP_keeperMPIGATE .* mask_MP_keeperNWwinds ;


% MPmonth = string( datetime(basetime_MPstats_ALLYRS, 'convertfrom','posixtime','Format','MM') );
% mask_MP_keepermonths = basetime_MPstats_ALLYRS;   mask_MP_keepermonths(:) = NaN;
% keep = find(MPmonth == keepmonths(1,:) | MPmonth == keepmonths(2,:) | MPmonth == keepmonths(3,:) | MPmonth == keepmonths(4,:));
%mask_MP_keepermonths(keep) = 1;

area_MPstats_ALLYRS                         = area_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ;  
basetime_MPstats_ALLYRS                     = basetime_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
meanlat_MPstats_ALLYRS                      = meanlat_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
meanlon_MPstats_ALLYRS_BEFOREfiltalldesired     = meanlon_MPstats_ALLYRS;
meanlon_MPstats_ALLYRS                      = meanlon_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
status_MPstats_ALLYRS                       = status_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
dAdt_MPstats_ALLYRS                         = dAdt_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
MotionX_MPstats_ALLYRS                      = MotionX_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
MotionY_MPstats_ALLYRS                      = MotionY_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
maxVOR600_MPstats_ALLYRS                    = maxVOR600_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
maxW600bpf_MPstats_ALLYRS                   = maxW600bpf_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
maxW600_MPstats_ALLYRS                      = maxW600_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ;            
LStracks_perMP_ALLYRS                       = LStracks_perMP_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
%MPenvs
meanMUCAPE_MPstats_ALLYRS                   = meanMUCAPE_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
maxMUCAPE_MPstats_ALLYRS                    = maxMUCAPE_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
meanMUCIN_MPstats_ALLYRS                    = meanMUCIN_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
minMUCIN_MPstats_ALLYRS                     = minMUCIN_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
meanMULFC_MPstats_ALLYRS                    = meanMULFC_MPstats_ALLYRS    .*  mask_MP_alldesired ; %mask_MP_keepermonths ;   
meanMUEL_MPstats_ALLYRS                     = meanMUEL_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
meanPW_MPstats_ALLYRS                       = meanPW_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
maxPW_MPstats_ALLYRS                        = maxPW_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
minPW_MPstats_ALLYRS                        = minPW_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
meanshearmag0to2_MPstats_ALLYRS             = meanshearmag0to2_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
maxshearmag0to2_MPstats_ALLYRS              = maxshearmag0to2_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
meanshearmag0to6_MPstats_ALLYRS             = meanshearmag0to6_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
maxshearmag0to6_MPstats_ALLYRS              = maxshearmag0to6_MPstats_ALLYRS   .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
meanshearmag2to9_MPstats_ALLYRS             = meanshearmag2to9_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
maxshearmag2to9_MPstats_ALLYRS              = maxshearmag2to9_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
meanOMEGA600_MPstats_ALLYRS                 = meanOMEGA600_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
minOMEGA600_MPstats_ALLYRS                  = minOMEGA600_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
minOMEGAsub600_MPstats_ALLYRS               = minOMEGAsub600_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
meanVIWVD_MPstats_ALLYRS                    = meanVIWVD_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
minVIWVD_MPstats_ALLYRS                     = minVIWVD_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
maxVIWVD_MPstats_ALLYRS                     = maxVIWVD_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
meanDIV750_MPstats_ALLYRS                   = meanDIV750_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
minDIV750_MPstats_ALLYRS                    = minDIV750_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
minDIVsub600_MPstats_ALLYRS                 = minDIVsub600_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
meanWNDSPD600_MPstats_ALLYRS                = meanWNDSPD600_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 
meanWNDDIR600_MPstats_ALLYRS_BEFOREfiltalldesired     = meanWNDDIR600_MPstats_ALLYRS;
meanWNDDIR600_MPstats_ALLYRS                = meanWNDDIR600_MPstats_ALLYRS  .*  mask_MP_alldesired ; %mask_MP_keepermonths ; 

%     mask_nMP_keepermonths =  mask_MP_keepermonths(1,:,:) ;    mask_nMP_keepermonths = permute(mask_nMP_keepermonths,[2 3 1]);
% duration_MPstats_ALLYRS                     = duration_MPstats_ALLYRS  .*  mask_nMP_keepermonths ; 

  mask_nMP_keeperall =  mask_MP_alldesired(1,:,:) ;    mask_nMP_keeperall = permute(mask_nMP_keeperall,[2 3 1]);
duration_MPstats_ALLYRS                     = duration_MPstats_ALLYRS  .*  mask_nMP_keeperall ; 

% MASK_KEEPERS_MP_ALLYRS  =  MASK_KEEPERS_MP_ALLYRS .*  mask_nMP_keepermonths ; 
% MASK_TOSSERS_MP_ALLYRS  =  MASK_TOSSERS_MP_ALLYRS .*  mask_nMP_keepermonths ; 

%  mblah1 = MP_with_MCSs_ALLYRS;

% for y = 1:MP_years
%     mphitlist = find( isnan(mask_nMP_keepermonths(:,y))) ;
%     for n = 1:length(mphitlist)
% 
%         hit = find(MP_with_MCSs_ALLYRS(:,y) == mphitlist(n)) ;
%         MP_with_MCSs_ALLYRS(hit,y) = NaN;
% 
%         hit = find(MP_without_MCSs_ALLYRS(:,y) == mphitlist(n)) ;
%         MP_without_MCSs_ALLYRS(hit,y) = NaN;
% 
%         hit = find(MP_other_ALLYRS(:,y) == mphitlist(n)) ;
%         MP_other_ALLYRS(hit,y) = NaN;
% 
%     end
% end

for y = 1:MP_years
    %mphitlist = find( isnan(mask_nMP_keepermonths(:,y))) ;
    mphitlist = find( isnan(mask_nMP_keeperall(:,y))) ;
    for n = 1:length(mphitlist)

        hit = find(MP_with_MCSs_ALLYRS(:,y) == mphitlist(n)) ;
        MP_with_MCSs_ALLYRS(hit,y) = NaN;

        hit = find(MP_without_MCSs_ALLYRS(:,y) == mphitlist(n)) ;
        MP_without_MCSs_ALLYRS(hit,y) = NaN;

        hit = find(MP_other_ALLYRS(:,y) == mphitlist(n)) ;
        MP_other_ALLYRS(hit,y) = NaN;

    end
end


%  mblah2 = MP_with_MCSs_ALLYRS;


basetime_MPstats_met_yymmddhhmmss_ALLYRS = datetime(basetime_MPstats_ALLYRS, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% end MCS/MP month filtering%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%










%num_all_mcs = length(find(isnan(duration_MCSstats_ALLYRS)==0))




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Some resulting big-picture stats stuff using the MPforMCS array:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%{
%total MCSs (regardless of LS,MP,alone):
mcs_preLSfilter = MPtracks_perMCS_ALLYRS(1,:,:); mcs_preLSfilter = mcs_preLSfilter(:);  %find all MCSs
num_mcs_preLSfilter = length(  find(isnan(mcs_preLSfilter)==0)  ) 


%total MCSs with (and without) LSs:
filt_MCS = MPtracks_perMCS_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;      %LS_present_early is first 6 hrs of mcs. I think MP_has_an_LS is for LS overlap anytime during MP lifetime that touches an MCS

mcs_postLSfilter = filt_MCS(1,:,:) ; mcs_postLSfilter = mcs_postLSfilter(:);
num_mcs_postLSfilter = length(  find(isnan(mcs_postLSfilter)==0)  ) 

num_mcs_withLS = num_mcs_preLSfilter - num_mcs_postLSfilter 
percent_mcs_withLS = 100 * (num_mcs_withLS/num_mcs_preLSfilter)
%}





%MPs:

% %oops: MPstats not yet filtered on CONUS domain in previous .m file?. Will have to add that later. until then, I will jerry-rig it
% % by using an already filtered field to conjure a mask for LStracks_perMP:
% maskMP =  permute(meanlon_MPstats_ALLYRS(1,:,:),[2 3 1]); maskMP(isnan(maskMP)==0) =1;   maskMP = maskMP(:);
% %mp_preLSfilter = permute(LStracks_perMP_ALLYRS(1,:,:),[2 3 1]); mp_preLSfilter = mp_preLSfilter(:);
% num_mp_preLSfilter = length(  find(maskMP==1) )  
% 
% maskMP = permute(meanlon_MPstats_ALLYRS(1,:,:),[2 3 1]) .* mask_kill_mp_because_LS_present;  maskMP(isnan(maskMP)==0) =1;  maskMP = maskMP(:);
% num_mp_postLSfilter = length(  find(maskMP==1) )  









%%%%% I guess it makes sense to apply these LS filters here before all else?
if(filteroutLS == 1)

    % note, after filtering, the original MCSstats vars that have the LS-MCSs removed will have the original var_MCSstats_ALLYRS name. 
    % Those with LSs present will be named the same var with "_YESLS" suffix added

    disp('  filtering MCSs on LS presence or lackthereof  ')

    % %% %% %% %% %% %% %% %% %% %% %% %% % % %% %% %% %% %% %% %% %% %% %% %% %% % % %% %% %% %% %% %% %% %% %% %% %% %% %
    % kill all mcs stats that have an LS present at MCSI and if they are touching an MP that has touched an LS:
    % %% %% %% %% %% %% %% %% %% %% %% %% % % %% %% %% %% %% %% %% %% %% %% %% %% % % %% %% %% %% %% %% %% %% %% %% %% %% %

    %2d
    basetime_MCSstats_ALLYRS_NOLS                    = basetime_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    %basetime_MCSstats_met_yymmddhhmmss_ALLYRS_NOLS   = basetime_MCSstats_met_yymmddhhmmss_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    convrain_MCSstats_ALLYRS_NOLS                    = convrain_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    dAdt_MCSstats_ALLYRS_NOLS                        = dAdt_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    dirmotion_MCSstats_ALLYRS_NOLS                   = dirmotion_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    LStracks_perMCS_ALLYRS_NOLS                      = LStracks_perMCS_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
%     maxMUCAPE_MCSstats_ALLYRS_NOLS                   = maxMUCAPE_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
%     maxVIWVConv_MCSstats_ALLYRS_NOLS                 = maxVIWVConv_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    maxW600_MCSstats_ALLYRS_NOLS                     = maxW600_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    maxW600bpf_MCSstats_ALLYRS_NOLS                  = maxW600bpf_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    meanlat_MCSstats_ALLYRS_NOLS                     = meanlat_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    meanlon_MCSstats_ALLYRS_NOLS                     = meanlon_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
%     meanPW_MCSstats_ALLYRS_NOLS                      = meanPW_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    MPtracks_perMCS_ALLYRS_NOLS                      = MPtracks_perMCS_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    rainrate_heavyrain_MCSstats_ALLYRS_NOLS          = rainrate_heavyrain_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    speed_MCSstats_ALLYRS_NOLS                       = speed_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    status_MCSstats_ALLYRS_NOLS                      = status_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    stratrain_MCSstats_ALLYRS_NOLS                   = stratrain_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    totalheavyrain_MCSstats_ALLYRS_NOLS              = totalheavyrain_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    totalrain_MCSstats_ALLYRS_NOLS                   = totalrain_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    
    totalrain6HR_MCSstats_ALLYRS_NOLS                = totalrain6HR_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    totalheavyrain6HR_MCSstats_ALLYRS_NOLS           = totalheavyrain6HR_MCSstats_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    
    MotionX_MCSstats_ALLYRS_NOLS                     = MotionX_MCSstats_ALLYRS  .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;
    MotionY_MCSstats_ALLYRS_NOLS                     = MotionY_MCSstats_ALLYRS  .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;

    %1d

    duration_MCSstats_ALLYRS_NOLS                    = duration_MCSstats_ALLYRS .* permute(mask_kill_mcs_because_LS_present_early(1,:,:),[2 3 1]) .* permute(mask_kill_mcs_because_MP_has_an_LS(1,:,:),[2 3 1]) ;
    totalrainmass_MCSstats_ALLYRS_NOLS               = totalrainmass_MCSstats_ALLYRS .* permute(mask_kill_mcs_because_LS_present_early(1,:,:),[2 3 1]) .* permute(mask_kill_mcs_because_MP_has_an_LS(1,:,:),[2 3 1]) ;
    MCSspeed_MCSstats_ALLYRS_NOLS                    = MCSspeed_MCSstats_ALLYRS .* permute(mask_kill_mcs_because_LS_present_early(1,:,:),[2 3 1]) .* permute(mask_kill_mcs_because_MP_has_an_LS(1,:,:),[2 3 1]) ;
    %5x2d
    maskpf_kill_mcs_because_LS_present_early_NOLS    = cat(4,mask_kill_mcs_because_LS_present_early,mask_kill_mcs_because_LS_present_early,mask_kill_mcs_because_LS_present_early,mask_kill_mcs_because_LS_present_early,mask_kill_mcs_because_LS_present_early)   ;
    maskpf_kill_mcs_because_LS_present_early_NOLS    = permute(maskpf_kill_mcs_because_LS_present_early_NOLS,[4 1 2 3]);
    maskpf_kill_mcs_because_MP_has_an_LS_NOLS        = cat(4,mask_kill_mcs_because_MP_has_an_LS,mask_kill_mcs_because_MP_has_an_LS,mask_kill_mcs_because_MP_has_an_LS,mask_kill_mcs_because_MP_has_an_LS,mask_kill_mcs_because_MP_has_an_LS)   ;
    maskpf_kill_mcs_because_MP_has_an_LS_NOLS        = permute(maskpf_kill_mcs_because_MP_has_an_LS_NOLS,[4 1 2 3]);
    pf_accumrain_MCSstats_ALLYRS_NOLS                = pf_accumrain_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ;
    pf_accumrainheavy_MCSstats_ALLYRS_NOLS           = pf_accumrainheavy_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ;
    pf_maxrainrate_MCSstats_ALLYRS_NOLS              = pf_maxrainrate_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ;
    pfarea_MCSstats_ALLYRS_NOLS                      = pfarea_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ;
    pflat_MCSstats_ALLYRS_NOLS                       = pflat_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ;
    pflon_MCSstats_ALLYRS_NOLS                       = pflon_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ;
    pfrainrate_MCSstats_ALLYRS_NOLS                  = pfrainrate_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ;

    pf_convrate_MCSstats_ALLYRS_NOLS                 = pf_convrate_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ; 
    pf_stratrate_MCSstats_ALLYRS_NOLS                = pf_stratrate_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ;
    pf_convarea_MCSstats_ALLYRS_NOLS                 = pf_convarea_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ; 
    pf_stratarea_MCSstats_ALLYRS_NOLS                = pf_stratarea_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ; 

    pf_ETH10_MCSstats_ALLYRS_NOLS                    = pf_ETH10_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ; 
    pf_ETH30_MCSstats_ALLYRS_NOLS                    = pf_ETH30_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ; 
    pf_ETH40_MCSstats_ALLYRS_NOLS                    = pf_ETH40_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ; 
    pf_ETH45_MCSstats_ALLYRS_NOLS                    = pf_ETH45_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ; 
    pf_ETH50_MCSstats_ALLYRS_NOLS                    = pf_ETH50_MCSstats_ALLYRS .* maskpf_kill_mcs_because_LS_present_early_NOLS .* maskpf_kill_mcs_because_MP_has_an_LS_NOLS ; 

    % % MCSstats vars for MCSs with LSs present 
    % use mask_kept_mcsfull_because_LS_present if you want to see MCSs with LSs present at any time
    % use mask_kept_mcsi_because_LS_present_early if you want to see MCSs with LSs present in fist 6 hours of MCS life

    basetime_MCSstats_ALLYRS_YESLS                    = basetime_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    %basetime_MCSstats_met_yymmddhhmmss_ALLYRS_NOLS   = basetime_MCSstats_met_yymmddhhmmss_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    convrain_MCSstats_ALLYRS_YESLS                    = convrain_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    dAdt_MCSstats_ALLYRS_YESLS                        = dAdt_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    dirmotion_MCSstats_ALLYRS_YESLS                   = dirmotion_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    LStracks_perMCS_ALLYRS_YESLS                      = LStracks_perMCS_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
%     maxMUCAPE_MCSstats_ALLYRS_YESLS                   = maxMUCAPE_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
%     maxVIWVConv_MCSstats_ALLYRS_YESLS                 = maxVIWVConv_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    maxW600_MCSstats_ALLYRS_YESLS                     = maxW600_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    maxW600bpf_MCSstats_ALLYRS_YESLS                  = maxW600bpf_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    meanlat_MCSstats_ALLYRS_YESLS                     = meanlat_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    meanlon_MCSstats_ALLYRS_YESLS                     = meanlon_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    %meanPW_MCSstats_ALLYRS_YESLS                      = meanPW_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    MPtracks_perMCS_ALLYRS_YESLS                      = MPtracks_perMCS_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    rainrate_heavyrain_MCSstats_ALLYRS_YESLS          = rainrate_heavyrain_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    speed_MCSstats_ALLYRS_YESLS                       = speed_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    status_MCSstats_ALLYRS_YESLS                      = status_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    stratrain_MCSstats_ALLYRS_YESLS                   = stratrain_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    totalheavyrain_MCSstats_ALLYRS_YESLS              = totalheavyrain_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    totalrain_MCSstats_ALLYRS_YESLS                   = totalrain_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ;
    totalrain6HR_MCSstats_ALLYRS_YESLS                = totalrain6HR_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ; 
    totalheavyrain6HR_MCSstats_ALLYRS_YESLS           = totalheavyrain6HR_MCSstats_ALLYRS .* mask_kept_mcsfull_because_LS_present ; 

    MotionX_MCSstats_ALLYRS_YESLS                     = MotionX_MCSstats_ALLYRS  .* mask_kept_mcsfull_because_LS_present ;
    MotionY_MCSstats_ALLYRS_YESLS                     = MotionY_MCSstats_ALLYRS  .* mask_kept_mcsfull_because_LS_present ;

    %1d
    duration_MCSstats_ALLYRS_YESLS                    = duration_MCSstats_ALLYRS .* permute(mask_kept_mcsfull_because_LS_present(1,:,:),[2 3 1]) ;
    totalrainmass_MCSstats_ALLYRS_YESLS               = totalrainmass_MCSstats_ALLYRS .* permute(mask_kept_mcsfull_because_LS_present(1,:,:),[2 3 1])  ;
    MCSspeed_MCSstats_ALLYRS_YESLS                    = MCSspeed_MCSstats_ALLYRS .* permute(mask_kept_mcsfull_because_LS_present(1,:,:),[2 3 1]) ;
    %5x2d
    maskpf_keep_mcs_because_LS_present_YESLS          = cat(4,mask_kept_mcsfull_because_LS_present,mask_kept_mcsfull_because_LS_present,mask_kept_mcsfull_because_LS_present,mask_kept_mcsfull_because_LS_present,mask_kept_mcsfull_because_LS_present)   ;
    maskpf_keep_mcs_because_LS_present_YESLS          = permute(maskpf_keep_mcs_because_LS_present_YESLS,[4 1 2 3]);
    pf_accumrain_MCSstats_ALLYRS_YESLS                = pf_accumrain_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ;
    pf_accumrainheavy_MCSstats_ALLYRS_YESLS           = pf_accumrainheavy_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ; 
    pf_maxrainrate_MCSstats_ALLYRS_YESLS              = pf_maxrainrate_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ; 
    pfarea_MCSstats_ALLYRS_YESLS                      = pfarea_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ; 
    pflat_MCSstats_ALLYRS_YESLS                       = pflat_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ; 
    pflon_MCSstats_ALLYRS_YESLS                       = pflon_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ; 
    pfrainrate_MCSstats_ALLYRS_YESLS                  = pfrainrate_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ; 
    pf_convrate_MCSstats_ALLYRS_YESLS                 = pf_convrate_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ; 
    pf_stratrate_MCSstats_ALLYRS_YESLS                = pf_stratrate_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ; 
    pf_convarea_MCSstats_ALLYRS_YESLS                 = pf_convarea_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ; 
    pf_stratarea_MCSstats_ALLYRS_YESLS                = pf_stratarea_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ;    

    pf_ETH10_MCSstats_ALLYRS_YESLS                    = pf_ETH10_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ;   
    pf_ETH30_MCSstats_ALLYRS_YESLS                    = pf_ETH30_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ;   
    pf_ETH40_MCSstats_ALLYRS_YESLS                    = pf_ETH40_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ;   
    pf_ETH45_MCSstats_ALLYRS_YESLS                    = pf_ETH45_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ;   
    pf_ETH50_MCSstats_ALLYRS_YESLS                    = pf_ETH50_MCSstats_ALLYRS .* maskpf_keep_mcs_because_LS_present_YESLS ;   

    % reset var names from ..._ALLYRS_NOLS to ..._ALLYRS (these are the MCSs with no LS present)
    %  (the fields analyzed by default below)


    basetime_MCSstats_ALLYRS            = basetime_MCSstats_ALLYRS_NOLS;
    % basetime_MCSstats_met_yymmddhhmmss_ALLYRS_NOLS = basetime_MCSstats_met_yymmddhhmmss_ALLYRS_NOLS;
    convrain_MCSstats_ALLYRS            = convrain_MCSstats_ALLYRS_NOLS;
    dAdt_MCSstats_ALLYRS                = dAdt_MCSstats_ALLYRS_NOLS;
    dirmotion_MCSstats_ALLYRS           = dirmotion_MCSstats_ALLYRS_NOLS;
    LStracks_perMCS_ALLYRS              = LStracks_perMCS_ALLYRS_NOLS;
%     maxMUCAPE_MCSstats_ALLYRS           = maxMUCAPE_MCSstats_ALLYRS_NOLS;
%     maxVIWVConv_MCSstats_ALLYRS         = maxVIWVConv_MCSstats_ALLYRS_NOLS;
    maxW600_MCSstats_ALLYRS             = maxW600_MCSstats_ALLYRS_NOLS;
    maxW600bpf_MCSstats_ALLYRS          = maxW600bpf_MCSstats_ALLYRS_NOLS;
    meanlat_MCSstats_ALLYRS             = meanlat_MCSstats_ALLYRS_NOLS;
    meanlon_MCSstats_ALLYRS             = meanlon_MCSstats_ALLYRS_NOLS;
%     meanPW_MCSstats_ALLYRS              = meanPW_MCSstats_ALLYRS_NOLS;
    MPtracks_perMCS_ALLYRS              = MPtracks_perMCS_ALLYRS_NOLS;
    rainrate_heavyrain_MCSstats_ALLYRS  = rainrate_heavyrain_MCSstats_ALLYRS_NOLS;
    speed_MCSstats_ALLYRS               = speed_MCSstats_ALLYRS_NOLS;
    status_MCSstats_ALLYRS              = status_MCSstats_ALLYRS_NOLS;
    stratrain_MCSstats_ALLYRS           = stratrain_MCSstats_ALLYRS_NOLS;
    totalheavyrain_MCSstats_ALLYRS      = totalheavyrain_MCSstats_ALLYRS_NOLS;
    totalrain_MCSstats_ALLYRS           = totalrain_MCSstats_ALLYRS_NOLS;
    totalrain6HR_MCSstats_ALLYRS        = totalrain6HR_MCSstats_ALLYRS_NOLS;
    totalheavyrain6HR_MCSstats_ALLYRS   = totalheavyrain6HR_MCSstats_ALLYRS_NOLS;


    MotionX_MCSstats_ALLYRS             = MotionX_MCSstats_ALLYRS_NOLS;
    MotionY_MCSstats_ALLYRS             = MotionY_MCSstats_ALLYRS_NOLS; 

    duration_MCSstats_ALLYRS            = duration_MCSstats_ALLYRS_NOLS;
    totalrainmass_MCSstats_ALLYRS       = totalrainmass_MCSstats_ALLYRS_NOLS;
    MCSspeed_MCSstats_ALLYRS            = MCSspeed_MCSstats_ALLYRS_NOLS;

    pf_accumrain_MCSstats_ALLYRS        = pf_accumrain_MCSstats_ALLYRS_NOLS;
    pf_accumrainheavy_MCSstats_ALLYRS   = pf_accumrainheavy_MCSstats_ALLYRS_NOLS;
    pf_maxrainrate_MCSstats_ALLYRS      = pf_maxrainrate_MCSstats_ALLYRS_NOLS;
    pfarea_MCSstats_ALLYRS              = pfarea_MCSstats_ALLYRS_NOLS;
    pflat_MCSstats_ALLYRS               = pflat_MCSstats_ALLYRS_NOLS;
    pflon_MCSstats_ALLYRS               = pflon_MCSstats_ALLYRS_NOLS;
    pfrainrate_MCSstats_ALLYRS          = pfrainrate_MCSstats_ALLYRS_NOLS;

    pf_convrate_MCSstats_ALLYRS         = pf_convrate_MCSstats_ALLYRS_NOLS; 
    pf_stratrate_MCSstats_ALLYRS        = pf_stratrate_MCSstats_ALLYRS_NOLS; 
    pf_convarea_MCSstats_ALLYRS         = pf_convarea_MCSstats_ALLYRS_NOLS; 
    pf_stratarea_MCSstats_ALLYRS        = pf_stratarea_MCSstats_ALLYRS_NOLS; 

    pf_ETH10_MCSstats_ALLYRS            = pf_ETH10_MCSstats_ALLYRS_NOLS; 
    pf_ETH30_MCSstats_ALLYRS            = pf_ETH30_MCSstats_ALLYRS_NOLS; 
    pf_ETH40_MCSstats_ALLYRS            = pf_ETH40_MCSstats_ALLYRS_NOLS; 
    pf_ETH45_MCSstats_ALLYRS            = pf_ETH45_MCSstats_ALLYRS_NOLS; 
    pf_ETH50_MCSstats_ALLYRS            = pf_ETH50_MCSstats_ALLYRS_NOLS; 



    % %% %% %% %% %% %% %% %% %% %% %% %% %
    % keep only the MP stats values that dont have an LS present at some
    % point in MP life:  These are the fields analyzed by default below
    % %% %% %% %% %% %% %% %% %% %% %% %% %

    mask800_kill_mp_because_LS_present = [];
    for t = 1:MP_times
        mask800_kill_mp_because_LS_present = cat(3,mask800_kill_mp_because_LS_present,mask_kill_mp_because_LS_present);
    end
    mask800_kill_mp_because_LS_present = permute(mask800_kill_mp_because_LS_present,[3 1 2]);

    area_MPstats_ALLYRS                         = area_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    basetime_MPstats_ALLYRS                     = basetime_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    dAdt_MPstats_ALLYRS                         = dAdt_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxVOR600_MPstats_ALLYRS                    = maxVOR600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxW600_MPstats_ALLYRS                      = maxW600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxW600bpf_MPstats_ALLYRS                   = maxW600bpf_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanlat_MPstats_ALLYRS                      = meanlat_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanlon_MPstats_ALLYRS                      = meanlon_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    status_MPstats_ALLYRS                       = status_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    %LStracks_perMP_ALLYRS =
    %basetime_MPstats_met_yymmddhhmmss_ALLYRS    = basetime_MPstats_met_yymmddhhmmss_ALLYRS .* mask800_kill_mp_because_LS_present ;
    duration_MPstats_ALLYRS                     = duration_MPstats_ALLYRS .* mask_kill_mp_because_LS_present ;

    meanMUCAPE_MPstats_ALLYRS           = meanMUCAPE_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxMUCAPE_MPstats_ALLYRS            = maxMUCAPE_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanMUCIN_MPstats_ALLYRS            = meanMUCIN_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minMUCIN_MPstats_ALLYRS             = minMUCIN_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanMULFC_MPstats_ALLYRS            = meanMULFC_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanMUEL_MPstats_ALLYRS             = meanMUEL_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanPW_MPstats_ALLYRS               = meanPW_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxPW_MPstats_ALLYRS                = maxPW_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minPW_MPstats_ALLYRS                = minPW_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanshearmag0to2_MPstats_ALLYRS     = meanshearmag0to2_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxshearmag0to2_MPstats_ALLYRS      = maxshearmag0to2_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanshearmag0to6_MPstats_ALLYRS     = meanshearmag0to6_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxshearmag0to6_MPstats_ALLYRS      = maxshearmag0to6_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanshearmag2to9_MPstat_ALLYRS      = meanshearmag2to9_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxshearmag2to9_MPstats_ALLYRS      = maxshearmag2to9_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanOMEGA600_MPstats_ALLYRS         = meanOMEGA600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minOMEGA600_MPstats_ALLYRS          = minOMEGA600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minOMEGAsub600_MPstats_ALLYRS       = minOMEGAsub600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanVIWVD_MPstats_ALLYRS            = meanVIWVD_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minVIWVD_MPstats_ALLYRS             = minVIWVD_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxVIWVD_MPstats_ALLYRS             = maxVIWVD_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanDIV750_MPstats_ALLYRS           = meanDIV750_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minDIV750_MPstats_ALLYRS            = minDIV750_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minDIVsub600_MPstats_ALLYRS         = minDIVsub600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanWNDSPD600_MPstats_ALLYRS        = meanWNDSPD600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanWNDDIR600_MPstats_ALLYRS        = meanWNDDIR600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;


    disp('   ')
    disp( ' Now, the original MCSstats vars that have the LS-MCSs removed will have the original var_MCSstats_ALLYRS name. Those with LSs present will be named the same var with "_YESLS" suffix added ' )
    disp('   ')
    disp( ' Now, the original MCSstats vars that have the LS-MCSs removed will have the original var_MCSstats_ALLYRS name. Those with LSs present will be named the same var with "_YESLS" suffix added ' )
    disp('   ')
    disp( ' Now, the original MCSstats vars that have the LS-MCSs removed will have the original var_MCSstats_ALLYRS name. Those with LSs present will be named the same var with "_YESLS" suffix added ' )
    disp('   ')

end

% blah = meanlat_MCSstats_ALLYRS_YESLS(:,:,1);
% blahmask = mask_kept_mcsfull_because_LS_present(:,:,1);


%%%%%%%%%%%%%%%%%%%%%
%%%%  now kill the low PW in MP fields
%%%%%%%%%%%%%%%%%%%%%

area_MPstats_ALLYRS                         = area_MPstats_ALLYRS .*  PW24mmMask_MPstats;
basetime_MPstats_ALLYRS                     = basetime_MPstats_ALLYRS .*  PW24mmMask_MPstats;
dAdt_MPstats_ALLYRS                         = dAdt_MPstats_ALLYRS .*  PW24mmMask_MPstats;
maxVOR600_MPstats_ALLYRS                    = maxVOR600_MPstats_ALLYRS .*  PW24mmMask_MPstats;
maxW600_MPstats_ALLYRS                      = maxW600_MPstats_ALLYRS .*  PW24mmMask_MPstats;
maxW600bpf_MPstats_ALLYRS                   = maxW600bpf_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanlat_MPstats_ALLYRS                      = meanlat_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanlon_MPstats_ALLYRS                      = meanlon_MPstats_ALLYRS .*  PW24mmMask_MPstats;
status_MPstats_ALLYRS                       = status_MPstats_ALLYRS .*  PW24mmMask_MPstats;
duration_MPstats_ALLYRS                     = duration_MPstats_ALLYRS .*  permute(PW24mmMask_MPstats(1,:,:),[2 3 1]);
meanMUCAPE_MPstats_ALLYRS           = meanMUCAPE_MPstats_ALLYRS .*  PW24mmMask_MPstats;
maxMUCAPE_MPstats_ALLYRS            = maxMUCAPE_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanMUCIN_MPstats_ALLYRS            = meanMUCIN_MPstats_ALLYRS .*  PW24mmMask_MPstats;
minMUCIN_MPstats_ALLYRS             = minMUCIN_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanMULFC_MPstats_ALLYRS            = meanMULFC_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanMUEL_MPstats_ALLYRS             = meanMUEL_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanPW_MPstats_ALLYRS               = meanPW_MPstats_ALLYRS .*  PW24mmMask_MPstats;
maxPW_MPstats_ALLYRS                = maxPW_MPstats_ALLYRS .*  PW24mmMask_MPstats;
minPW_MPstats_ALLYRS                = minPW_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanshearmag0to2_MPstats_ALLYRS     = meanshearmag0to2_MPstats_ALLYRS .*  PW24mmMask_MPstats;
maxshearmag0to2_MPstats_ALLYRS      = maxshearmag0to2_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanshearmag0to6_MPstats_ALLYRS     = meanshearmag0to6_MPstats_ALLYRS .*  PW24mmMask_MPstats;
maxshearmag0to6_MPstats_ALLYRS      = maxshearmag0to6_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanshearmag2to9_MPstat_ALLYRS      = meanshearmag2to9_MPstats_ALLYRS .*  PW24mmMask_MPstats;
maxshearmag2to9_MPstats_ALLYRS      = maxshearmag2to9_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanOMEGA600_MPstats_ALLYRS         = meanOMEGA600_MPstats_ALLYRS .*  PW24mmMask_MPstats;
minOMEGA600_MPstats_ALLYRS          = minOMEGA600_MPstats_ALLYRS .*  PW24mmMask_MPstats;
minOMEGAsub600_MPstats_ALLYRS       = minOMEGAsub600_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanVIWVD_MPstats_ALLYRS            = meanVIWVD_MPstats_ALLYRS .*  PW24mmMask_MPstats;
minVIWVD_MPstats_ALLYRS             = minVIWVD_MPstats_ALLYRS .*  PW24mmMask_MPstats;
maxVIWVD_MPstats_ALLYRS             = maxVIWVD_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanDIV750_MPstats_ALLYRS           = meanDIV750_MPstats_ALLYRS .*  PW24mmMask_MPstats;
minDIV750_MPstats_ALLYRS            = minDIV750_MPstats_ALLYRS .*  PW24mmMask_MPstats;
minDIVsub600_MPstats_ALLYRS         = minDIVsub600_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanWNDSPD600_MPstats_ALLYRS        = meanWNDSPD600_MPstats_ALLYRS .*  PW24mmMask_MPstats;
meanWNDDIR600_MPstats_ALLYRS        = meanWNDDIR600_MPstats_ALLYRS .*  PW24mmMask_MPstats;


%  filter the MCSspace-MP field:
filt_MPtracks_perMCS_ALLYRS  =  MPtracks_perMCS_ALLYRS;
[ww ee rr]  = size(MPtracks_perMCS_ALLYRS);
for y = 1:rr
    mplist = unique(MPtracks_perMCS_ALLYRS(:,:,y));  mplist(isnan(mplist)) = [];  mplist(mplist<1) = [];
    % if MP is dry, then set it to -1 (instead of nan)
    for m = 1:length(mplist)
        if(  isnan(PW24mmMask_MPstats(1,m,y))  )
            [drykill1,drykill2] = find(MPtracks_perMCS_ALLYRS(:,:,y)==m);
            filt_MPtracks_perMCS_ALLYRS(drykill1,drykill2,y) = -1;
        end
    end
end
MPtracks_perMCS_ALLYRS = filt_MPtracks_perMCS_ALLYRS;   clear filt_MPtracks_perMCS_ALLYRS

% pblah = PW24mmMask_MPstats(:,:,1);
% pblah2 = filt_MPtracks_perMCS_ALLYRS(:,:,1);
% pblah1 = MPtracks_perMCS_ALLYRS(:,:,1);
% find(MPtracks_perMCS_ALLYRS==-999)

disp('   ')
disp( ' Now, the original MCSstats vars are filtered on PW < 24 mm' )
disp( ' Now, the original MCSstats vars are filtered on PW < 24 mm' )
disp( ' Now, the original MCSstats vars are filtered on PW < 24 mm' )
disp('   ')



%%%% now filter some things on MPI lon starting gate:
MPtracks_perMCS_ALLYRS_MPIGATEfilt = MPtracks_perMCS_ALLYRS;
[ax bx cx] = size(MPtracks_perMCS_ALLYRS);
for t = 1:ax
    for n = 1:bx
        for y = 1:cx
            mpspresent = [];
            % y = 1; n = 200; t = 10;
            mpspresent = MPtracks_perMCS_ALLYRS(t,n,y) ;
            mpspresent(isnan(mpspresent)) = [] ;
            mpspresent(mpspresent < 1) = [] ;
            mpspresent = unique(mpspresent) ;
            if( isempty(mpspresent)==0 )
                if(  (meanlon_MPstats_ALLYRS_BEFOREfiltalldesired(1,mpspresent,y) - 360.) > -100.0   )
                    %MPtracks_perMCS_ALLYRS_MPIGATEfilt(t,n,y) = NaN ;   %%just kill the MCS times with an offending MP
                    MPtracks_perMCS_ALLYRS_MPIGATEfilt(:,n,y) = NaN ;    %%kill the MCSs for their full lives with an offending MP
                end
            end
        end
    end
end

length(  find( isnan(MPtracks_perMCS_ALLYRS) )  ) - length(  find(  isnan(MPtracks_perMCS_ALLYRS_MPIGATEfilt) )  )

%   mblah0 = mask_MP_keeperMPIGATE(:,:,1) ; 
%   mblah2 = MPtracks_perMCS_ALLYRS_MPIGATEfilt(:,:,1);
%   mblah1 = MPtracks_perMCS_ALLYRS(:,:,1);
MPtracks_perMCS_ALLYRS = MPtracks_perMCS_ALLYRS_MPIGATEfilt;


disp('   ')
disp( ' Now, the original MPs_perMCS is now MPI E of -100lon filtered!!!! ' )
disp('   ')
disp( ' Now, the original MPs_perMCS is now MPI E of -100lon filtered!!!! ' )
disp('   ')
disp( ' Now, the original MPs_perMCS is now MPI E of -100lon filtered!!!! ' )



%%%% now filter some things on MPI background wind ranging from N-E-S-W (keeping W-NW-N):
MPtracks_perMCS_ALLYRS_NWWINDfilt = MPtracks_perMCS_ALLYRS;
[ax bx cx] = size(MPtracks_perMCS_ALLYRS);
for t = 1:ax
    for n = 1:bx
        for y = 1:cx
            mpspresent = [];
            % y = 1; n = 200; t = 10;
            mpspresent = MPtracks_perMCS_ALLYRS(t,n,y) ;
            mpspresent(isnan(mpspresent)) = [] ;
            mpspresent(mpspresent < 1) = [] ;
            mpspresent = unique(mpspresent) ;
            if( isempty(mpspresent)==0 )
                if(  mean(meanWNDDIR600_MPstats_ALLYRS_BEFOREfiltalldesired(:,mpspresent,y),'omitnan') > 0  &  mean(meanWNDDIR600_MPstats_ALLYRS_BEFOREfiltalldesired(:,mpspresent,y),'omitnan') < 270. )
                    %MPtracks_perMCS_ALLYRS_NWWINDfilt(t,n,y) = NaN ;
                    MPtracks_perMCS_ALLYRS_NWWINDfilt(:,n,y) = NaN ;
                end
            end
        end
    end
end


length(  find( isnan(MPtracks_perMCS_ALLYRS) )  ) - length(  find(  isnan(MPtracks_perMCS_ALLYRS_NWWINDfilt) )  )

MPtracks_perMCS_ALLYRS = MPtracks_perMCS_ALLYRS_NWWINDfilt;

disp('   ')
disp( ' Now, the original MPs_perMCS is now nonNW wind filtered!!!! ' )
disp('   ')
disp( ' Now, the original MPs_perMCS is now nonNW wind filtered!!!! ' )
disp('   ')
disp( ' Now, the original MPs_perMCS is now nonNW wind filtered!!!! ' )












%need to filter MP_with_MCS on noLS & PW24 thresholds
%  MP_with_MCSs_ALLYRS_before = MP_with_MCSs_ALLYRS;
%  MP_without_MCSs_ALLYRS_before = MP_without_MCSs_ALLYRS;

%  MP_with_MCSs_ALLYRS =   MP_with_MCSs_ALLYRS_before;
%wrong:
% for y = 1:MP_years
%     for n = 1:MP_tracks
%         if( isnan(mask_kill_mp_because_LS_present(n,y))  )  %  &    meanPW_MPstats_ALLYRS(n,y) >= 24.0  )
%             MP_with_MCSs_ALLYRS(n,y) = NaN;
%             MP_without_MCSs_ALLYRS(n,y) = NaN;
%         end
%     end
% end
% for y = 1:MP_years
%     for n = 1:MP_tracks
%         if(  mean(meanPW_MPstats_ALLYRS(:,n,y),'omitnan') < 24.0  ) % PW is noLS filtered (not pw24, fwiw, but i dont think it matters)
%             MP_with_MCSs_ALLYRS(n,y) = NaN;
%             MP_without_MCSs_ALLYRS(n,y) = NaN;
%         end
%     end
% end
%corrected:
%corrected:
[fg fh] = size(MP_with_MCSs_ALLYRS);
for y = 1:fh
    for n = 1:fg

        mp =  MP_with_MCSs_ALLYRS(n,y) ;
        if( isnan(mp)==0   &   isnan( mask_kill_mp_because_LS_present(mp,y) )    )  
            MP_with_MCSs_ALLYRS(n,y) = NaN;
        end

        mp =  MP_without_MCSs_ALLYRS(n,y) ;
        if( isnan(mp)==0   &   isnan( mask_kill_mp_because_LS_present(mp,y) )    )  
            MP_without_MCSs_ALLYRS(n,y) = NaN;
        end

    end
end

%m1 = MP_with_MCSs_ALLYRS;

[fg fh] = size(MP_with_MCSs_ALLYRS);
for y = 1:fh
    for n = 1:fg
        %n = 40; y = 1; n = 1
        mp =  MP_with_MCSs_ALLYRS(n,y) ;
        if( isnan(mp)==0   &     mean(   meanPW_MPstats_ALLYRS(:,mp,y), 'omitnan'   ) < 24.0        )  
            MP_with_MCSs_ALLYRS(n,y) = NaN;
        end
        if( isnan(mp)==0   &  isnan( mean(   meanPW_MPstats_ALLYRS(:,mp,y), 'omitnan'   ) )        )  
            MP_with_MCSs_ALLYRS(n,y) = NaN;
        end

        mp =  MP_without_MCSs_ALLYRS(n,y) ;
        if( isnan(mp)==0   &     mean(   meanPW_MPstats_ALLYRS(:,mp,y), 'omitnan'   ) < 24.0        )  
            MP_without_MCSs_ALLYRS(n,y) = NaN;
        end
        if( isnan(mp)==0   &  isnan( mean(   meanPW_MPstats_ALLYRS(:,mp,y), 'omitnan'   ) )        )  
            MP_without_MCSs_ALLYRS(n,y) = NaN;
        end

    end
end

%m2 = MP_with_MCSs_ALLYRS;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 1) plot origins of MP features present during MCSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


MPatMCSI_perMCS_ALLYRS = zeros(2,mcs_tracks,mcs_years) ;  % list of MP object numbers present at each MCS's initiation period (first 2 hrs)
mcsibasetime_perMCS_ALLYRS = zeros(2,mcs_tracks,mcs_years) ;   % list of basetimes for MCSI (because of the occassional NaN offsets in MCS tracks.

% "adjust" for the confusing NaN at the firest few times of mcs track when IDing mcsi time/MP presence
% - look in first 5 times of MCS track and pick the first 2 times in each MCS's track that are not NAN to cal the MCSI period: 

for y = 1:mcs_years
    for n = 1:mcs_tracks
        
      %  y = 4;  n = 273;
      
       %look in first 5 times of MCS for not nans
      notnan = find( isnan(MPtracks_perMCS_ALLYRS(1:5,n,y)) ==0 );  
      
      if( length(notnan) > 1 ) % if there is more than one non-nan:
          
      	MPatMCSI_perMCS_ALLYRS(1:2,n,y) =  MPtracks_perMCS_ALLYRS(notnan(1:2),n,y)  ; 
        mcsibasetime_perMCS_ALLYRS(1:2,n,y)   =  basetime_MCSstats_ALLYRS(notnan(1:2),n,y)  ;
            
      elseif( length(notnan) == 1) % if there is only one non-nan in first 5 times
          
      	MPatMCSI_perMCS_ALLYRS(1,n,y) =  MPtracks_perMCS_ALLYRS(notnan(1),n,y)  ;
        mcsibasetime_perMCS_ALLYRS(1,n,y) = basetime_MCSstats_ALLYRS(notnan(1),n,y);
        MPatMCSI_perMCS_ALLYRS(2,n,y) =  NaN  ;  
        mcsibasetime_perMCS_ALLYRS(2,n,y) = NaN;
        
      else  % length(notnan) == 0); % if there are no non-nans in first 5 times
      
      	MPatMCSI_perMCS_ALLYRS(1:2,n,y) =  NaN ;   
        mcsibasetime_perMCS_ALLYRS(1:2,n,y) = NaN;
          
      end
      
    end
end


%  mblah = MPatMCSI_perMCS_ALLYRS(:,:,4)

%   blah_mcs = datetime( basetime_MCSstats_ALLYRS( notnan(1:2),n,y ), 'convertfrom','posixtime','Format','dd-MM-y-HH') 
%   blah_mcs = datetime( basetime_MCSstats_ALLYRS( :,n,y ), 'convertfrom','posixtime','Format','dd-MM-y-HH') 







% % tabulate UNIQUE MP obj origin locations for those present at MCSI (no repeats if there are multiple MCSs with same MP)
% unique_MP_origin_lons = [];
% unique_MP_origin_lats = [];
% unique_MP_full_lats = [];
% unique_MP_full_lons = [];
%     
% for y = 1:mcs_years
% 
%     % y = 1
%     
%     %unique syn objs numbers per year
%     syns = MPatMCSI_perMCS_ALLYRS(:,:,y);
%     uniq_syn = unique( syns( find( syns ) ) );    uniq_syn(uniq_syn < 0) = [];   uniq_syn(isnan(uniq_syn)) = [];  
%    
% %     %identify a syn object present at this MCS's birth:
% %     MPtr = MPatMCSI_perMCS_ALLYRS(:,n,y)  ;  %synoptic track number present at MCSI
% %     mpnums = vertcat(mpnums,MPtr) ;
%     
%     %tabulate lats/lons for the uniques syn tracks:
%     for n = 1:length(uniq_syn)
%         %tabulated lat/lons of syn object origins that initiate MCSs for use in hostograms later:
%         unique_MP_origin_lons = vertcat( unique_MP_origin_lons, meanlon_MPstats_ALLYRS(1,uniq_syn(n),y) );
%         unique_MP_origin_lats = vertcat( unique_MP_origin_lats, meanlat_MPstats_ALLYRS(1,uniq_syn(n),y) );
%         
%         unique_MP_full_lats = vertcat( unique_MP_full_lats, meanlat_MPstats_ALLYRS(:,uniq_syn(n),y) );
%         unique_MP_full_lons = vertcat( unique_MP_full_lons, meanlon_MPstats_ALLYRS(:,uniq_syn(n),y) );
%         
%     end
% end




% tabulate NON-UNIQUE MP obj origin locations for MPs present at MCSI (i.e., allow repeated MD numbers if they are present at multiple MCSI events - but not double counted per MCS. 
% But I do allow if two different MPs are present in one MCSI period)
NONunique_MP_origin_lons = [];
NONunique_MP_origin_lats = [];

for y = 1:mcs_years
    synsperyr = [];
    % y = 1  ;
    for n = 1:mtracks
        % y = 1; n = 190
        %unique MP objs numbers per MCS in this year
        syns = MPatMCSI_perMCS_ALLYRS(:,n,y) ;
        syns = unique( syns( find( syns ) ) );  syns(syns < 0) = [];   syns(isnan(syns)) = [];
        if(  isempty(syns) == 0  )
            for wer = 1:length(syns) % in case there are two MDs inan MCSI period
                synsperyr = vertcat( synsperyr, syns(wer));
            end
        end
    end
    
    % tabulate lats/lons for thee uniques syn tracks:
    for n = 1:length(synsperyr)
        %tabulated lat/lons of syn object origins that initiate MCSs for use in hostograms later:
        NONunique_MP_origin_lons = vertcat( NONunique_MP_origin_lons, meanlon_MPstats_ALLYRS(1,synsperyr(n),y) );
        NONunique_MP_origin_lats = vertcat( NONunique_MP_origin_lats, meanlat_MPstats_ALLYRS(1,synsperyr(n),y) );
    end
    
end



% % tabulate UNIQUE (nosynoptic obj origin locations 
% syn_origin_lons = [];
% syn_origin_lats = [];
% 
% for y = 1:mcs_years
%     % y = 1
%     %syn objs numbers per year; diagnostics to see if there are duplicates
%     mpnums = []; 
%     for n = 1:mtracks
%         for cit = 1:2   
%             
%             % if there is a syn object present at MCSi, find it's origin lat/lon
%             if( MPatMCSI_perMCS_ALLYRS(cit,n,y) > 0)  
%                 
%                 %identify a syn object present at this MCS's birth:
%                 MPtr = MPatMCSI_perMCS_ALLYRS(cit,n,y)  ;  %synoptic track number present at MCSI
%                 mpnums = vertcat(mpnums,MPtr) ;
%                 
%                 %tabulated lat/lons of syn object origins that initiate MCSs for use in hostograms later:
%                 syn_origin_lons = vertcat( syn_origin_lons, meanlon_MPstats_ALLYRS(1,MPtr,y) );
%                 syn_origin_lats = vertcat( syn_origin_lats, meanlat_MPstats_ALLYRS(1,MPtr,y) );
%                 
%             end
%             
%         end
%         
%     end
% end


figure; plot(totalheavyrain_MCSstats_ALLYRS(:),'ok')


dualpol_colmap



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 2) repeat syn origins but as 2d histogram - still trying to make this
%%% work
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% plot(polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% origins = [syn_origin_lons-360,syn_origin_lats];
% hist3(origins,'Nbins',[30,15],'CDataMode','auto','FaceColor','interp');
% colormap(flipud(creamsicle2))   %colormap(flipud(gray))
% caxis([0 max(max(hist3(origins,'Nbins',[30,30],'CDataMode','auto','FaceColor','interp'))) ])
% colorbar
% view(0,90)
% hold on
% load coastlines
% plot(coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% load topo topo 
% highelev = topo ;
% highelev(topo < 1300) = NaN;
% contour([0 : 359]-360 , [-89 : 90], highelev, [1300 5000] , 'FaceColor', [0.4 0.2 0])
% hold on
% plot(-105.27,40.01,'k^')
% title([' Origin locations of Synoptic objects that are eventually present during MCSI '])
% axis([-170 -50 15 65])



% 
% ff = figure  
% ff.Position = [2204,414,845,395];
% 
% set(gca,'XTick',[])
% set(gca,'YTick',[])
% 
% title([' Unique origin locations of MP objects present during MCSI. filtLS=',num2str(filteroutLS)])
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% ax4 = axes; 
% ax5 = axes;
% linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% origins = [unique_MP_origin_lons-360,unique_MP_origin_lats];
% length(isnan(unique_MP_origin_lons-360)==0)
% 
% %histogram2(ax2,syn_origin_lons-360,syn_origin_lats,'NumBins',[30,15],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(ax2,unique_MP_origin_lons-360,unique_MP_origin_lats,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 20])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0 0.7 0]);  
% 
% 
% % %overlay density kernel of MCSIs with syn obs   - not defined until later (developed/ran code out of order)
% % [pdfx xi]= ksdensity(MCSI_withMP_lon);
% % [pdfy yi]= ksdensity(MCSI_withMP_lat);
% % [xxi,yyi]     = meshgrid(xi,yi);
% % [pdfxx,pdfyy] = meshgrid(pdfx,pdfy);
% % pdfxy = pdfxx.*pdfyy; 
% % contour(ax5,xxi,yyi,pdfxy,8,'--r','LineWidth',0.5)
% 
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% set(ax4,'Color','None')       %p
% set(ax4, 'visible', 'off');   %p
% 
% set(ax5,'Color','None')       %p
% set(ax5, 'visible', 'off');   %p
% 
% xlabel(ax1,'latitude')
% ylabel(ax1,'longitude')
% 
% %axis([-170 -50 20 60])
% axis([-140 -60 20 60])
% 
% %%%%%%%% image out:
% 
% saveas(ff,horzcat(imout,'/MPOrigins_AtMCSI_filtLS',num2str(filteroutLS),'.png'));
% 
% outlab = horzcat(imout,'/MPOrigins_AtMCSI_filtLS',num2str(filteroutLS),'.eps');
% EPSprint = horzcat('print -painters -depsc ',outlab);
% eval([EPSprint]);
% 
% 
% 
% 
% 
% 
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%  same thing but looking at full lifetime of MP
% %%%%%%%%%%%%%%%%%%%  objects rather than just MP-I locations: 
% 
% 
% ff = figure  
% ff.Position = [2204,414,845,395];
% 
% set(gca,'XTick',[])
% set(gca,'YTick',[])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% ax4 = axes; 
% ax5 = axes;
% linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% origins = [unique_MP_full_lons-360,unique_MP_full_lats];
% length(isnan(unique_MP_full_lats-360)==0)
% 
% %histogram2(ax2,syn_origin_lons-360,syn_origin_lats,'NumBins',[30,15],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(ax2,unique_MP_full_lons-360,unique_MP_full_lats,[-180:1:-50],[20:1:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 100])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0 0.7 0]);  
% 
% % %overlay density kernel of MCSIs with syn obs   --- not defined until later (out of order)
% % [pdfx xi]= ksdensity(MCSI_withMP_lon);
% % [pdfy yi]= ksdensity(MCSI_withMP_lat);
% % [xxi,yyi]     = meshgrid(xi,yi);
% % [pdfxx,pdfyy] = meshgrid(pdfx,pdfy);
% % pdfxy = pdfxx.*pdfyy; 
% % contour(ax5,xxi,yyi,pdfxy,8,'--r','LineWidth',0.5)
% 
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% set(ax4,'Color','None')       %p
% set(ax4, 'visible', 'off');   %p
% 
% set(ax5,'Color','None')       %p
% set(ax5, 'visible', 'off');   %p
% 
% xlabel(ax1,'latitude')
% ylabel(ax1,'longitude')
% 
% %axis([-170 -50 20 60])
% axis([-140 -60 20 60])
% title([' Unique full track locations of MPs that are eventually present during MCSI '])
% 
% %%%%%%%% image out:
% 
% %saveas(ff,horzcat(imout,'/MPfulltacks_AtMCSI_filtLS',num2str(filteroutLS),'.png'));
% 
% outlab = horzcat(imout,'/MPfulltacks_AtMCSI_filtLS',num2str(filteroutLS),'.eps');
% EPSprint = horzcat('print -painters -depsc ',outlab);
% eval([EPSprint]);











% next, reconcile these (below) with (NON)unique_origin_lats size:



%generate list of MCS numbers with MP objs present at MCSI:

MCSI_with_MP = [];
MCSI_without_MP = [];
MCSI_withMP_lon = [];
MCSI_withMP_lat = [];
MCSI_withoutMP_lon = [];
MCSI_withoutMP_lat = [];

%mcs numbers with MPs (not) present at MCSI
MCSI_with_MP_ALLYRS = zeros(mcs_tracks,mcs_years);    MCSI_with_MP_ALLYRS(:,:) = NaN;
MCSI_without_MP_ALLYRS = zeros(mcs_tracks,mcs_years); MCSI_without_MP_ALLYRS(:,:) = NaN;

%note, this loop should inherently skip dud MCSs (that have an all-NaN records during their full lifetime) because it's looking for >. This includes those filtered by LSs
MCSI_with_multiMP = [];
for y = 1:mcs_years
    for n = 1:mcs_tracks
        
        %   n = 336;  y = 1;
        if(  MPatMCSI_perMCS_ALLYRS(1,n,y) > 0 | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0    ) %tabulate all of the MCSs with MP object present at birth
        %if(  MPatMCSI_perMCS_ALLYRS(1,n,y) > 1 | MPatMCSI_perMCS_ALLYRS(2,n,y) > 1    ) %tabulate all of the MCSs with MP object present at birth

            clear unis
            unis = unique(MPatMCSI_perMCS_ALLYRS(1:2,n,y) ) ;    unis(unis == -1) = [];     unis(unis == NaN) = [];
            MCSI_with_MP_ALLYRS(n,y) =  unis(1) ;  % MP obj number present at MCSI for each MCS obj (in MCS format) - picking the first if there are multiples (THIS MAY/MAYNOT THE IDEAL WAY BUT NOT SURE HOW TO HANDLE THIS IF MORE THAN ONE - WHICH I DONT THINK IS COMMON)
            
            for g = 1:length(unis)
                MCSI_with_multiMP = vertcat(MCSI_with_multiMP,unis(g));
            end
            
            MCSI_with_MP = vertcat(MCSI_with_MP,n);
            MCSI_withMP_lon = vertcat( MCSI_withMP_lon, meanlon_MCSstats_ALLYRS(1,n,y) ) ;
            MCSI_withMP_lat = vertcat( MCSI_withMP_lat, meanlat_MCSstats_ALLYRS(1,n,y) ) ;
            
        elseif(MPatMCSI_perMCS_ALLYRS(1,n,y) < 0 & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0 )  %tabulate all of the MCSs without MP object present at birth
            
            MCSI_without_MP_ALLYRS(n,y) = 1;
            MCSI_without_MP = vertcat(MCSI_without_MP,n);
            MCSI_withoutMP_lon = vertcat( MCSI_withoutMP_lon, meanlon_MCSstats_ALLYRS(1,n,y) ) ;
            MCSI_withoutMP_lat = vertcat( MCSI_withoutMP_lat, meanlat_MCSstats_ALLYRS(1,n,y) ) ;

        end
    end
end



% change these to use MP/LS per MCS fields rather than duration? 

%numMCSI_with_LS = length(find(isnan(duration_MCSstats_ALLYRS_YESLS)==0))
%numMCSI_without_LS = length(find(isnan(duration_MCSstats_ALLYRS_NOLS)==0))
%num_all_MCSI = numMCSI_with_LS + numMCSI_without_LS

% length(MCSI_without_MP) +  length(MCSI_with_MP)  % 
% length(MCSI_without_MP)   % 
% length(MCSI_with_MP)      % size not allowing multiple MDs present at MCSI
% length(MCSI_with_multiMP) % size allowing multiple MDs present at MCSI events




% %%%%%%%%%%%%   mapped histogram of MCSI locations with MP object present
% 
% ff = figure  
% ff.Position = [2008,332,683,428];
% 
% title([' Locations of MCSI events that have MP objects present'])
% 
% set(gca,'XTick',[])
% set(gca,'YTick',[])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% ax4 = axes;
% % ax5 = axes;
% linkaxes([ax1,ax2,ax3,ax4],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% 
% histogram2(ax2, MCSI_withMP_lon, MCSI_withMP_lat,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% cb = colormap(ax2,flipud(creamsicle2)) 
% caxis(ax2,[1 25])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% 
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] , 'LineColor', [0 0.7 0] , 'LineWidth', 1.25 ) %'FaceColor', 'k')%'none','LineColor','k')
% 
% plot(ax4,mean(mean(MCSI_withMP_lon,'omitnan')),mean(mean(MCSI_withMP_lat,'omitnan')),'xr')
% 
% % % overlay density kernel of MCSIs with MP obs 
% % [pdfx xi]= ksdensity(MCSI_withMP_lon);
% % [pdfy yi]= ksdensity(MCSI_withMP_lat);
% % [xxi,yyi]     = meshgrid(xi,yi);
% % [pdfxx,pdfyy] = meshgrid(pdfx,pdfy);
% % pdfxy = pdfxx.*pdfyy; 
% % contour(ax5,xxi,yyi,pdfxy,20,'--r','LineWidth',0.5)
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% set(ax4,'Color','None')       %p
% set(ax4, 'visible', 'off');   %p
% 
% % set(ax5,'Color','None')       %p
% % set(ax5, 'visible', 'off');   %p
% 
% xlabel(ax1,'latitude')
% ylabel(ax1,'longitude')
% 
% axis([-125 -70 25 55])
% 
% %%%%%%%% image out:
% 
% %saveas(ff,horzcat(imout,'/MCSIorigins_withMP.png'));
% 
% outlab = horzcat(imout,'/MCSIorigins_withMP_filtLS',num2str(filteroutLS),'.eps');
% EPSprint = horzcat('print -painters -depsc ',outlab);
% eval([EPSprint]);














% %%%%%%%%%%%%   mapped histogram of MCSI locations without MP object present
% 
% ff = figure  
% ff.Position = [2008,332,683,428];
% 
% set(gca,'XTick',[])
% set(gca,'YTick',[])
% 
% title([' Locations of MCSI events that DO NOT have MP objects present'])
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% ax4 = axes; 
% linkaxes([ax1, ax2, ax3, ax4],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% edges1 = [-180:3:-50];  edges2 = [20:3:60];
% 
% kill = find(  isnan(MCSI_withoutMP_lon));
% MCSI_withoutMP_lon(kill) = [];
% MCSI_withoutMP_lat(kill) = [];
% kill = find(  isnan(MCSI_withoutMP_lat));
% MCSI_withoutMP_lon(kill) = [];
% MCSI_withoutMP_lat(kill) = [];
% combined = horzcat(MCSI_withoutMP_lon,MCSI_withoutMP_lat);
% combinedsort = sortrows(combined,2);
% MCSI_withoutMP_lon_sort = combinedsort(:,1);
% MCSI_withoutMP_lat_sort = combinedsort(:,2);
% NC = histcounts2( MCSI_withoutMP_lon_sort, MCSI_withoutMP_lat_sort, edges1,edges2  ) / (2021-2004+1) ;
% centers1 = [  mean(edges1(1:2))   :  ( mean(edges1(2:3)) - mean(edges1(1:2)) )   :  mean(edges1(end-1:end))  ] ; 
% centers2 = [  mean(edges2(1:2))   :  ( mean(edges2(2:3)) - mean(edges2(1:2)) )   :  mean(edges2(end-1:end))  ] ; 
% contourf(ax2,centers1,centers2,NC',12,'k','LineColor','none')
% colormap(ax2,flipud(creamsicle2))
% caxis(ax2,[0 max(max(NC))])
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% set(cb,'YTick',[0:max(max(NC))/5:max(max(NC))])
% hold on
% 
% load coastlines
% %plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% states = readgeotable("usastatehi.shp");
% states{:,4} = states{:,4}
% geoshow(states,'facecolor', 'none', 'DefaultEdgeColor', [0 0.5 1])
% borders("Canada",'Color', [0 0.5 1])
% borders("Mexico",'Color', [0 0.5 1])
% borders("Cuba",'Color', [0 0.5 1])
% 
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] , 'LineColor', [0 0.7 0] , 'LineWidth', 1.25 ) %'FaceColor', 'k')%'none','LineColor','k')
%     
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% set(ax4,'Color','None')       %p
% set(ax4, 'visible', 'off');   %p
% 
% xlabel(ax1,'latitude')
% ylabel(ax1,'longitude')
% 
% axis([-125 -70 25 55])
% 
% 
% 
% 
% %%% normalize
% 
% ff = figure  
% ff.Position = [2008,332,683,428];
% 
% set(gca,'XTick',[])
% set(gca,'YTick',[])
% 
% title([' Locations of MCSI events that DO NOT have MP objects present'])
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% ax4 = axes; 
% linkaxes([ax1, ax2, ax3, ax4],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% edges1 = [-180:3:-50];  edges2 = [20:3:60];
% 
% kill = find(  isnan(MCSI_withoutMP_lon));
% MCSI_withoutMP_lon(kill) = [];
% MCSI_withoutMP_lat(kill) = [];
% kill = find(  isnan(MCSI_withoutMP_lat));
% MCSI_withoutMP_lon(kill) = [];
% MCSI_withoutMP_lat(kill) = [];
% combined = horzcat(MCSI_withoutMP_lon,MCSI_withoutMP_lat);
% combinedsort = sortrows(combined,2);
% MCSI_withoutMP_lon_sort = combinedsort(:,1);
% MCSI_withoutMP_lat_sort = combinedsort(:,2);
% NC = histcounts2( MCSI_withoutMP_lon_sort, MCSI_withoutMP_lat_sort, edges1,edges2  ) / (2021-2004+1) ;
% NC = NC/max(max(NC));
% centers1 = [  mean(edges1(1:2))   :  ( mean(edges1(2:3)) - mean(edges1(1:2)) )   :  mean(edges1(end-1:end))  ] ; 
% centers2 = [  mean(edges2(1:2))   :  ( mean(edges2(2:3)) - mean(edges2(1:2)) )   :  mean(edges2(end-1:end))  ] ; 
% contourf(ax2,centers1,centers2,NC',12,'k','LineColor','none')
% colormap(ax2,flipud(creamsicle2))
% caxis(ax2,[0 1])
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% set(cb,'YTick',[0:1/5:1])
% hold on
% 
% load coastlines
% %plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% states = readgeotable("usastatehi.shp");
% states{:,4} = states{:,4}
% geoshow(states,'facecolor', 'none', 'DefaultEdgeColor', [0 0.5 1])
% borders("Canada",'Color', [0 0.5 1])
% borders("Mexico",'Color', [0 0.5 1])
% borders("Cuba",'Color', [0 0.5 1])
% 
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] , 'LineColor', [0 0.7 0] , 'LineWidth', 1.25 ) %'FaceColor', 'k')%'none','LineColor','k')
%     
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% set(ax4,'Color','None')       %p
% set(ax4, 'visible', 'off');   %p
% 
% xlabel(ax1,'latitude')
% ylabel(ax1,'longitude')
% 
% axis([-125 -70 25 55])
% %%%%%%%% image out:
% 
% %saveas(ff,horzcat(imout,'/MCSIorigins_withoutMP.png'));
% 
% outlab = horzcat(imout,'/MCSIorigins_withoutMP_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps') ;
% EPSprint = horzcat('print -painters -depsc ',outlab);
% eval([EPSprint]);



% %%%%%%%%%%%%%%%%
% %%% are MCSI locations with and without MP objs statistically different?
% %%%%%%%%%%%%%%%%
% 
% length( isnan(MCSI_withoutMP_lon(:)==0 ) )
% 
% median(MCSI_withMP_lon(:),'omitnan')
% median(MCSI_withoutMP_lon(:),'omitnan') 
% 
% alvl = 0.05;
% [sh,p] = kstest2(MCSI_withMP_lon(:),MCSI_withoutMP_lon(:),'Alpha',alvl) 
% [p2,sh2] = ranksum(MCSI_withMP_lon(:),MCSI_withoutMP_lon(:),'Alpha',alvl)
% 
% median(MCSI_withMP_lat(:),'omitnan') 
% median(MCSI_withoutMP_lat(:),'omitnan')
% 
% [sh,p] = kstest2(MCSI_withMP_lat(:),MCSI_withoutMP_lat(:),'Alpha',alvl) 
% [p2,sh2] = ranksum(MCSI_withMP_lat(:),MCSI_withoutMP_lat(:),'Alpha',alvl)








% %%%%%%%%%%%%   mapped histogram of all MCSI locations
% ff = figure  
% ff.Position = [2008,332,683,428];
% 
% title([' Locations of all MCSI events. filtLS=',num2str(filteroutLS)])
% 
% set(gca,'XTick',[])
% set(gca,'YTick',[])
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% ax4 = axes; 
% linkaxes([ax1, ax2, ax3, ax4],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% edges1 = [-180:3:-50];  edges2 = [20:3:60];
% 
% lon1 = meanlon_MCSstats_ALLYRS(1,:,:);    lat1 = meanlat_MCSstats_ALLYRS(1,:,:); 
% lon1 = lon1(:);   lat1 = lat1(:);
% 
% kill = find(  isnan(lon1));
% lon1(kill) = [];
% lat1(kill) = [];
% kill = find(  isnan(lat1));
% lon1(kill) = [];
% lat1(kill) = [];
% combined = horzcat(lon1,lat1);
% combinedsort = sortrows(combined,2);
% lon1_sort = combinedsort(:,1);
% lat1_sort = combinedsort(:,2);
% NC = histcounts2( lon1_sort, lat1_sort, edges1, edges2  ) / (2021-2004+1) ;
% centers1 = [  mean(edges1(1:2))   :  ( mean(edges1(2:3)) - mean(edges1(1:2)) )   :  mean(edges1(end-1:end))  ] ; 
% centers2 = [  mean(edges2(1:2))   :  ( mean(edges2(2:3)) - mean(edges2(1:2)) )   :  mean(edges2(end-1:end))  ] ; 
% 
% contourf(ax2,centers1,centers2,NC',12,'k','LineColor','none')
% colormap(ax2,flipud(creamsicle2))
% caxis(ax2,[0 max(max(NC))])
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% set(cb,'YTick',[0:max(max(NC))/5:max(max(NC))])
% hold on
% 
% load coastlines
% %plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% states = readgeotable("usastatehi.shp");
% states{:,4} = states{:,4}
% geoshow(states,'facecolor', 'none', 'DefaultEdgeColor', [0 0.5 1])
% borders("Canada",'Color', [0 0.5 1])
% borders("Mexico",'Color', [0 0.5 1])
% borders("Cuba",'Color', [0 0.5 1])
% 
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] , 'LineColor', [0 0.7 0] , 'LineWidth', 1.25 ) %'FaceColor', 'k')%'none','LineColor','k')
%     
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% set(ax4,'Color','None')       %p
% set(ax4, 'visible', 'off');   %p
% 
% xlabel(ax1,'latitude')
% ylabel(ax1,'longitude')
% 
% axis([-125 -70 25 55])
% 
% 
% length( isnan( meanlon_MCSstats_ALLYRS(1,:,:) )==0 )
% 
% 
% %%%%%%%%%% normalized
% 
% ff = figure  
% ff.Position = [2008,332,683,428];
% 
% title([' Locations of all MCSI events. filtLS=',num2str(filteroutLS)])
% 
% set(gca,'XTick',[])
% set(gca,'YTick',[])
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% ax4 = axes; 
% linkaxes([ax1, ax2, ax3, ax4],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% edges1 = [-180:3:-50];  edges2 = [20:3:60];
% 
% lon1 = meanlon_MCSstats_ALLYRS(1,:,:);    lat1 = meanlat_MCSstats_ALLYRS(1,:,:); 
% lon1 = lon1(:);   lat1 = lat1(:);
% 
% kill = find(  isnan(lon1));
% lon1(kill) = [];
% lat1(kill) = [];
% kill = find(  isnan(lat1));
% lon1(kill) = [];
% lat1(kill) = [];
% combined = horzcat(lon1,lat1);
% combinedsort = sortrows(combined,2);
% lon1_sort = combinedsort(:,1);
% lat1_sort = combinedsort(:,2);
% NC = histcounts2( lon1_sort, lat1_sort, edges1, edges2  ) / (2021-2004+1) ;
% centers1 = [  mean(edges1(1:2))   :  ( mean(edges1(2:3)) - mean(edges1(1:2)) )   :  mean(edges1(end-1:end))  ] ; 
% centers2 = [  mean(edges2(1:2))   :  ( mean(edges2(2:3)) - mean(edges2(1:2)) )   :  mean(edges2(end-1:end))  ] ; 
% NC = NC/max(max(NC));
% contourf(ax2,centers1,centers2,NC',12,'k','LineColor','none')
% colormap(ax2,flipud(creamsicle2))
% caxis(ax2,[0 1])
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% set(cb,'YTick',[0:1/5:1])
% hold on
% 
% load coastlines
% %plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% states = readgeotable("usastatehi.shp");
% states{:,4} = states{:,4}
% geoshow(states,'facecolor', 'none', 'DefaultEdgeColor', [0 0.5 1])
% borders("Canada",'Color', [0 0.5 1])
% borders("Mexico",'Color', [0 0.5 1])
% borders("Cuba",'Color', [0 0.5 1])
% 
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] , 'LineColor', [0 0.7 0] , 'LineWidth', 1.25 ) %'FaceColor', 'k')%'none','LineColor','k')
%     
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% set(ax4,'Color','None')       %p
% set(ax4, 'visible', 'off');   %p
% 
% xlabel(ax1,'latitude')
% ylabel(ax1,'longitude')
% 
% axis([-125 -70 25 55])
% 
% 
% %%%%%%%% image out:
% 
% %saveas(ff,horzcat(imout,'/MCSIorigins_allevents_filtLS',num2str(filteroutLS),'.png'));
% 
% outlab = horzcat(imout,'/MCSIorigins_allevents_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps') ;
% EPSprint = horzcat('print -painters -depsc ',outlab);
% eval([EPSprint]);









%{
if(  filteroutLS ==  1)


    %%%%%%%%%%%%   mapped histogram of all MCSI locations


    ff = figure
    ff.Position = [2008,332,683,428];

    title([' Locations of all MCSI events with LSs '])

    set(gca,'XTick',[])
    set(gca,'YTick',[])
    ax1 = axes;
    ax2 = axes;
    ax3 = axes;
    ax4 = axes;
    linkaxes([ax1, ax2, ax3, ax4],'xy');

    plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
    hold on

    edges1 = [-180:3:-50];  edges2 = [20:3:60];

    lon1 = meanlon_MCSstats_ALLYRS_YESLS(1,:,:);    lat1 = meanlat_MCSstats_ALLYRS_YESLS(1,:,:);
    lon1 = lon1(:);   lat1 = lat1(:);

    kill = find(  isnan(lon1));
    lon1(kill) = [];
    lat1(kill) = [];
    kill = find(  isnan(lat1));
    lon1(kill) = [];
    lat1(kill) = [];
    combined = horzcat(lon1,lat1);
    combinedsort = sortrows(combined,2);
    lon1_sort = combinedsort(:,1);
    lat1_sort = combinedsort(:,2);
    NC = histcounts2( lon1_sort, lat1_sort, edges1, edges2  ) / (2021-2004+1) ;
    centers1 = [  mean(edges1(1:2))   :  ( mean(edges1(2:3)) - mean(edges1(1:2)) )   :  mean(edges1(end-1:end))  ] ;
    centers2 = [  mean(edges2(1:2))   :  ( mean(edges2(2:3)) - mean(edges2(1:2)) )   :  mean(edges2(end-1:end))  ] ;
    contourf(ax2,centers1,centers2,NC',12,'k','LineColor','none')
    colormap(ax2,flipud(creamsicle2))
    caxis(ax2,[0 max(max(NC))])
    cb = colorbar(ax2)
    agr=get(cb); %gets properties of colorbar
    aa = agr.Position; %gets the positon and size of the color bar
    set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
    set(cb,'YTick',[0:max(max(NC))/5:max(max(NC))])
    hold on

    load coastlines
    %plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);
    states = readgeotable("usastatehi.shp");
    states{:,4} = states{:,4}
    geoshow(states,'facecolor', 'none', 'DefaultEdgeColor', [0 0.5 1])
    borders("Canada",'Color', [0 0.5 1])
    borders("Mexico",'Color', [0 0.5 1])
    borders("Cuba",'Color', [0 0.5 1])

    hold on

    load topo topo
    highelev = topo ;
    highelev(topo < 1500) = 0;
    contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] , 'LineColor', [0 0.7 0] , 'LineWidth', 1.25 ) %'FaceColor', 'k')%'none','LineColor','k')

    set(ax2,'Color','None')       %p
    set(ax2, 'visible', 'off');   %p

    set(ax3,'Color','None')       %p
    set(ax3, 'visible', 'off');   %p

    set(ax4,'Color','None')       %p
    set(ax4, 'visible', 'off');   %p

    xlabel(ax1,'latitude')
    ylabel(ax1,'longitude')

    axis([-125 -70 25 55])


    length( isnan(meanlon_MCSstats_ALLYRS_YESLS(1,:,:) )==0)


    %%%%%% normalized
    ff = figure
    ff.Position = [2008,332,683,428];

    title([' Locations of all MCSI events with LSs '])

    set(gca,'XTick',[])
    set(gca,'YTick',[])
    ax1 = axes;
    ax2 = axes;
    ax3 = axes;
    ax4 = axes;
    linkaxes([ax1, ax2, ax3, ax4],'xy');

    plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
    hold on

    edges1 = [-180:3:-50];  edges2 = [20:3:60];

    lon1 = meanlon_MCSstats_ALLYRS_YESLS(1,:,:);    lat1 = meanlat_MCSstats_ALLYRS_YESLS(1,:,:);
    lon1 = lon1(:);   lat1 = lat1(:);

    kill = find(  isnan(lon1));
    lon1(kill) = [];
    lat1(kill) = [];
    kill = find(  isnan(lat1));
    lon1(kill) = [];
    lat1(kill) = [];
    combined = horzcat(lon1,lat1);
    combinedsort = sortrows(combined,2);
    lon1_sort = combinedsort(:,1);
    lat1_sort = combinedsort(:,2);
    NC = histcounts2( lon1_sort, lat1_sort, edges1, edges2  ) / (2021-2004+1) ;
    NC = NC/max(max(NC));
    centers1 = [  mean(edges1(1:2))   :  ( mean(edges1(2:3)) - mean(edges1(1:2)) )   :  mean(edges1(end-1:end))  ] ;
    centers2 = [  mean(edges2(1:2))   :  ( mean(edges2(2:3)) - mean(edges2(1:2)) )   :  mean(edges2(end-1:end))  ] ;
    contourf(ax2,centers1,centers2,NC',12,'k','LineColor','none')
    colormap(ax2,flipud(creamsicle2))
    caxis(ax2,[0 max(max(NC))])
    cb = colorbar(ax2)
    agr=get(cb); %gets properties of colorbar
    aa = agr.Position; %gets the positon and size of the color bar
    set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
    set(cb,'YTick',[0:1/5:1])
    hold on

    load coastlines
    %plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);
    states = readgeotable("usastatehi.shp");
    states{:,4} = states{:,4}
    geoshow(states,'facecolor', 'none', 'DefaultEdgeColor', [0 0.5 1])
    borders("Canada",'Color', [0 0.5 1])
    borders("Mexico",'Color', [0 0.5 1])
    borders("Cuba",'Color', [0 0.5 1])

    hold on

    load topo topo
    highelev = topo ;
    highelev(topo < 1500) = 0;
    contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] , 'LineColor', [0 0.7 0] , 'LineWidth', 1.25 ) %'FaceColor', 'k')%'none','LineColor','k')

    set(ax2,'Color','None')       %p
    set(ax2, 'visible', 'off');   %p

    set(ax3,'Color','None')       %p
    set(ax3, 'visible', 'off');   %p

    set(ax4,'Color','None')       %p
    set(ax4, 'visible', 'off');   %p

    xlabel(ax1,'latitude')
    ylabel(ax1,'longitude')

    axis([-125 -70 25 55])




    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIorigins_allevents_WITHLS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIorigins_allevents_WITHLS_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    eval([EPSprint]);

end
%}




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% 3)  SOME NUMBERY STATSY THINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%% number of MCSs events with(out) synoptic objects

% PERCENT_MCSI_with_MP = length(MCSI_with_MP)/( length(MCSI_with_MP) + length(MCSI_without_MP)) * 100 
% PERCENT_MCSI_without_MP = length(MCSI_without_MP)/( length(MCSI_with_MP) + length(MCSI_without_MP)) * 100 
% 
% NUM_mcsi_with_allowMP =  length(MCSI_with_MP) + length(MCSI_without_MP)   %can be repeated MP objs (touching multiple MCSI events)
% NUM_mcsi_with_allowmultiMP =  length(MCSI_with_multiMP) + length(MCSI_without_MP) 

%%%% number of syn objects touching an MCS where synoptic object is made
%%%% AFTER MCSI. Note, this doesnt necessarily mean that the MCS MAKES the
%%%% syn object (it could mean that a previously made syn obj just cross
%%%% paths with the MCS - so you have to make sure that the syn
%%%% object formed after the MCS did. 

% blah = MPtracks_perMCS_ALLYRS(:,:,1);

MPobjs_formed_after_mcsi = [];   % tabulated list of MP objects touching mcs which formed after MCSI period
MPobjs_formed_by_mcs_and_present_at_subsequent_mcsi = [];  % tally of MP objs "made" by an MCS goes on to be present at a subsequent MCS's birth. currently includes duplicate syn objs per year if they go on to "make" multiple MCSs. It's most useful for number of times a syn object is made by MCS then goes on to  makes MCS
MPobjs_concidentaloverlap_after_mcsi = []; %tally of MP object numbers that may look like they are formed by an MCS post MCSI, but really, the syn objects formed prior to MCSI and there is conincidental spatiotemporal overlap with an MCS after MCSI

[la lb lc] = size(LStracks_perMP_ALLYRS);
Mask_MPsformedbyMCS_MPstats = zeros(la,lb,lc);    Mask_MPsformedbyMCS_MPstats(:) = NaN;

for y = 1:mcs_years
    
    
    for n = 2:mcs_tracks  %starts at 2 because of the step below when looking for syn objs in prior-occuring  MCSs
        
        %         y = 2;     n = 103
        
        currmcs = MPtracks_perMCS_ALLYRS(:,n,y);  % syn objs for the current mcs
        currmcs(isnan(currmcs)) = [] ; % black out the nans.
        currpostmcs = currmcs(3:end); % syn objs for the current mcs during the post-mcsi period
        
        currpostmcs(currpostmcs == -1) = []; %kill the non-overlap times
        currpostmcs = unique(currpostmcs);
        
        %find list of syn objs touching current MCS that are only first present AFTER MCSI
        
        postcurrmcsi_syns = [];
        
        if( isempty(currpostmcs) == 0 &  isnan(basetime_MCSstats_ALLYRS(1, n, y))==0 )
            
            for s = 1 : length(currpostmcs)
                
                if(  currpostmcs(s) ~= currmcs(1)  &  currpostmcs(s) ~= currmcs(2)   & ...  %                % if the MP occurring in the post-MCSI period is not also present during the MCSI period, and
                        isempty(find(   MPtracks_perMCS_ALLYRS(:, 1:n-1,y)  == currpostmcs(s)  ))   &  ...  %(MP obj not present & logged for a previous MCS)-?-(because MCSs are logged in chronologcial order, so if multiple MCSs have a syn obj, then I guess we will jsut say that the first MCS in the record makes the syn object ?)
                        (basetime_MCSstats_ALLYRS(1, n, y) - basetime_MPstats_ALLYRS(1, currpostmcs(s), y)) /3600 < -2   ) %and the syn object didn't develop during or well before the MCSI and coincidentally coincide with the MCS later in it's life (positive means that syn object forms before the MCS (i.e., coincidental syn-mcs overlap)
                    
                    %record the MP obj:
                    MPobjs_formed_after_mcsi = cat(1, MPobjs_formed_after_mcsi, currpostmcs(s)  ) ;
                    
                    %mask for these MP objs:
                    Mask_MPsformedbyMCS_MPstats(:,currpostmcs(s),y) = 1;

                    %if this "MCS-MADE" syn obj then goes on to be present at subsequent MCSI events:
                    for m = n+1:mcs_tracks
                        if( MPatMCSI_perMCS_ALLYRS(1, m, y)  == currpostmcs(s)  |  MPatMCSI_perMCS_ALLYRS(2, m,y)  == currpostmcs(s) )  %syn object number not present during MCSI period for subsequent MCSs
                            %record the syn obj:
                            MPobjs_formed_by_mcs_and_present_at_subsequent_mcsi = cat(1,MPobjs_formed_by_mcs_and_present_at_subsequent_mcsi,currpostmcs(s));
                        end
                    end
                    
                %log syn objects that have just coindicental overlap with an MCS post MCSI:
                elseif(  currpostmcs(s) ~= currmcs(1)  &  currpostmcs(s) ~= currmcs(2)   & ...  %                % if the SYN occurring in the post-MCSI period is not also present during the MCSI period, and
                        isempty(find(   MPtracks_perMCS_ALLYRS(:, 1:n-1,y)  == currpostmcs(s)  ))   &  ...  %(syn obj not present & logged for a previous MCS)-?-(because MCSs are logged in chronologcial order, so if multiple MCSs have a syn obj, then I guess we will jsut say that the first MCS in the record makes the syn object ?)
                        (basetime_MCSstats_ALLYRS(1, n, y) - basetime_MPstats_ALLYRS(1, currpostmcs(s), y)) /3600 > 0   ) %and the syn object develops =before the MCSI and coincidentally coincide with the MCS later in it's life (positive means that syn object forms before the MCS (i.e., coincidental syn-mcs overlap)
                    %record the syn obj:
                    MPobjs_concidentaloverlap_after_mcsi = cat(1,MPobjs_concidentaloverlap_after_mcsi, currpostmcs(s));      
                end
                
            end
        end
    end 
end


% post-process the resuts:

%collate the syn objs each year touching an MCS into one long array
total_MP_touching_mcss = [];
for y = 1:mcs_years
    total_MP_touching_mcss = cat(1,total_MP_touching_mcss, MP_with_MCSs_ALLYRS( find( isnan(MP_with_MCSs_ALLYRS(:,y))==0 ),y)  ) ;
end

% %MP objects touching an MCS but form after MCSI
% %MPs formed while collocated with MCSs after MCSI (no LS present)
% PERCENT_MPtouchingmcs_formed_after_mcsi = 100 * ( length(MPobjs_formed_after_mcsi) / length(total_MP_touching_mcss) ) 
% %MPs formed while collocated with MCS and present at subsequent MCSI event
% PERCENT_MPtouchingmcs_formed_by_mcs_and_present_at_subsequent_mcsi = 100 * ( length(MPobjs_formed_by_mcs_and_present_at_subsequent_mcsi) / length(total_MP_touching_mcss) ) 
% 
% PERCENT_MPtouchingmcs_concidentaloverlap_after_mcsi = 100 * ( length(MPobjs_concidentaloverlap_after_mcsi) / length(total_MP_touching_mcss) ) 


% TotalMP_ALLTRACKEDMPOBJS = length(find(isnan(duration_MPstats_ALLYRS)==0))    
% TotalMP_INMCSCONUSdom = length( find(isnan(MASK_KEEPERS_MP_ALLYRS)==0) )  
% TotalMP_TouchingMCS = length(total_MP_touching_mcss)  

%add up the number of unique mp objs present at MCSi each year:
NumUniqueMP_presentatMCSI = [];
for y = 1:1:mcs_years
    % y = 2
    curryr = MPtracks_perMCS_ALLYRS(1:2,:,y) ;
    NumUniqueMP_presentatMCSI = vertcat( NumUniqueMP_presentatMCSI , length( unique(   curryr(find(curryr > 1)) )    ) ) ;
end
%TotalUniqueMP_presentAtMCSI = sum(NumUniqueMP_presentatMCSI)

% % % %diagnostics: 
% blah_sfpi = datetime(basetime_MPstats_ALLYRS(1,500,1), 'convertfrom','posixtime','Format','dd-MM-y-HH') 
% blah_mcs = datetime(basetime_MCSstats_ALLYRS(:,:,:),'convertfrom','posixtime','Format','dd-MM-y-HH') ;
% blah_sybmcsi =    MPatMCSI_perMCS_ALLYRS(:,:,1); 





%%%%%%%%%%%%%%%% num of MCSs in contact with an MP at anytime (not just during
%%%%%%%%%%%%%%%% MCSI

MCSs_with_MPtouchingatanyimteduringMCSlife = [];
for y = 1:1:mcs_years
    for n = 1:mcs_tracks
        %     y = 2; n = 103;
        curryrmcs = MPtracks_perMCS_ALLYRS(:,n,y) ;
        lll = length( unique(   curryrmcs(find(curryrmcs > 1)) )    ) ;
        if( isempty(lll)==0 & isnan(lll)==0 & lll > 0     )
            MCSs_with_MPtouchingatanyimteduringMCSlife = vertcat( MCSs_with_MPtouchingatanyimteduringMCSlife, n ) ;
        end
    end
end
%Total_MCSs_touchingMPanytimeduringMCSlife = length(MCSs_with_MPtouchingatanyimteduringMCSlife)


%%%% num of MPs present during MCSI:





%%



    

%%%%%%% and old and depriciated way:
%
% %%%% number of syn objects touching an MCS where synoptic object is made
% %%%% AFTER MCSI. Note, this doesnt necessarily mean that the MCS MAKES the
% %%%% syn object (it could mean that a previously made syn obj just cross
% %%%% paths with the MCS - so you have to make sure that the syn
% %%%% object formed after the MCS did. 
% 
% % blah = MPtracks_perMCS_ALLYRS(:,:,1);
% 
% MPobjs_formed_after_mcsi = [];   % tabulated list of synoptic objects touching mcs which formed after MCSI period
% MPobjs_formed_by_mcs_and_present_at_subsequent_mcsi = [];
% 
% 
% for y = 1:mcs_years
%     
%     %mpobjs_after_mcsi = [];
%
%     for n = 2:mcs_tracks  %starts at 2 because of the step below when looking for syn objs in prior-occuring  MCSs
%
%         currmcs = MPtracks_perMCS_ALLYRS(:,n,y);  % syn objs for the current mcs
%         currmcs(isnan(currmcs)) = [] ; % black out the nans.
%         currpostmcs = currmcs(3:end); % syn objs for the current mcs during the post-mcsi period
%         
%         %find list of syn objs touching current MCS that is first present
%         %AFTER MCSI
%         
%         postcurrmcsi_syns = [];
%         
%         if(  isempty(currpostmcs)==0  &  isempty( find(currpostmcs > 0) ) == 0    )
%        %if(  isempty(currpostmcs)==0  &  currmcs(1) == -1  &  currmcs(2) == -1  &  isempty( find(currpostmcs > 0) ) == 0    )    
%             postcurrmcsi_syns = unique(currpostmcs(find(currpostmcs > 0))) ;
%         end
%
%         for s = 1:length(postcurrmcsi_syns)
%             
%             % Look at current synoptic object space to confirm if mpI happened more than X (e.g. 2) hrs after MCSI    &&    (syn obj not present & logged for a previous MCS)-?-(because MCSs are logged in chronologcial order, so if multiple MCSs have a syn obj, then I guess we will jsut say that the first MCS in the record makes the syn object ?)    ........  then record the syn obj:
%             if(  (basetime_MCSstats_ALLYRS(1, n, y) - basetime_MPstats_ALLYRS(1, postcurrmcsi_syns(s), y))/3600 < -1    &    isempty(find(   MPtracks_perMCS_ALLYRS(:, 1:n-1,y)  == postcurrmcsi_syns(s)   ))  )
%                 MPobjs_formed_after_mcsi = cat(1, MPobjs_formed_after_mcsi, postcurrmcsi_syns(s)              ) ; %list of synoptic objects touching mcs after MCSI period
%
%                 %if this "MCS-MADE" syn obj then goes on to be present at subsequent MCSI:
%                 initiatesMCSlater = find(  MPatMCSI_perMCS_ALLYRS(:, n+1:end,y)  == postcurrmcsi_syns(s)   ) ;
%                 if()
%                 end
%                
%             end
%         end
%     end
% end














%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% plot duration of MP objects PRIOR to MCSi time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


mpI_vs_mcsI_dt = [];  % tabulated list of the time differential (hours) between MCSI and synoptic object formation for those that are present at MCSI birth
MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;    MPPREDURatMCSI_ALLYRS(:) = NaN;   % same as 1 line above, just in MCS(track,year) space. 

%some stuff for later that makes sense to do in this upcoming loop:
%lat/lon/objnum data (at MP intiation time) to go along with the dt log (used for specific plots later):
mpnumlog = [];
mpI_vs_mcsI_dt_lat = [];  %can use these for area and intensity plots well below
mpI_vs_mcsI_dt_lon = [];

for y = 1 : mcs_years % which is same as num years of MP objects
    for n = 1 : mcs_tracks

        %  y = 17; n = 71;
        %  y = 6; n = 78;

        mpobjs = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ;      % MP object(s) number (or lack thereof) for this MCSI event

        for u = 1:length(mpobjs)   %note, there could be more than one syn obj present at MCSI because of calling MCSI period as t = 1-2 of MCS

            % u = 1

            if(  isempty( mpobjs(u) ) == 0  & isnan( mpobjs(u) ) == 0  &  mpobjs(u) > 0  )

                %now log MPI and MCSI times for each MP-MCS
                %mcsItime = basetime_MCSstats_ALLYRS(1, n, y) ;   % Mcs obj initiation time for this MCS
                mcsItime = basetime_MCSstats_ALLYRS(1:5, n, y) ;   % Mcs obj initiation time for this MCS - considering first few because of annoying sometime nans at first few MCS times(s)
                mpItime = basetime_MPstats_ALLYRS(1, mpobjs(u)  , y) ;   %MP obj initiation time for this MCS
                if(  isnan(mpItime)==0)
                    mpI_vs_mcsI_dt = vertcat( mpI_vs_mcsI_dt , (mcsItime(1) - mpItime)/3600  ) ;  % [HOURS]   %you could alter this loop to make this variable in the format of MCSstats arrays if you want to.
                    MPPREDURatMCSI_ALLYRS(n,y) = (mcsItime(1) - mpItime)/3600 ;  % logging it in MCS (tracks, year) space

                    %log each MP's initiation lat/lon with respect to MPI-MCSI, used for specific plots later:
                    mpI_vs_mcsI_dt_lat = vertcat(mpI_vs_mcsI_dt_lat, meanlat_MPstats_ALLYRS(1,mpobjs(u),y) );
                    mpI_vs_mcsI_dt_lon = vertcat(mpI_vs_mcsI_dt_lon, meanlon_MPstats_ALLYRS(1,mpobjs(u),y) );

                    %now log some other MP properties at time of MCSI for some
                    %specific plots below. need to do a little 1:5 iterative magic
                    %to compensate for the sometine MCS nans early in their life
                    dumind = zeros(5,1); dumind(:) = NaN;
                    for i = 1:5
                        tffind  =  find(  floor(basetime_MPstats_ALLYRS(:,mpobjs(u),y)/100) == floor(mcsItime(i)/100) ) ;
                        if(isempty(tffind)==0)
                            dumind(i) = i;
                        end
                    end
                    dumind(isnan(dumind))=[] ;
                    mcstind  =  floor( mcsItime(dumind(1))/100 ) ;  %first time there is an MCS time (just past the unwanted nan buffer)
                    mptind   =  find(  floor(basetime_MPstats_ALLYRS(:,mpobjs(u),y)/100) == mcstind ) ; %the MP's corresponding time index
                    toffset = 3; % number of hours PRIOR(+) to MCSI that you want to look at MP's characteristics, set to 0 if you want at time of mcsi
                    mptimind = mptind - toffset;
                    if(mptimind < 1)
                        mptimind = 1;
                    end
                end
            end
        end
    end
end
mpI_vs_mcsI_dt(find(mpI_vs_mcsI_dt<0.5)) = 0;
MPPREDURatMCSI_ALLYRS( find(MPPREDURatMCSI_ALLYRS < 0.5) ) = 0;

%length(find(isnan(MPPREDURatMCSI_ALLYRS)==0));

% length(mparea_atMCSI_PWfilt)
% length(mparea_atMCSI)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%  Make masks to filter MPs with MCSs that 
%%%%      MPI < X hours before the MCS 
%%%%      (in case pre MCS convection is generating MP vorticity)
%%%%
%%%% Need 2 masks? One for the MPs and one for the MCSs?
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
MPdurMASK_forMCSs = totalrain_MCSstats_ALLYRS;          MPdurMASK_forMCSs(:) = 1;  
MPdurMASK_forMPs  = area_MPstats_ALLYRS;                MPdurMASK_forMPs(:)  = 1;  
%%%  MCS mask:
%look for MCSs with MPdur < 3, set them to NaN in MCSmask
[ h1 h2 ] = size(MPPREDURatMCSI_ALLYRS)  ;
for m = 1:h1
    for y = 1:h2
        if( MPPREDURatMCSI_ALLYRS(m,y)  <  3.0 )
            MPdurMASK_forMCSs(:,m,y) = NaN;
        end    
    end
end
%%%  MP mask: 
%look for MCSs with MPdur < 3, grab those MP numbers and set them to nan in MPmask
for m = 1:h1  
    for y = 1:h2
        if( MPPREDURatMCSI_ALLYRS(m,y)  <  3.0 )
            %look at MPs present at this MCSI time
            mpsatmcsi =  MPatMCSI_perMCS_ALLYRS(:,m,y) ; 
            for n = 1:length(mpsatmcsi)
                if( isnan(mpsatmcsi(n))==0  &  mpsatmcsi(n)>0 )  %if there's an MP at MCSI with dur > 3 hr
                    MPdurMASK_forMPs(:,mpsatmcsi(n),y) = NaN;
                end
            end
        end
    end
end

% mblah2 = MPdurMASK_forMCSs(:,:,2)   ;
% mblah  = MPPREDURatMCSI_ALLYRS(:,2) ;
% mblah2 = MPdurMASK_forMPs(:,:,2)    ;


%%%%%%%%%%%%% apply these masks as needed when looking at MCSI-MP analyses
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mpI_vs_mcsI_dt(find(mpI_vs_mcsI_dt < 3.0)) = NaN;
MPPREDURatMCSI_ALLYRS( find(MPPREDURatMCSI_ALLYRS < 3.0) ) = NaN;

preserve_MPatMCSI_perMCS_ALLYRS = MPatMCSI_perMCS_ALLYRS ;
MPatMCSI_perMCS_ALLYRS = MPatMCSI_perMCS_ALLYRS .* MPdurMASK_forMCSs(1:2,:,:)  ;   %in principle, applying mask here sshould be all that is needed for the many non-MP/MP/LS histograms below (unil line > ~11200)





mpI_vs_mcsI_dt = [];  % tabulated list of the time differential (hours) between MCSI and synoptic object formation for those that are present at MCSI birth
MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;    MPPREDURatMCSI_ALLYRS(:) = NaN;   % same as 1 line above, just in MCS(track,year) space. 
%some stuff for later that makes sense to do in this upcoming loop:
%lat/lon/objnum data (at MP intiation time) to go along with the dt log (used for specific plots later):
mpnumlog = [];
mpI_vs_mcsI_dt_lat = [];  %can use these for area and intensity plots well below
mpI_vs_mcsI_dt_lon = [];
% MP area, vorticity (at MCSI time) for MPs present at MCSI
mparea_atMCSI = [];
mpvort_atMCSI = [];
mpmeanMUCAPE_atMCSI = [];
mpmaxMUCAPE_atMCSI = [];
mpmeanMUCIN_atMCSI = []; 
mpminMUCIN_atMCSI = [];
mpmeanMULFC_atMCSI = [];
mpmeanMUEL_atMCSI = [];
mpmeanPW_atMCSI = [];
mpmaxPW_atMCSI = [];
mpminPW_atMCSI = []; 
mpmeanshearmag0to2_atMCSI = []; 
mpmaxshearmag0to2_atMCSI = [];
mpmeanshearmag0to6_atMCSI = [];
mpmaxshearmag0to6_atMCSI = []; 
mpmeanshearmag2to9_atMCSI = [];
mpmaxshearmag2to9_atMCSI = [];
mpmeanOMEGA600_atMCSI = [];
mpminOMEGA600_atMCSI = [];
mpminOMEGAsub600_atMCSI = []; 
mpmeanVIWVD_atMCSI = []; 
mpminVIWVD_atMCSI = []; 
mpmaxVIWVD_atMCSI = []; 
mpmeanDIV750_atMCSI = []; 
mpminDIV750_atMCSI = [];
mpminDIVsub600_atMCSI = []; 
mpmeanWNDSPD600_atMCSI = []; 
mpmeanWNDDIR600_atMCSI = []; 
% MP area, vorticity (at MCSI time) for MPs present at MCSI  - same as just above but a
% PWfilter implemented
mparea_atMCSI_PWfilt = [];
mpvort_atMCSI_PWfilt = [];
mpmeanMUCAPE_atMCSI_PWfilt = [];
mpmaxMUCAPE_atMCSI_PWfilt = [];
mpmeanMUCIN_atMCSI_PWfilt = []; 
mpminMUCIN_atMCSI_PWfilt = [];
mpmeanMULFC_atMCSI_PWfilt = [];
mpmeanMUEL_atMCSI_PWfilt = [];
mpmeanPW_atMCSI_PWfilt = [];
mpmaxPW_atMCSI_PWfilt = [];
mpminPW_atMCSI_PWfilt = []; 
mpmeanshearmag0to2_atMCSI_PWfilt = []; 
mpmaxshearmag0to2_atMCSI_PWfilt = [];
mpmeanshearmag0to6_atMCSI_PWfilt = [];
mpmaxshearmag0to6_atMCSI_PWfilt = []; 
mpmeanshearmag2to9_atMCSI_PWfilt = [];
mpmaxshearmag2to9_atMCSI_PWfilt = [];
mpmeanOMEGA600_atMCSI_PWfilt = [];
mpminOMEGA600_atMCSI_PWfilt = [];
mpminOMEGAsub600_atMCSI_PWfilt = []; 
mpmeanVIWVD_atMCSI_PWfilt = []; 
mpminVIWVD_atMCSI_PWfilt = []; 
mpmaxVIWVD_atMCSI_PWfilt = []; 
mpmeanDIV750_atMCSI_PWfilt = []; 
mpminDIV750_atMCSI_PWfilt = [];
mpminDIVsub600_atMCSI_PWfilt = []; 
mpmeanWNDSPD600_atMCSI_PWfilt = []; 
mpmeanWNDDIR600_atMCSI_PWfilt = []; 

for y = 1 : mcs_years % which is same as num years of MP objects
    for n = 1 : mcs_tracks

        %  y = 17; n = 71;
        %  y = 6; n = 78;

        mpobjs = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ;      % MP object(s) number (or lack thereof) for this MCSI event

        for u = 1:length(mpobjs)   %note, there could be more than one syn obj present at MCSI because of calling MCSI period as t = 1-2 of MCS

            % u = 1
            if(  isempty( mpobjs(u) ) == 0  & isnan( mpobjs(u) ) == 0  &  mpobjs(u) > 0 )

                %now log MPI and MCSI times for each MP-MCS
                %mcsItime = basetime_MCSstats_ALLYRS(1, n, y) ;   % Mcs obj initiation time for this MCS
                mcsItime = basetime_MCSstats_ALLYRS(1:5, n, y) ;   % Mcs obj initiation time for this MCS - considering first few because of annoying sometime nans at first few MCS times(s)
                mpItime = basetime_MPstats_ALLYRS(1, mpobjs(u)  , y) ;   %MP obj initiation time for this MCS
                if(isnan(mpItime)==0)
                    mpI_vs_mcsI_dt = vertcat( mpI_vs_mcsI_dt , (mcsItime(1) - mpItime)/3600  ) ;  % [HOURS]   %you could alter this loop to make this variable in the format of MCSstats arrays if you want to.
                    MPPREDURatMCSI_ALLYRS(n,y) = (mcsItime(1) - mpItime)/3600 ;  % logging it in MCS (tracks, year) space

                    %log each MP's initiation lat/lon with respect to MPI-MCSI, used for specific plots later:
                    mpI_vs_mcsI_dt_lat = vertcat(mpI_vs_mcsI_dt_lat, meanlat_MPstats_ALLYRS(1,mpobjs(u),y) );
                    mpI_vs_mcsI_dt_lon = vertcat(mpI_vs_mcsI_dt_lon, meanlon_MPstats_ALLYRS(1,mpobjs(u),y) );

                    %now log some other MP properties at time of MCSI for some
                    %specific plots below. need to do a little 1:5 iterative magic
                    %to compensate for the sometine MCS nans early in their life
                    dumind = zeros(5,1); dumind(:) = NaN;
                    for i = 1:5
                        tffind  =  find(  floor(basetime_MPstats_ALLYRS(:,mpobjs(u),y)/100) == floor(mcsItime(i)/100) ) ;
                        if(isempty(tffind)==0)
                            dumind(i) = i;
                        end
                    end
                    dumind(isnan(dumind))=[] ;
                    mcstind  =  floor( mcsItime(dumind(1))/100 ) ;  %first time there is an MCS time (just past the unwanted nan buffer)
                    mptind   =  find(  floor(basetime_MPstats_ALLYRS(:,mpobjs(u),y)/100) == mcstind ) ; %the MP's corresponding time index
                    toffset = 3; % number of hours PRIOR(+) to MCSI that you want to look at MP's characteristics, set to 0 if you want at time of mcsi
                    mptimind = mptind - toffset;
                    if(mptimind < 1)
                        mptimind = 1;
                    end

                    mparea_atMCSI  =  vertcat( mparea_atMCSI, area_MPstats_ALLYRS(mptind,mpobjs(u),y)       ) ;   %log area of MP at MCSI time
                    mpvort_atMCSI  =  vertcat( mpvort_atMCSI, maxVOR600_MPstats_ALLYRS(mptind,mpobjs(u),y)  );   %log peak vort of MP at MCSI time
                    mpmeanMUCAPE_atMCSI         =  vertcat( mpmeanMUCAPE_atMCSI,  meanMUCAPE_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmaxMUCAPE_atMCSI          =  vertcat( mpmaxMUCAPE_atMCSI,   maxMUCAPE_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmeanMUCIN_atMCSI          =  vertcat( mpmeanMUCIN_atMCSI,   meanMUCIN_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpminMUCIN_atMCSI           =  vertcat( mpminMUCIN_atMCSI,    minMUCIN_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmeanMULFC_atMCSI          =  vertcat( mpmeanMULFC_atMCSI,   meanMULFC_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmeanMUEL_atMCSI           =  vertcat( mpmeanMUEL_atMCSI,    meanMUEL_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmeanPW_atMCSI             =  vertcat( mpmeanPW_atMCSI,      meanPW_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmaxPW_atMCSI              =  vertcat( mpmaxPW_atMCSI,       maxPW_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpminPW_atMCSI              =  vertcat( mpminPW_atMCSI,       minPW_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmeanshearmag0to2_atMCSI   =  vertcat( mpmeanshearmag0to2_atMCSI,   meanshearmag0to2_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmaxshearmag0to2_atMCSI    =  vertcat( mpmaxshearmag0to2_atMCSI,    maxshearmag0to2_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmeanshearmag0to6_atMCSI   =  vertcat( mpmeanshearmag0to6_atMCSI,   meanshearmag0to6_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmaxshearmag0to6_atMCSI    =  vertcat( mpmaxshearmag0to6_atMCSI,    maxshearmag0to6_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmeanshearmag2to9_atMCSI   =  vertcat( mpmeanshearmag2to9_atMCSI,   meanshearmag2to9_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmaxshearmag2to9_atMCSI    =  vertcat( mpmaxshearmag2to9_atMCSI,    maxshearmag2to9_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmeanOMEGA600_atMCSI       =  vertcat( mpmeanOMEGA600_atMCSI,       meanOMEGA600_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpminOMEGA600_atMCSI        =  vertcat( mpminOMEGA600_atMCSI,        minOMEGA600_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpminOMEGAsub600_atMCSI     =  vertcat( mpminOMEGAsub600_atMCSI,     minOMEGAsub600_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmeanVIWVD_atMCSI          =  vertcat( mpmeanVIWVD_atMCSI,          meanVIWVD_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpminVIWVD_atMCSI           =  vertcat( mpminVIWVD_atMCSI,           minVIWVD_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmaxVIWVD_atMCSI           =  vertcat( mpmaxVIWVD_atMCSI,           maxVIWVD_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmeanDIV750_atMCSI         =  vertcat( mpmeanDIV750_atMCSI,         meanDIV750_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpminDIV750_atMCSI          =  vertcat( mpminDIV750_atMCSI,          minDIV750_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpminDIVsub600_atMCSI       =  vertcat( mpminDIVsub600_atMCSI,       minDIVsub600_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmeanWNDSPD600_atMCSI      =  vertcat( mpmeanWNDSPD600_atMCSI,      meanWNDSPD600_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                    mpmeanWNDDIR600_atMCSI      =  vertcat( mpmeanWNDDIR600_atMCSI,      meanWNDDIR600_MPstats_ALLYRS(mptimind,mpobjs(u),y) .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;

                    % PW>24 filtered one
                    if(  mean( meanPW_MPstats_ALLYRS(:,mpobjs(u),y),'omitnan') > 24.  )
                        mparea_atMCSI_PWfilt               =  vertcat( mparea_atMCSI_PWfilt, area_MPstats_ALLYRS(mptind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;   %log area of MP at MCSI time
                        mpvort_atMCSI_PWfilt               =  vertcat( mpvort_atMCSI_PWfilt, maxVOR600_MPstats_ALLYRS(mptind,mpobjs(u),y)  .*  MPdurMASK_forMPs(1,mpobjs(u),y)  );   %log peak vort of MP at MCSI time
                        mpmeanMUCAPE_atMCSI_PWfilt         =  vertcat( mpmeanMUCAPE_atMCSI_PWfilt,  meanMUCAPE_MPstats_ALLYRS(mptimind,mpobjs(u),y)  .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                        mpmaxMUCAPE_atMCSI_PWfilt          =  vertcat( mpmaxMUCAPE_atMCSI_PWfilt,   maxMUCAPE_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                        mpmeanMUCIN_atMCSI_PWfilt          =  vertcat( mpmeanMUCIN_atMCSI_PWfilt,   meanMUCIN_MPstats_ALLYRS(mptimind,mpobjs(u),y)  .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                        mpminMUCIN_atMCSI_PWfilt           =  vertcat( mpminMUCIN_atMCSI_PWfilt,    minMUCIN_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                        mpmeanMULFC_atMCSI_PWfilt          =  vertcat( mpmeanMULFC_atMCSI_PWfilt,   meanMULFC_MPstats_ALLYRS(mptimind,mpobjs(u),y)  .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                        mpmeanMUEL_atMCSI_PWfilt           =  vertcat( mpmeanMUEL_atMCSI_PWfilt,    meanMUEL_MPstats_ALLYRS(mptimind,mpobjs(u),y)  .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                        mpmeanPW_atMCSI_PWfilt             =  vertcat( mpmeanPW_atMCSI_PWfilt,      meanPW_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                        mpmaxPW_atMCSI_PWfilt              =  vertcat( mpmaxPW_atMCSI_PWfilt,       maxPW_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                        mpminPW_atMCSI_PWfilt              =  vertcat( mpminPW_atMCSI_PWfilt,       minPW_MPstats_ALLYRS(mptimind,mpobjs(u),y)  .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                        mpmeanshearmag0to2_atMCSI_PWfilt   =  vertcat( mpmeanshearmag0to2_atMCSI_PWfilt,   meanshearmag0to2_MPstats_ALLYRS(mptimind,mpobjs(u),y)  .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                        mpmaxshearmag0to2_atMCSI_PWfilt    =  vertcat( mpmaxshearmag0to2_atMCSI_PWfilt,    maxshearmag0to2_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                        mpmeanshearmag0to6_atMCSI_PWfilt   =  vertcat( mpmeanshearmag0to6_atMCSI_PWfilt,   meanshearmag0to6_MPstats_ALLYRS(mptimind,mpobjs(u),y)  .*  MPdurMASK_forMPs(1,mpobjs(u),y)      ) ;
                        mpmaxshearmag0to6_atMCSI_PWfilt    =  vertcat( mpmaxshearmag0to6_atMCSI_PWfilt,    maxshearmag0to6_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                        mpmeanshearmag2to9_atMCSI_PWfilt   =  vertcat( mpmeanshearmag2to9_atMCSI_PWfilt,   meanshearmag2to9_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                        mpmaxshearmag2to9_atMCSI_PWfilt    =  vertcat( mpmaxshearmag2to9_atMCSI_PWfilt,    maxshearmag2to9_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                        mpmeanOMEGA600_atMCSI_PWfilt       =  vertcat( mpmeanOMEGA600_atMCSI_PWfilt,       meanOMEGA600_MPstats_ALLYRS(mptimind,mpobjs(u),y)    .*  MPdurMASK_forMPs(1,mpobjs(u),y)    ) ;
                        mpminOMEGA600_atMCSI_PWfilt        =  vertcat( mpminOMEGA600_atMCSI_PWfilt,        minOMEGA600_MPstats_ALLYRS(mptimind,mpobjs(u),y)    .*  MPdurMASK_forMPs(1,mpobjs(u),y)    ) ;
                        mpminOMEGAsub600_atMCSI_PWfilt     =  vertcat( mpminOMEGAsub600_atMCSI_PWfilt,     minOMEGAsub600_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                        mpmeanVIWVD_atMCSI_PWfilt          =  vertcat( mpmeanVIWVD_atMCSI_PWfilt,          meanVIWVD_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                        mpminVIWVD_atMCSI_PWfilt           =  vertcat( mpminVIWVD_atMCSI_PWfilt,           minVIWVD_MPstats_ALLYRS(mptimind,mpobjs(u),y)    .*  MPdurMASK_forMPs(1,mpobjs(u),y)    ) ;
                        mpmaxVIWVD_atMCSI_PWfilt           =  vertcat( mpmaxVIWVD_atMCSI_PWfilt,           maxVIWVD_MPstats_ALLYRS(mptimind,mpobjs(u),y)    .*  MPdurMASK_forMPs(1,mpobjs(u),y)    ) ;
                        mpmeanDIV750_atMCSI_PWfilt         =  vertcat( mpmeanDIV750_atMCSI_PWfilt,         meanDIV750_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                        mpminDIV750_atMCSI_PWfilt          =  vertcat( mpminDIV750_atMCSI_PWfilt,          minDIV750_MPstats_ALLYRS(mptimind,mpobjs(u),y)    .*  MPdurMASK_forMPs(1,mpobjs(u),y)    ) ;
                        mpminDIVsub600_atMCSI_PWfilt       =  vertcat( mpminDIVsub600_atMCSI_PWfilt,       minDIVsub600_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                        mpmeanWNDSPD600_atMCSI_PWfilt      =  vertcat( mpmeanWNDSPD600_atMCSI_PWfilt,      meanWNDSPD600_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                        mpmeanWNDDIR600_atMCSI_PWfilt      =  vertcat( mpmeanWNDDIR600_atMCSI_PWfilt,      meanWNDDIR600_MPstats_ALLYRS(mptimind,mpobjs(u),y)   .*  MPdurMASK_forMPs(1,mpobjs(u),y)     ) ;
                    end
                end
            end
        end
    end
end






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%% MCSI-MP MPI maps, with mpdurmask applied:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% tabulate UNIQUE MP obj origin locations for those present at MCSI (no repeats if there are multiple MCSs with same MP)
unique_MP_origin_lons = [];
unique_MP_origin_lats = [];
unique_MP_full_lats = [];
unique_MP_full_lons = [];
    
for y = 1:mcs_years

    % y = 1
    
    %unique syn objs numbers per year
    syns = MPatMCSI_perMCS_ALLYRS(:,:,y);
    uniq_syn = unique( syns( find( syns ) ) );    uniq_syn(uniq_syn < 0) = [];   uniq_syn(isnan(uniq_syn)) = [];  
   
%     %identify a syn object present at this MCS's birth:
%     MPtr = MPatMCSI_perMCS_ALLYRS(:,n,y)  ;  %synoptic track number present at MCSI
%     mpnums = vertcat(mpnums,MPtr) ;
    
    %tabulate lats/lons for the uniques syn tracks:
    for n = 1:length(uniq_syn)
        %tabulated lat/lons of syn object origins that initiate MCSs for use in hostograms later:
        unique_MP_origin_lons = vertcat( unique_MP_origin_lons, meanlon_MPstats_ALLYRS(1,uniq_syn(n),y) );
        unique_MP_origin_lats = vertcat( unique_MP_origin_lats, meanlat_MPstats_ALLYRS(1,uniq_syn(n),y) );
        
        unique_MP_full_lats = vertcat( unique_MP_full_lats, meanlat_MPstats_ALLYRS(:,uniq_syn(n),y) );
        unique_MP_full_lons = vertcat( unique_MP_full_lons, meanlon_MPstats_ALLYRS(:,uniq_syn(n),y) );
        
    end
end


ff = figure  
ff.Position = [2204,414,845,395];

set(gca,'XTick',[])
set(gca,'YTick',[])

title([' Unique origin locations of MP objects present during MCSI. filtLS=',num2str(filteroutLS)])
ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes; 
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on
origins = [unique_MP_origin_lons-360,unique_MP_origin_lats];
length(isnan(unique_MP_origin_lons-360)==0)

%histogram2(ax2,syn_origin_lons-360,syn_origin_lats,'NumBins',[30,15],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
histogram2(ax2,unique_MP_origin_lons-360,unique_MP_origin_lats,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 20])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
load coastlines
%plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
states = readgeotable("usastatehi.shp");
states{:,4} = states{:,4}
geoshow(states,'facecolor', 'none', 'DefaultEdgeColor', [0.4 0.2 0])
borders("Canada",'Color', [0.4 0.2 0])
borders("Mexico",'Color', [0.4 0.2 0])
borders("Cuba",'Color', [0.4 0.2 0])

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0 0.7 0]);  


set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

xlabel(ax1,'latitude')
ylabel(ax1,'longitude')

%axis([-170 -50 20 60])
axis([-140 -60 20 60])

%%%%%%%% image out:

saveas(ff,horzcat(imout,'/MPOrigins_AtMCSI_filtLS',num2str(filteroutLS),'.png'));

outlab = horzcat(imout,'/MPOrigins_AtMCSI_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);


%%%%%%%%%%%%%%%%%%%  same thing but looking at full lifetime of MP
%%%%%%%%%%%%%%%%%%%  objects rather than just MP-I locations: 


ff = figure  
ff.Position = [2204,414,845,395];

set(gca,'XTick',[])
set(gca,'YTick',[])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes; 
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on
origins = [unique_MP_full_lons-360,unique_MP_full_lats];
length(isnan(unique_MP_full_lats-360)==0)

%histogram2(ax2,syn_origin_lons-360,syn_origin_lats,'NumBins',[30,15],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
histogram2(ax2,unique_MP_full_lons-360,unique_MP_full_lats,[-180:1:-50],[20:1:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 100])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
load coastlines
%plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
states = readgeotable("usastatehi.shp");
states{:,4} = states{:,4}
geoshow(states,'facecolor', 'none', 'DefaultEdgeColor', [0.4 0.2 0])
borders("Canada",'Color', [0.4 0.2 0])
borders("Mexico",'Color', [0.4 0.2 0])
borders("Cuba",'Color', [0.4 0.2 0])

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0 0.7 0]);  


set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

xlabel(ax1,'latitude')
ylabel(ax1,'longitude')

%axis([-170 -50 20 60])
axis([-140 -60 20 60])
title([' Unique full track locations of MPs that are eventually present during MCSI '])

%%%%%%%% image out:

%saveas(ff,horzcat(imout,'/MPfulltacks_AtMCSI_filtLS',num2str(filteroutLS),'.png'));

outlab = horzcat(imout,'/MPfulltacks_AtMCSI_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);







%%%%%%%%%%%%   mapped histogram of MCSI locations with MP object present

%generate list of MCS numbers with MP objs present at MCSI:

MCSI_with_MP = [];
% MCSI_without_MP = [];
MCSI_withMP_lon = [];
MCSI_withMP_lat = [];
% MCSI_withoutMP_lon = [];
% MCSI_withoutMP_lat = [];

%mcs numbers with MPs (not) present at MCSI
MCSI_with_MP_ALLYRS = zeros(mcs_tracks,mcs_years);    MCSI_with_MP_ALLYRS(:,:) = NaN;
MCSI_without_MP_ALLYRS = zeros(mcs_tracks,mcs_years); MCSI_without_MP_ALLYRS(:,:) = NaN;

%note, this loop should inherently skip dud MCSs (that have an all-NaN records during their full lifetime) because it's looking for >. This includes those filtered by LSs
MCSI_with_multiMP = [];
for y = 1:mcs_years
    for n = 1:mcs_tracks
        
        %   n = 336;  y = 1;
        if(  MPatMCSI_perMCS_ALLYRS(1,n,y) > 0 | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0    ) %tabulate all of the MCSs with MP object present at birth
        %if(  MPatMCSI_perMCS_ALLYRS(1,n,y) > 1 | MPatMCSI_perMCS_ALLYRS(2,n,y) > 1    ) %tabulate all of the MCSs with MP object present at birth

            clear unis
            unis = unique(MPatMCSI_perMCS_ALLYRS(1:2,n,y) ) ;    unis(unis == -1) = [];     unis(unis == NaN) = [];
            MCSI_with_MP_ALLYRS(n,y) =  unis(1) ;  % MP obj number present at MCSI for each MCS obj (in MCS format) - picking the first if there are multiples (THIS MAY/MAYNOT THE IDEAL WAY BUT NOT SURE HOW TO HANDLE THIS IF MORE THAN ONE - WHICH I DONT THINK IS COMMON)
            
            for g = 1:length(unis)
                MCSI_with_multiMP = vertcat(MCSI_with_multiMP,unis(g));
            end
            
            MCSI_with_MP = vertcat(MCSI_with_MP,n);
            MCSI_withMP_lon = vertcat( MCSI_withMP_lon, meanlon_MCSstats_ALLYRS(1,n,y) ) ;
            MCSI_withMP_lat = vertcat( MCSI_withMP_lat, meanlat_MCSstats_ALLYRS(1,n,y) ) ;
            
        elseif(MPatMCSI_perMCS_ALLYRS(1,n,y) < 0 & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0 )  %tabulate all of the MCSs without MP object present at birth
            
%             MCSI_without_MP_ALLYRS(n,y) = 1;
%             MCSI_without_MP = vertcat(MCSI_without_MP,n);
            MCSI_withoutMP_lon = vertcat( MCSI_withoutMP_lon, meanlon_MCSstats_ALLYRS(1,n,y) ) ;
            MCSI_withoutMP_lat = vertcat( MCSI_withoutMP_lat, meanlat_MCSstats_ALLYRS(1,n,y) ) ;

        end
    end
end



% change these to use MP/LS per MCS fields rather than duration? 

%numMCSI_with_LS = length(find(isnan(duration_MCSstats_ALLYRS_YESLS)==0))
%numMCSI_without_LS = length(find(isnan(duration_MCSstats_ALLYRS_NOLS)==0))
%num_all_MCSI = numMCSI_with_LS + numMCSI_without_LS
% 
% length(MCSI_without_MP) +  length(MCSI_with_MP)  % 
% length(MCSI_without_MP)   % 
% length(MCSI_with_MP)      % size not allowing multiple MDs present at MCSI
% length(MCSI_with_multiMP) % size allowing multiple MDs present at MCSI events
% 


% ff = figure  
% ff.Position = [2008,332,683,428];
% 
% set(gca,'XTick',[])
% set(gca,'YTick',[])
% 
% title([' Locations of MCSI events that have MP objects present'])
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% ax4 = axes; 
% linkaxes([ax1, ax2, ax3, ax4],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% edges1 = [-180:3:-50];  edges2 = [20:3:60];
% 
% kill = find(  isnan(MCSI_withMP_lon));
% MCSI_withMP_lon(kill) = [];
% MCSI_withMP_lat(kill) = [];
% kill = find(  isnan(MCSI_withMP_lat));
% MCSI_withMP_lon(kill) = [];
% MCSI_withMP_lat(kill) = [];
% combined = horzcat(MCSI_withMP_lon,MCSI_withMP_lat);
% combinedsort = sortrows(combined,2);
% MCSI_withMP_lon_sort = combinedsort(:,1);
% MCSI_withMP_lat_sort = combinedsort(:,2);
% NC = histcounts2( MCSI_withMP_lon_sort, MCSI_withMP_lat_sort, edges1,edges2  ) / (2021-2004+1) ;
% centers1 = [  mean(edges1(1:2))   :  ( mean(edges1(2:3)) - mean(edges1(1:2)) )   :  mean(edges1(end-1:end))  ] ; 
% centers2 = [  mean(edges2(1:2))   :  ( mean(edges2(2:3)) - mean(edges2(1:2)) )   :  mean(edges2(end-1:end))  ] ; 
% contourf(ax2,centers1,centers2,NC',12,'k','LineColor','none')
% colormap(ax2,flipud(creamsicle2))
% caxis(ax2,[0 max(max(NC))])
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% set(cb,'YTick',[0:max(max(NC))/5:max(max(NC))])
% hold on
% 
% load coastlines
% %plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% states = readgeotable("usastatehi.shp");
% states{:,4} = states{:,4}
% geoshow(states,'facecolor', 'none', 'DefaultEdgeColor', [0 0.5 1])
% borders("Canada",'Color', [0 0.5 1])
% borders("Mexico",'Color', [0 0.5 1])
% borders("Cuba",'Color', [0 0.5 1])
% 
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] , 'LineColor', [0 0.7 0] , 'LineWidth', 1.25 ) %'FaceColor', 'k')%'none','LineColor','k')
%     
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% set(ax4,'Color','None')       %p
% set(ax4, 'visible', 'off');   %p
% 
% xlabel(ax1,'latitude')
% ylabel(ax1,'longitude')
% 
% axis([-125 -70 25 55])



%%%%% normalized


% ff = figure  
% ff.Position = [2008,332,683,428];
% 
% set(gca,'XTick',[])
% set(gca,'YTick',[])
% 
% title([' Locations of MCSI events that have MP objects present'])
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% ax4 = axes; 
% linkaxes([ax1, ax2, ax3, ax4],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% edges1 = [-180:3:-50];  edges2 = [20:3:60];
% 
% kill = find(  isnan(MCSI_withMP_lon));
% MCSI_withMP_lon(kill) = [];
% MCSI_withMP_lat(kill) = [];
% kill = find(  isnan(MCSI_withMP_lat));
% MCSI_withMP_lon(kill) = [];
% MCSI_withMP_lat(kill) = [];
% combined = horzcat(MCSI_withMP_lon,MCSI_withMP_lat);
% combinedsort = sortrows(combined,2);
% MCSI_withMP_lon_sort = combinedsort(:,1);
% MCSI_withMP_lat_sort = combinedsort(:,2);
% NC = histcounts2( MCSI_withMP_lon_sort, MCSI_withMP_lat_sort, edges1,edges2  ) / (2021-2004+1) ;
% NC = NC/max(max(NC));
% centers1 = [  mean(edges1(1:2))   :  ( mean(edges1(2:3)) - mean(edges1(1:2)) )   :  mean(edges1(end-1:end))  ] ; 
% centers2 = [  mean(edges2(1:2))   :  ( mean(edges2(2:3)) - mean(edges2(1:2)) )   :  mean(edges2(end-1:end))  ] ; 
% contourf(ax2,centers1,centers2,NC',12,'k','LineColor','none')
% colormap(ax2,flipud(creamsicle2))
% caxis(ax2,[0 1])
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% set(cb,'YTick',[0:1/5:1])
% hold on
% 
% load coastlines
% %plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% states = readgeotable("usastatehi.shp");
% states{:,4} = states{:,4}
% geoshow(states,'facecolor', 'none', 'DefaultEdgeColor', [0 0.5 1])
% borders("Canada",'Color', [0 0.5 1])
% borders("Mexico",'Color', [0 0.5 1])
% borders("Cuba",'Color', [0 0.5 1])
% 
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] , 'LineColor', [0 0.7 0] , 'LineWidth', 1.25 ) %'FaceColor', 'k')%'none','LineColor','k')
%     
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% set(ax4,'Color','None')       %p
% set(ax4, 'visible', 'off');   %p
% 
% xlabel(ax1,'latitude')
% ylabel(ax1,'longitude')
% 
% axis([-125 -70 25 55])

% ff = figure  
% ff.Position = [2008,332,683,428];
% 
% title([' Locations of MCSI events that have MP objects present'])
% 
% set(gca,'XTick',[])
% set(gca,'YTick',[])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% ax4 = axes;
% % ax5 = axes;
% linkaxes([ax1,ax2,ax3,ax4],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% 
% histogram2(ax2, MCSI_withMP_lon, MCSI_withMP_lat,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% cb = colormap(ax2,flipud(creamsicle2)) 
% caxis(ax2,[1 25])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% 
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] , 'LineColor', [0 0.7 0] , 'LineWidth', 1.25 ) %'FaceColor', 'k')%'none','LineColor','k')
% 
% plot(ax4,mean(mean(MCSI_withMP_lon,'omitnan')),mean(mean(MCSI_withMP_lat,'omitnan')),'xr')
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% set(ax4,'Color','None')       %p
% set(ax4, 'visible', 'off');   %p
% 
% % set(ax5,'Color','None')       %p
% % set(ax5, 'visible', 'off');   %p
% 
% xlabel(ax1,'latitude')
% ylabel(ax1,'longitude')
% 
% axis([-125 -70 25 55])
% 
% %%%%%%%% image out:
% 
% %saveas(ff,horzcat(imout,'/MCSIorigins_withMP.png'));
% 
% outlab = horzcat(imout,'/MCSIorigins_withMP_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
% EPSprint = horzcat('print -painters -depsc ',outlab);
% eval([EPSprint]);






% area_MPstats_ALLYRS     maxVOR600_MPstats_ALLYRS



%%%%% plot histogram of num of MCSI events as function of MP area
figure;
[h1,b] = hist(area_MPstats_ALLYRS,[0:20000:800000]);  blah1 =  h1 /(sum(h1));
bar(b,blah1,1,'FaceColor',[0 0 0])
hold on
[h1,b] = hist(mparea_atMCSI_PWfilt,[0:20000:800000]);  blah1 =  h1 /(sum(h1));
bar(b,blah1,1,'FaceColor',[0.6350 0.0780 0.1840])
alpha 0.7
axis([0.00000 800000 0 0.12])
title(['Area of MP at MCSI'])

outlab = horzcat(imout,'/MParea_atMCSI_andfull',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);




figure;
[h1,b] = hist(maxVOR600_MPstats_ALLYRS,[0:0.000002:0.0001]);  blah1 =  h1 /(sum(h1));
bar(b,blah1,1,'FaceColor',[0 0 0])
hold on
[h1,b] = hist(mpvort_atMCSI_PWfilt,[0:0.000002:0.0001]);  blah1 =  h1 /(sum(h1));
bar(b,blah1,1,'FaceColor',[0.4940 0.1840 0.5560])
alpha 0.7
axis([.00002 0.000095 0 0.12])
title(['Vorticity of MP at MCSI'])

outlab = horzcat(imout,'/MPvort_atMCSI',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);



% plot the normalized histogram:
ff = figure   

edges=[0:3:200]/24;
[h1,b] = hist((mpI_vs_mcsI_dt/24),edges,'r');  blah1 =  h1; %/(sum(h1));
bar(b,blah1,1,'FaceColor',[0 0.5 0.5])
axis([-0.125/2 7 0 80 ])
%axis([-0.125/2 7 0 0.16])
xlabel('Days','FontSize',15)
ylabel('Num of MP objects [normalized by popul size]','FontSize',15)
ax = gca;
ax.FontSize = 15; 
title([' Duration of MP prior to MCSI. Filtdt<3hr, filtLS=',num2str(filteroutLS)])
%%%%%%%% image out:

saveas(ff,horzcat(imout,'/MPDuration_preMCSI_filtLS',num2str(filteroutLS),'.png'));


outlab = horzcat(imout,'/MPDuration_preMCSI_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to duration of MCSs with MP objs present at
%%%   MCSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%% make syn origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hidur  = [22:200];
meddur = [15:21];
lodur  = [0:14];

% grab MCS duration and MP obj for all events with syn present at MCSI:

MCSwithMPDuration_list = [];
MCSwithoutMPDuration_list = [];

%lat/lons of origin site of synoptic obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];

for y = 1 : mcs_years        % which is same as num years of MP objects
    for n = 1 : mcs_tracks

        %if there's a MP obj at mcsi
        %if( preserve_MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  |  preserve_MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  |  MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )

            MCSwithMPDuration_list = vertcat(MCSwithMPDuration_list, duration_MCSstats_ALLYRS(n,y) );
            
            %find the syn obj number & then it's origin lat/lon and cat it (for different mcs durations):
            if(  isnan(duration_MCSstats_ALLYRS(n,y))==0  &  isempty(find(duration_MCSstats_ALLYRS(n,y) == hidur ))==0  )
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                %mpnum = unique(preserve_MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
            elseif(  isnan(duration_MCSstats_ALLYRS(n,y))==0  &  isempty(find(duration_MCSstats_ALLYRS(n,y) == meddur ))==0 )
                %mpnum = unique(preserve_MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
            elseif(  isnan(duration_MCSstats_ALLYRS(n,y))==0  &  isempty(find(duration_MCSstats_ALLYRS(n,y) == lodur ))==0  )
                %mpnum = unique(preserve_MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end
            
            %if no mp obj present at MCSI
        %elseif(preserve_MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & preserve_MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
        elseif(MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi  
            
            MCSwithoutMPDuration_list = vertcat(MCSwithoutMPDuration_list, duration_MCSstats_ALLYRS(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)

%   mblah = MPatMCSI_perMCS_ALLYRS(:,:,3);


%histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
ff = figure('position',[84,497,1032,451]);
title(' Duration of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
edges=[0:1:96];
hold on
[h1,b] = hist(MCSwithoutMPDuration_list,edges) ;  blah1 =  h1/(sum(h1));
bar(b,blah1,1,'FaceColor',[0 0.5 0.5])
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPDuration_list,edges) ;  blah2 =  h1/(sum(h1));
bar(b,blah2,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPDuration_list,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPDuration_list,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPDuration_list,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPDuration_list,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPDuration_list,MCSwithMPDuration_list,'Alpha',alvl)
% text(55,100,['K-S test at ', num2str(alvl),' sig lvl'])
% if(sh == 0)
%     text(55,90,['Sig diff distributions? NO.  P-val:',num2str(p)])
% elseif(sh == 1)
%     text(55,90,['Sig diff distributions? YES.  P-val:',num2str(p)]) 
% end
[p2,sh2] = ranksum(MCSwithoutMPDuration_list,MCSwithMPDuration_list,'Alpha',alvl)
% text(55,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl'])
% if(sh2 == 0)
%     text(55,60,['Sig diff distributions? NO.  P-val:',num2str(p2)])
% elseif(sh2 == 1)
%     text(55,60,['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
% end
ax = gca;
ax.FontSize = 15
legend('MCSI without MP','MCSI with MP','FontSize',15)

axis([1 72 0 max(blah1)+0.025 ])
xticks([0:6:96])
xlabel('Hours','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)

%%%%%%%% image out:

%saveas(ff,horzcat(imout,'/MCSIhist_duration_filtLS',num2str(filteroutLS),'.png'));

outlab = horzcat(imout,'/MCSIhist_duration_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);


if(filteroutLS==1)


    MCS_withLS_Duration = duration_MCSstats_ALLYRS_YESLS(:);   MCS_withLS_Duration(MCS_withLS_Duration ==0) = NaN;
    MCS_withoutLS_Duration = duration_MCSstats_ALLYRS(:);      MCS_withoutLS_Duration(MCS_withoutLS_Duration ==0) = NaN;

    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);
    title(' Duration of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:1:96];
    hold on
    [h1,b] = hist(MCS_withoutLS_Duration,edges) ;  blah1 =  h1/(sum(h1));
    bar(b,blah1,1,'FaceColor',[0 0.5 0.5])
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCS_withLS_Duration,edges) ;  blah2 =  h1/(sum(h1));
    bar(b,blah2,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCS_withoutLS_Duration,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCS_withoutLS_Duration,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCS_withLS_Duration,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCS_withLS_Duration,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    alvl = 0.05;
    [sh,p] = kstest2(MCS_withoutLS_Duration,MCS_withLS_Duration,'Alpha',alvl)
    % text(55,100,['K-S test at ', num2str(alvl),' sig lvl'])
    % if(sh == 0)
    %     text(55,90,['Sig diff distributions? NO.  P-val:',num2str(p)])
    % elseif(sh == 1)
    %     text(55,90,['Sig diff distributions? YES.  P-val:',num2str(p)])
    % end
    [p2,sh2] = ranksum(MCS_withoutLS_Duration,MCS_withLS_Duration,'Alpha',alvl)
    % text(55,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl'])
    % if(sh2 == 0)
    %     text(55,60,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    % elseif(sh2 == 1)
    %     text(55,60,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    % end
    ax = gca;
    ax.FontSize = 15
    legend('MCS without LS','MCS with LS','FontSize',15)

    axis([1 72 0 0.1]) %max(blah1) ])
    xticks([0:6:96])
    xlabel('Hours','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_duration_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LS_duration.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);



    %%%   Now do a fun one with: 
    %       i)   MCSs with LSs (MCS_withLS_Duration);   
    %       ii)  MCSs without LSs but with MPs (MCSwithMPDuration_list);  
    %       iii) MCSs without LSs or MPs (MCSwithoutMPDuration_list);
    

    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' Duration of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:1:96];
    hold on
    [h1,b] = hist(MCS_withLS_Duration,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5])
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPDuration_list,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPDuration_list,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1])
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCS_withLS_Duration,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCS_withLS_Duration,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPDuration_list,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPDuration_list,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPDuration_list,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPDuration_list,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;
%     [sh,p] = kstest2(MCS_withoutLS_Duration,MCS_withLS_Duration,'Alpha',alvl)
%     % text(55,100,['K-S test at ', num2str(alvl),' sig lvl'])
%     % if(sh == 0)
%     %     text(55,90,['Sig diff distributions? NO.  P-val:',num2str(p)])
%     % elseif(sh == 1)
%     %     text(55,90,['Sig diff distributions? YES.  P-val:',num2str(p)])
%     % end
%     [p2,sh2] = ranksum(MCS_withoutLS_Duration,MCS_withLS_Duration,'Alpha',alvl)
%     % text(55,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl'])
%     % if(sh2 == 0)
%     %     text(55,60,['Sig diff distributions? NO.  P-val:',num2str(p2)])
%     % elseif(sh2 == 1)
%     %     text(55,60,['Sig diff distributions? YES.  P-val:',num2str(p2)])
%     % end
   
    axis([1 72 0 0.1]) %max(blah1) ])
    xticks([0:6:96])
    xlabel('Hours','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_duration_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LSMPMCS_duration_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);

end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCS_withLS_Duration(:),MCSwithMPDuration_list(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCS_withLS_Duration(:),MCSwithMPDuration_list(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPDuration_list(:),MCSwithoutMPDuration_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPDuration_list(:),MCSwithoutMPDuration_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCS_withLS_Duration(:),MCSwithoutMPDuration_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCS_withLS_Duration(:),MCSwithoutMPDuration_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



%%% violin version


% 
% 
% xs = 0.5;
% xf = 3.5;
% figure('units','normalized','outerposition',[0 0 1 1])
% 
% subplot(2,4,1)
% ys = 0;
% yf = 130;
% exp = {'','with LS','with MP','MCS alone',''};
% blah = MCS_withLS_Duration(:); blah(isnan(MCS_withLS_Duration(:))) = [];
% violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
% blah = MCSwithMPDuration_list(:); blah(isnan(MCSwithMPDuration_list(:))) = [];
% violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
% blah = MCSwithoutMPDuration_list; blah(isnan(MCSwithoutMPDuration_list)) = [];
% violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
% axis([xs xf ys yf])
% set(gca,'xtick',[0:3],'xticklabel',exp)
% title('MCS total duration')

% subplot(2,4,2)
% ys = 0;
% yf = 130;
% exp = {'','with LS','with MP','MCS alone',''};
% blah = MCS_withLS_Duration(:); blah(isnan(MCS_withLS_Duration(:))) = [];
% violin(blah,'x',[1 0 0 5],'facecolor',[0 0.5 0.5])
% blah = MCSwithMPDuration_list(:); blah(isnan(MCSwithMPDuration_list(:))) = [];
% violin(blah,'x',[2 0 0 5],'facecolor',[1 0.5 0])
% blah = MCSwithoutMPDuration_list; blah(isnan(MCSwithoutMPDuration_list)) = [];
% violin(blah,'x',[3 0 0 5],'facecolor',[0 0.3 1])
% axis([xs xf ys yf])
% set(gca,'xtick',[0:3],'xticklabel',exp)
% title('MCS total duration')













%%%%%%%%%%%%%%%
% now plot geographic histograms of MP origins tied to MCSI of hi-, med-, lo-duration MCSs
%%%%%%%%%%%%%%%

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

title([' Origin locations of MPs eventually present during MCSI of MCSs with duration: ', num2str(hidur(1)),'+ hrs.  N = ', num2str(length(mplat_hiMCS)) ])

%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])

%saveas(ff,horzcat(imout,'/MPorigin_longdurMCS.png'));

outlab = horzcat(imout,'/MPorigin_longdurMCS_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);







% 
% %subplot(3,1,2)
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% 
% title([' Origin locations of MPs eventually present during MCSI of MCSs with duration: ', num2str(meddur(1)),'-',num2str(meddur(end)) ' hrs.  N = ', num2str(length(mplat_medMCS)) ])
% 
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 15])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% axis([-160 -50 15 60])
% 
% %saveas(ff,horzcat(imout,'/MPorigin_meddurMCS.png'));
% 
% outlab = horzcat(imout,'/MPorigin_meddurMCS_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
title([' Origin locations of MPs eventually present during MCSI of MCSs with duration: ', num2str(lodur(1)),'-',num2str(lodur(end)) ' hrs.  N = ', num2str(length(mplat_loMCS)) ])

title([' Origin locations of MPs eventually present during MCSI of MCSs with duration: ', num2str(lodur(1)),'-',num2str(lodur(end)) ' hrs.  N = ', num2str(length(mplat_loMCS)) ])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])

%saveas(ff,horzcat(imout,'/MPorigin_shortdurMCS.png'));
outlab = horzcat(imout,'/MPorigin_shortdurMCS_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is long-MCS-duration syn obj origin different than for short-mcs-dur?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)


















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to AREA of MCSs with MP objs present at MCSI
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% condense [1:5] PF area stats 1-combined MCS pf area:
areapf_MCSstats_ALLYRS = dAdt_MCSstats_ALLYRS;    areapf_MCSstats_ALLYRS(:) = NaN;  
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        for t = 1:mtimes
            areapf_MCSstats_ALLYRS(t,n,y) = sum(pfarea_MCSstats_ALLYRS(:,t,n,y), 'omitnan' );
        end
    end
end
areapf_MCSstats_ALLYRS(areapf_MCSstats_ALLYRS==0) = NaN;

%make this var the MCS lifeime max:
maxareapf_MCSstats_ALLYRS = max( areapf_MCSstats_ALLYRS, [], 1);   maxareapf_MCSstats_ALLYRS = permute(maxareapf_MCSstats_ALLYRS, [2 3 1]) ;






%%%%% make syn origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hiarea  = [65000:690000];
medarea = [35001:65000];
loarea  = [0:35000];

% grab MCS duration and syn obj for all events with syn present at MCSI:

MCSwithMPareapf_list = [];
MCSwithoutMPareapf_list = [];

%lat/lons of origin site of synoptic obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPareapf_list = vertcat(MCSwithMPareapf_list, maxareapf_MCSstats_ALLYRS(n,y) );
            
            %find the MP obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(maxareapf_MCSstats_ALLYRS(n,y))==0  &  maxareapf_MCSstats_ALLYRS(n,y) > hiarea(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(maxareapf_MCSstats_ALLYRS(n,y))==0  &  maxareapf_MCSstats_ALLYRS(n,y) > medarea(1)  &  maxareapf_MCSstats_ALLYRS(n,y) < medarea(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(maxareapf_MCSstats_ALLYRS(n,y))==0  &  maxareapf_MCSstats_ALLYRS(n,y) < loarea(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end
            
            %if no mp obj present at MCSI
        elseif(MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPareapf_list = vertcat(MCSwithoutMPareapf_list, maxareapf_MCSstats_ALLYRS(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)





% %histogram of MCS durations with & without synoptic objs at birth:
% ff = figure;
% edges=[-5000:5000:200000-5000];
% hold on
% hist(MCSwithoutMPareapf_list,edges);
% h = findobj(gca,'Type','patch');
% h.FaceColor = [0 0.5 0.5];
% h.EdgeColor = [0 0 0];
% hold on
% hist(MCSwithMPareapf_list,edges);
% h2 = findobj(gca,'Type','patch');
% h2(1).FaceColor = [1 0.5 0];
% h2(1).EdgeColor = [0 0 0];
% h2(1).FaceAlpha = 0.8;
% plot(median(MCSwithoutMPareapf_list,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
% plot(mean(MCSwithoutMPareapf_list,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
% plot(median(MCSwithMPareapf_list,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
% plot(mean(MCSwithMPareapf_list,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
% legend('MCSI without synoptic obj','MCSI with synoptic obj')
% title([' max lifetime area of total PFs for MCSs'])
% alvl = 0.05;
% [sh,p] = kstest2(MCSwithoutMPareapf_list,MCSwithMPareapf_list,'Alpha',alvl)
% text(90000,300,['K-S test at ', num2str(alvl),' significance lvl'])
% if(sh == 0)
%     text(90000,280,['Sig diff distributions? NO.  P-val:',num2str(p)])
% elseif(sh == 1)
%     text(90000,280,['Sig diff distributions? YES.  P-val:',num2str(p)]) 
% end
% [p2,sh2] = ranksum(MCSwithoutMPareapf_list,MCSwithMPareapf_list,'Alpha',alvl)
% text(90000,170,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl'])
% if(sh2 == 0)
%     text(90000,150,['Sig diff distributions? NO.  P-val:',num2str(p2)])
% elseif(sh2 == 1)
%     text(90000,150,['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
% end
% axis([1 edges(end)-10000 0 150 ])
% xticks([0:10000:edges(end)-1000])
% xlabel(['precip area [km^2]'])
% ylabel(['Num of MCSs'])





%histogram of MCS area with & without MP objs at birth normalized by total count of each group:
ff = figure('position',[84,497,1032,451]);
edges=[-5000:5000:400000-5000];
hold on
[h1,b] = hist(MCSwithoutMPareapf_list,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPareapf_list,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPareapf_list,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPareapf_list,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPareapf_list,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPareapf_list,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
alvl = 0.05;
%[sh,p] = kstest2(MCSwithoutMPareapf_list,MCSwithMPareapf_list,'Alpha',alvl)
[sh,p] = kstest2(blahwithout,blahwith,'Alpha',alvl)
% text(55,100,['K-S test at ', num2str(alvl),' sig lvl'])
% if(sh == 0)
%     text(55,90,['Sig diff distributions? NO.  P-val:',num2str(p)])
% elseif(sh == 1)
%     text(55,90,['Sig diff distributions? YES.  P-val:',num2str(p)]) 
% end
[p2,sh2] = ranksum(blahwithout,blahwith,'Alpha',alvl)
%text(55,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl'])
% if(sh2 == 0)
%     text(55,60,['Sig diff distributions? NO.  P-val:',num2str(p2)])
% elseif(sh2 == 1)
%     text(55,60,['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
% end
ax = gca;
ax.FontSize = 15
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' Precip area of MCSs','FontSize',15)
axis([1 2.5*10^5 0 0.11 ])
xticks([0:10000:edges(end)-1000])
xlabel('km^2','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)

%saveas(ff,horzcat(imout,'/MCSIhist_pfarea.png'));
outlab = horzcat(imout,'/MCSIhist_pfarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total PF area: ', num2str(hiarea(1)),'+ km^2.  N = ', num2str(length(mplat_hiMCS)) ])


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])

%saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_largeareaMCS_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);







%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

title([' Origin locations of MP objects eventually present during MCSI of MCSs with max total PF area: ', num2str(medarea(1)),'-',num2str(medarea(end)) ' km^2.  N = ', num2str(length(mplat_medMCS)) ])


ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])

%saveas(ff,horzcat(imout,'/MPorigin_medareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_medareaMCS_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);








%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

title([' Origin locations of MP objects eventually present during MCSI of MCSs with max total PF: < ',num2str(loarea(end)) ' km^2.  N = ', num2str(length(mplat_loMCS)) ])


ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])

%saveas(ff,horzcat(imout,'/MPorigin_smallareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_smallareaMCS_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);


%stat diff tests, is lare-area-MCS MP obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)



% plot all MCSs with LSs and all without LSs (regardless of MP presence)
if(filteroutLS==1)


    % condense [1:5] PF area stats 1-combined MCS pf area:
    areapf_MCSstats_ALLYRS_YESLS = dAdt_MCSstats_ALLYRS_YESLS;    areapf_MCSstats_ALLYRS_YESLS(:) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            for t = 1:mtimes
                areapf_MCSstats_ALLYRS_YESLS(t,n,y) = sum(pfarea_MCSstats_ALLYRS_YESLS(:,t,n,y), 'omitnan' );
            end
        end
    end
    areapf_MCSstats_ALLYRS_YESLS(areapf_MCSstats_ALLYRS_YESLS==0) = NaN;

    %make this var the MCS lifeime max:
    maxareapf_MCSstats_ALLYRS_YESLS = max( areapf_MCSstats_ALLYRS_YESLS, [], 1);   maxareapf_MCSstats_ALLYRS_YESLS = permute(maxareapf_MCSstats_ALLYRS_YESLS, [2 3 1]) ;




    MCS_withLS_maxareapf = maxareapf_MCSstats_ALLYRS_YESLS(:);   MCS_withLS_maxareapf(MCS_withLS_maxareapf ==0) = NaN; MCS_withLS_maxareapf(isnan(MCS_withLS_maxareapf)) = [];
    MCS_withoutLS_maxareapf = maxareapf_MCSstats_ALLYRS(:);      MCS_withoutLS_maxareapf(MCS_withoutLS_maxareapf ==0) = NaN;  MCS_withoutLS_maxareapf(isnan(MCS_withoutLS_maxareapf)) = [];

    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);
    title(' maxpf area of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[-5000:5000:400000-5000];
    hold on
    [h1,b] = hist(MCS_withoutLS_maxareapf,edges) ;  blah1 =  h1/(sum(h1));
    bar(b,blah1,1,'FaceColor',[0 0.5 0.5])
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCS_withLS_maxareapf,edges) ;  blah2 =  h1/(sum(h1));
    bar(b,blah2,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCS_withoutLS_maxareapf,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCS_withoutLS_maxareapf,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCS_withLS_maxareapf,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCS_withLS_maxareapf,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    alvl = 0.05;
    [sh,p] = kstest2(MCS_withoutLS_maxareapf,MCS_withLS_maxareapf,'Alpha',alvl)
    % text(55,100,['K-S test at ', num2str(alvl),' sig lvl'])
    % if(sh == 0)
    %     text(55,90,['Sig diff distributions? NO.  P-val:',num2str(p)])
    % elseif(sh == 1)
    %     text(55,90,['Sig diff distributions? YES.  P-val:',num2str(p)])
    % end
    [p2,sh2] = ranksum(MCS_withoutLS_maxareapf,MCS_withLS_maxareapf,'Alpha',alvl)
    % text(55,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl'])
    % if(sh2 == 0)
    %     text(55,60,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    % elseif(sh2 == 1)
    %     text(55,60,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    % end
    ax = gca;
    ax.FontSize = 15
    legend('MCS without LS','MCS with LS','FontSize',15)

    axis([1 2.5*10^5 0 0.11 ])
    xticks([0:10000:edges(end)-1000])
    xlabel('km^2','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_maxareapf_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LS_duration_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);


    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCS_withLS_maxareapf);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPareapf_list);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPareapf_list);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' Max precip area of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[-5000:5000:400000-5000];
    hold on
    [h1,b] = hist(MCS_withLS_maxareapf,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5])
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPareapf_list,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPareapf_list,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1])
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCS_withLS_maxareapf,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCS_withLS_maxareapf,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPareapf_list,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPareapf_list,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPareapf_list,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPareapf_list,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;
    %     [sh,p] = kstest2(MCS_withoutLS_Duration,MCS_withLS_Duration,'Alpha',alvl)
    %     % text(55,100,['K-S test at ', num2str(alvl),' sig lvl'])
    %     % if(sh == 0)
    %     %     text(55,90,['Sig diff distributions? NO.  P-val:',num2str(p)])
    %     % elseif(sh == 1)
    %     %     text(55,90,['Sig diff distributions? YES.  P-val:',num2str(p)])
    %     % end
    %     [p2,sh2] = ranksum(MCS_withoutLS_Duration,MCS_withLS_Duration,'Alpha',alvl)
    %     % text(55,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl'])
    %     % if(sh2 == 0)
    %     %     text(55,60,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    %     % elseif(sh2 == 1)
    %     %     text(55,60,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    %     % end

    axis([1 2.5*10^5 0 0.11 ])
    xticks([0:10000:edges(end)-1000])
    xlabel('km^2','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_maxareapf_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LSMPMCS_maxareapf_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);

end




alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCS_withLS_maxareapf(:),MCSwithMPareapf_list(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCS_withLS_maxareapf(:),MCSwithMPareapf_list(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPareapf_list(:),MCSwithoutMPareapf_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPareapf_list(:),MCSwithoutMPareapf_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCS_withLS_maxareapf(:),MCSwithoutMPareapf_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCS_withLS_maxareapf(:),MCSwithoutMPareapf_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end










%   totalrain_MCSstats_ALLYRS


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to total RAINFALL MASS of MCSs with Syn objs present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% condense [1:5] PF area stats 1-combined MCS pf area:
totalrainmass_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    totalrainmass_MCSstats_ALLYRSb(:) = NaN;  
rainmass  =  totalrain_MCSstats_ALLYRS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]

for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        %for t = 1:mtimes
            totalrainmass_MCSstats_ALLYRSb(n,y)  =  sum (   rainmass(:,n,y) , 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
        %end
    end
end
totalrainmass_MCSstats_ALLYRSb(totalrainmass_MCSstats_ALLYRSb==0) = NaN;


fact = 10^13 ;



%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hitotmass  = [0.55000000000000001, 10] * fact;
medtotmass = [0.29000000000000001, 0.55] * fact;
lototmass  = [0, 0.29] * fact;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPtotmass_list = [];
MCSwithoutMPtotmass_list = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPtotmass_list = vertcat( MCSwithMPtotmass_list, totalrainmass_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(totalrainmass_MCSstats_ALLYRSb(n,y))==0  &  totalrainmass_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(totalrainmass_MCSstats_ALLYRSb(n,y))==0  &  totalrainmass_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  totalrainmass_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(totalrainmass_MCSstats_ALLYRSb(n,y))==0  &  totalrainmass_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end
            
            
            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPtotmass_list = vertcat(MCSwithoutMPtotmass_list, totalrainmass_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)



%   figure; hist( vertcat(MCSwithoutMPtotmass_list , MCSwithMPtotmass_list ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:.05:4];
hold on
% hist(MCSwithoutMPtotmass_list/fact,edges);
% h = findobj(gca,'Type','patch');
% h.FaceColor = [0 0.5 0.5];
% h.EdgeColor = [0 0 0];
% hold on
% hist(MCSwithMPtotmass_list/fact,edges);
% h2 = findobj(gca,'Type','patch');
% h2(1).FaceColor = [1 0.5 0];
% h2(1).EdgeColor = [0 0 0];
% h2(1).FaceAlpha = 0.8;
[h1,b] = hist(MCSwithoutMPtotmass_list/fact,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPtotmass_list/fact,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPtotmass_list/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPtotmass_list/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPtotmass_list/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPtotmass_list/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without synoptic obj','MCSI with synoptic obj','FontSize',15)
title(' Total lifetime accumulated rain mass for MCSs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPtotmass_list,MCSwithMPtotmass_list,'Alpha',alvl)
% text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
% if(sh == 0)
%     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
% elseif(sh == 1)
%     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)]) 
% end
[p2,sh2] = ranksum(MCSwithoutMPtotmass_list,MCSwithMPtotmass_list,'Alpha',alvl)
% text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
% if(sh2 == 0)
%     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
% elseif(sh2 == 1)
%     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
% end
ax = gca;
ax.FontSize = 15
xticks( [.025:0.2:edges(end)] )
xlabel('MCS lifetime total rain mass [x10^1^3 kg]','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([0 edges(end)-1 0 0.15 ])



%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MCSIhist_totrain_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime precip mass of : ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])

%saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_largetotprecip_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









% %subplot(3,1,2)
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% 
% title([' Origin locations of MPs eventually present during MCSI of MCSs with max total PF mass: ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) ' kg.  N = ', num2str(length(mplat_medMCS)) ])
% 
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 15])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% axis([-160 -50 15 60])
% 
% %saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
% outlab = horzcat(imout,'/MPorigin_medtotprecip_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

title([' Origin locations of MPs eventually present during MCSI of MCSs with max total PF mass: < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])


ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])

%saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_smalltotprecip_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)







if(filteroutLS==1)

    fact = 10^13 ;

    % condense [1:5] PF area stats 1-combined MCS pf area:
    totalrainmass_MCSstats_ALLYRS_YESLSb = dAdt_MCSstats_ALLYRS;    totalrainmass_MCSstats_ALLYRS_YESLSb(:) = NaN;
    rainmass_YESLS  =  totalrain_MCSstats_ALLYRS_YESLS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]

    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            %for t = 1:mtimes
            totalrainmass_MCSstats_ALLYRS_YESLSb(n,y)  =  sum (   rainmass_YESLS(:,n,y) , 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
            %end
        end
    end
    totalrainmass_MCSstats_ALLYRS_YESLSb(totalrainmass_MCSstats_ALLYRS_YESLSb==0) = NaN;


    MCSwithoutLStotmass = totalrainmass_MCSstats_ALLYRSb(:);   MCSwithoutLStotmass(MCSwithoutLStotmass==0)=[];  MCSwithoutLStotmass(isnan(MCSwithoutLStotmass))=[];
    MCSwithLStotmass = totalrainmass_MCSstats_ALLYRS_YESLSb(:);   MCSwithLStotmass(MCSwithLStotmass==0)=[];  MCSwithLStotmass(isnan(MCSwithLStotmass))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' Total lifetime accumulated rain mass for MCSs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:.05:4];
    hold on
    % hist(MCSwithoutMPtotmass_list/fact,edges);
    % h = findobj(gca,'Type','patch');
    % h.FaceColor = [0 0.5 0.5];
    % h.EdgeColor = [0 0 0];
    % hold on
    % hist(MCSwithMPtotmass_list/fact,edges);
    % h2 = findobj(gca,'Type','patch');
    % h2(1).FaceColor = [1 0.5 0];
    % h2(1).EdgeColor = [0 0 0];
    % h2(1).FaceAlpha = 0.8;
    [h1,b] = hist(MCSwithoutLStotmass/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLStotmass/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLStotmass/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLStotmass/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLStotmass/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLStotmass/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLStotmass,MCSwithLStotmass,'Alpha',alvl)
    % text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
    % if(sh == 0)
    %     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
    % elseif(sh == 1)
    %     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)])
    % end
    [p2,sh2] = ranksum(MCSwithoutLStotmass,MCSwithLStotmass,'Alpha',alvl)
    % text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
    % if(sh2 == 0)
    %     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    % elseif(sh2 == 1)
    %     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    % end
    ax = gca;
    ax.FontSize = 15
    xticks( [.025:0.2:edges(end)] )
    xlabel('MCS lifetime total rain mass [x10^1^3 kg]','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 edges(end)-1 0 0.15 ])

    saveas(ff,horzcat(imout,'/MCSIhist_totrain_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
    outlab = horzcat(imout,'/MCSIhist_totrain_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);







    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_list/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_list/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' Total rain mass of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:.05:4];
    hold on
    [h1,b] = hist(MCSwithLStotmass/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPtotmass_list/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPtotmass_list/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLStotmass/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLStotmass/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPtotmass_list/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPtotmass_list/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPtotmass_list/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPtotmass_list/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [.025:0.2:edges(end)] )
    xlabel('MCS lifetime total rain mass [x10^1^3 kg]','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 edges(end)-1 0 0.15 ])

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_totrainmass_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LSMPMCS_maxareapf_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLStotmass(:),MCSwithMPtotmass_list(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLStotmass(:),MCSwithMPtotmass_list(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPtotmass_list(:),MCSwithoutMPtotmass_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPtotmass_list(:),MCSwithoutMPtotmass_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLStotmass(:),MCSwithoutMPtotmass_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLStotmass(:),MCSwithoutMPtotmass_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end












%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to mean speed of MCSs with MP objs present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



meanspeed = (  MotionX_MCSstats_ALLYRS .* MotionX_MCSstats_ALLYRS  +  MotionY_MCSstats_ALLYRS .* MotionY_MCSstats_ALLYRS  ).^0.5 ;
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        %for t = 1:mtimes
            MCSspeed_MCSstats_ALLYRS(n,y)  =  mean (   meanspeed(:,n,y) , 'omitnan'   )  ;   % mean motion speed of MCS
        %end
    end
end



%%%%% make syn origin locations broken down by hi, med, lo MCS duration:

% prescribed speed bins of mcs (hours):
himcsspeed  = [19.00000001, 100] ;
medmcsspeed = [15.00000001, 19] ;
lomcsspeed  = [0, 15] ;

% grab MCS duration and syn obj for all events with syn present at MCSI:

MCSwithMPmcsspeed_list = [];
MCSwithoutMPmcsspeed_list = [];

%lat/lons of origin site of synoptic obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a MP obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  |  MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPmcsspeed_list = vertcat( MCSwithMPmcsspeed_list, MCSspeed_MCSstats_ALLYRS(n,y) );
            
            %find the MP obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(MCSspeed_MCSstats_ALLYRS(n,y))==0  &  MCSspeed_MCSstats_ALLYRS(n,y) > himcsspeed(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(MCSspeed_MCSstats_ALLYRS(n,y))==0  &  MCSspeed_MCSstats_ALLYRS(n,y) > medmcsspeed(1)  &  MCSspeed_MCSstats_ALLYRS(n,y) < medmcsspeed(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(MCSspeed_MCSstats_ALLYRS(n,y))==0  &  MCSspeed_MCSstats_ALLYRS(n,y) < lomcsspeed(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end
            
            
            %if no syn obj present at MCSI
        elseif(MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPmcsspeed_list = vertcat(MCSwithoutMPmcsspeed_list, MCSspeed_MCSstats_ALLYRS(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)



%   figure; hist( vertcat(MCSwithoutMPtotmass_list , MCSwithMPtotmass_list ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:1:50];
hold on
% hist(MCSwithoutMPmcsspeed_list,edges);
% h = findobj(gca,'Type','patch');
% h.FaceColor = [0 0.5 0.5];
% h.EdgeColor = [0 0 0];
% hold on
% hist(MCSwithMPmcsspeed_list,edges);
% h2 = findobj(gca,'Type','patch');
% h2(1).FaceColor = [1 0.5 0];
% h2(1).EdgeColor = [0 0 0];
% h2(1).FaceAlpha = 0.8;
[h1,b] = hist(MCSwithoutMPmcsspeed_list,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPmcsspeed_list,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPmcsspeed_list,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPmcsspeed_list,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPmcsspeed_list,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPmcsspeed_list,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without synoptic obj','MCSI with synoptic obj','FontSize',15)
title(' Mean MCSs motion','FontSize',15)
alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPmcsspeed_list,MCSwithMPmcsspeed_list,'Alpha',alvl)
% text(30,150,['K-S test at ', num2str(alvl),' significance lvl:'])
% if(sh == 0)
%     text(30,140,['Sig diff distributions? NO.  P-val:',num2str(p)])
% elseif(sh == 1)
%     text(30,140,['Sig diff distributions? YES.  P-val:',num2str(p)]) 
% end
[p2,sh2] = ranksum(MCSwithoutMPmcsspeed_list,MCSwithMPmcsspeed_list,'Alpha',alvl)
text(30,120,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
% if(sh2 == 0)
%     text(30,110,['Sig diff distributions? NO.  P-val:',num2str(p2)])
% elseif(sh2 == 1)
%     text(30,110,['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
% end
ax = gca;
ax.FontSize = 15
xticks( [-0.5:2:edges(end)] )
xlabel(['MCS lifetime mean speed of motion [m/s]'],'FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([3 40 0 0.12 ])

%saveas(ff,horzcat(imout,'/MCSIhist_mcsspeed.png'));
outlab = horzcat(imout,'/MCSIhist_mcsspeed.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);










% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime mean speed of : ', num2str(himcsspeed(1)),'+ m/s.  N = ', num2str(length(mplat_hiMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_fastMCS.png'));
outlab = horzcat(imout,'/MPorigin_fastMCS.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);







%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime mean speed: ', num2str(medmcsspeed(1)),'-',num2str(medmcsspeed(end)) ' m/s.  N = ', num2str(length(mplat_medMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_medspeedMCS.png'));
outlab = horzcat(imout,'/MPorigin_medspeedMCS.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);







%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime mean speed : < ',num2str(lomcsspeed(end)) ' m/s.  N = ', num2str(length(mplat_loMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_slowMCS.png'));
outlab = horzcat(imout,'/MPorigin_slowMCS.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is lare-area-MCS mp obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)








if(filteroutLS==1)

    %fact = 10^13 ;
    meanspeed_YESLS = (  MotionX_MCSstats_ALLYRS_YESLS .* MotionX_MCSstats_ALLYRS_YESLS  +  MotionY_MCSstats_ALLYRS_YESLS .* MotionY_MCSstats_ALLYRS_YESLS  ).^0.5 ;

    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            %for t = 1:mtimes
            MCSspeed_MCSstats_ALLYRS_YESLS(n,y)  =  mean (   meanspeed_YESLS(:,n,y) , 'omitnan'   )  ;   % mean motion speed of MCS
            %end
        end
    end



%     MCSwithoutLStotmass = totalrainmass_MCSstats_ALLYRS(:);   MCSwithoutLStotmass(MCSwithoutLStotmass==0)=[];  MCSwithoutLStotmass(isnan(MCSwithoutLStotmass))=[];
%     MCSwithLStotmass = totalrainmass_MCSstats_ALLYRS_YESLS(:);   MCSwithLStotmass(MCSwithLStotmass==0)=[];  MCSwithLStotmass(isnan(MCSwithLStotmass))=[];
    MCSwithoutLSspeed = MCSspeed_MCSstats_ALLYRS(:);   MCSwithoutLSspeed(MCSwithoutLSspeed==0)=[];  MCSwithoutLSspeed(isnan(MCSwithoutLSspeed))=[];
    MCSwithLSspeed =  MCSspeed_MCSstats_ALLYRS_YESLS(:);   MCSwithLSspeed(MCSwithLSspeed==0)=[];  MCSwithLSspeed(isnan(MCSwithLSspeed))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' MCS speed. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:2:50];
    hold on
    % hist(MCSwithoutMPtotmass_list/fact,edges);
    % h = findobj(gca,'Type','patch');
    % h.FaceColor = [0 0.5 0.5];
    % h.EdgeColor = [0 0 0];
    % hold on
    % hist(MCSwithMPtotmass_list/fact,edges);
    % h2 = findobj(gca,'Type','patch');
    % h2(1).FaceColor = [1 0.5 0];
    % h2(1).EdgeColor = [0 0 0];
    % h2(1).FaceAlpha = 0.8;
    [h1,b] = hist(MCSwithoutLSspeed,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLSspeed,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLSspeed,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLSspeed,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLSspeed,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLSspeed,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLSspeed,MCSwithLSspeed,'Alpha',alvl)
    % text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
    % if(sh == 0)
    %     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
    % elseif(sh == 1)
    %     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)])
    % end
    [p2,sh2] = ranksum(MCSwithoutLSspeed,MCSwithLSspeed,'Alpha',alvl)
    % text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
    % if(sh2 == 0)
    %     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    % elseif(sh2 == 1)
    %     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    % end
    ax = gca;
    ax.FontSize = 15
    xticks( [0:2:edges(end)] )
    xlabel('MCS lifetime total rain mass [x10^1^3 kg]','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 edges(end)-1 0 0.15 ])

    saveas(ff,horzcat(imout,'/MCSIhist_mcsspeed_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
    outlab = horzcat(imout,'/MCSIhist_mcsspeed_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);







    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_list/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_list/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' MCS speed. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:2:50];
    hold on
    [h1,b] = hist(MCSwithLSspeed,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPmcsspeed_list,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPmcsspeed_list,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLSspeed,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLSspeed,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPmcsspeed_list,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPmcsspeed_list,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPmcsspeed_list,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPmcsspeed_list,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [0:2:edges(end)] )
    xlabel('MCS mean speed','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 edges(end)-1 0 0.2 ])

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_totrainmass_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LSMPMCS_maxareapf_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSspeed(:),MCSwithMPmcsspeed_list(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSspeed(:),MCSwithMPmcsspeed_list(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPmcsspeed_list(:),MCSwithoutMPmcsspeed_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPmcsspeed_list(:),MCSwithoutMPmcsspeed_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSspeed(:),MCSwithoutMPmcsspeed_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSspeed(:),MCSwithoutMPmcsspeed_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end









%%%%%%%%%%%%%%%%%%
%%%  convective tot rain mass
%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to total conv/strat RAINFALL MASS of MCSs with Syn objs present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% condense [1:5] PF area stats 1-combined MCS pf area:
convrainmass_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    convrainmass_MCSstats_ALLYRSb(:) = NaN;  
convrainmass  =  convrain_MCSstats_ALLYRS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]

for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        %for t = 1:mtimes
            convrainmass_MCSstats_ALLYRSb(n,y)  =  sum (   convrainmass(:,n,y) , 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
        %end
    end
end
convrainmass_MCSstats_ALLYRSb(convrainmass_MCSstats_ALLYRSb==0) = NaN;


fact = 10^13 ;



%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hitotmass  = [0.1500000000000001, 10] * fact;
medtotmass = [0.07000000000000001, 0.15] * fact;
lototmass  = [0, 0.07] * fact;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPconvmass_list = [];
MCSwithoutMPconvmass_list = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPconvmass_list = vertcat( MCSwithMPconvmass_list, convrainmass_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(convrainmass_MCSstats_ALLYRSb(n,y))==0  &  convrainmass_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(convrainmass_MCSstats_ALLYRSb(n,y))==0  &  convrainmass_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  convrainmass_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(convrainmass_MCSstats_ALLYRSb(n,y))==0  &  convrainmass_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end
            
            
            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPconvmass_list = vertcat(MCSwithoutMPconvmass_list, convrainmass_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)



%   figure; hist( vertcat(MCSwithoutMPtotmass_list , MCSwithMPtotmass_list ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:.025:1];
hold on
% hist(MCSwithoutMPtotmass_list/fact,edges);
% h = findobj(gca,'Type','patch');
% h.FaceColor = [0 0.5 0.5];
% h.EdgeColor = [0 0 0];
% hold on
% hist(MCSwithMPtotmass_list/fact,edges);
% h2 = findobj(gca,'Type','patch');
% h2(1).FaceColor = [1 0.5 0];
% h2(1).EdgeColor = [0 0 0];
% h2(1).FaceAlpha = 0.8;
[h1,b] = hist(MCSwithoutMPconvmass_list/fact,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPconvmass_list/fact,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPconvmass_list/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPconvmass_list/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPconvmass_list/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPconvmass_list/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' Total lifetime accumulated convective rain mass for MCSs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPconvmass_list,MCSwithMPconvmass_list,'Alpha',alvl)
% text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
% if(sh == 0)
%     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
% elseif(sh == 1)
%     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)]) 
% end
[p2,sh2] = ranksum(MCSwithoutMPconvmass_list,MCSwithMPconvmass_list,'Alpha',alvl)
% text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
% if(sh2 == 0)
%     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
% elseif(sh2 == 1)
%     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
% end
ax = gca;
ax.FontSize = 15
xticks( [0:0.05:edges(end)] )
xlabel('MCS lifetime total convective rain mass [x10^1^3 kg]','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([0 edges(end) 0 0.22 ])



%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MCSIhist_convrain_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime conv precip mass of : ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_largeconvprecip_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total conv PF mass: ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) ' kg.  N = ', num2str(length(mplat_medMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_medconvprecip_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total conv PF mass: < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])


%saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_smalltotprecip_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)







if(filteroutLS==1)

    fact = 10^13 ;

    % condense [1:5] PF area stats 1-combined MCS pf area:
    totalrainmass_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    totalrainmass_MCSstats_ALLYRSb(:) = NaN;
    convrainmass_YESLS  =  convrain_MCSstats_ALLYRS_YESLS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]

    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            %for t = 1:mtimes
            convrainmass_MCSstats_ALLYRS_YESLSb(n,y)  =  sum (   convrainmass_YESLS(:,n,y) , 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
            %end
        end
    end
    convrainmass_MCSstats_ALLYRS_YESLSb(convrainmass_MCSstats_ALLYRS_YESLSb==0) = NaN;


    MCSwithoutLSconvmass = convrainmass_MCSstats_ALLYRSb(:);   MCSwithoutLSconvmass(MCSwithoutLSconvmass==0)=[];  MCSwithoutLSconvmass(isnan(MCSwithoutLSconvmass))=[];
    MCSwithLSconvmass = convrainmass_MCSstats_ALLYRS_YESLSb(:);   MCSwithLSconvmass(MCSwithLSconvmass==0)=[];  MCSwithLSconvmass(isnan(MCSwithLSconvmass))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' Total lifetime accumulated conv rain mass for MCSs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:.025:1];
    hold on
    % hist(MCSwithoutMPtotmass_list/fact,edges);
    % h = findobj(gca,'Type','patch');
    % h.FaceColor = [0 0.5 0.5];
    % h.EdgeColor = [0 0 0];
    % hold on
    % hist(MCSwithMPtotmass_list/fact,edges);
    % h2 = findobj(gca,'Type','patch');
    % h2(1).FaceColor = [1 0.5 0];
    % h2(1).EdgeColor = [0 0 0];
    % h2(1).FaceAlpha = 0.8;
    [h1,b] = hist(MCSwithoutLSconvmass/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLSconvmass/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLSconvmass/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLSconvmass/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLSconvmass/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLSconvmass/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLSconvmass,MCSwithLSconvmass,'Alpha',alvl)
    % text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
    % if(sh == 0)
    %     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
    % elseif(sh == 1)
    %     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)])
    % end
    [p2,sh2] = ranksum(MCSwithoutLSconvmass,MCSwithLSconvmass,'Alpha',alvl)
    % text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
    % if(sh2 == 0)
    %     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    % elseif(sh2 == 1)
    %     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    % end
    ax = gca;
    ax.FontSize = 15
    xticks( [0:0.5:edges(end)] )
    xlabel('MCS lifetime total conv rain mass [x10^1^3 kg]','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 edges(end) 0 0.22 ])

    saveas(ff,horzcat(imout,'/MCSIhist_convrain_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
    outlab = horzcat(imout,'/MCSIhist_convrain_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);







    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_list/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_list/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' Total convective rain mass of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:.025:1];
    hold on
    [h1,b] = hist(MCSwithLSconvmass/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPconvmass_list/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPconvmass_list/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLSconvmass/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLSconvmass/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPconvmass_list/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPconvmass_list/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPconvmass_list/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPconvmass_list/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [0:0.05:edges(end)] )
    xlabel('MCS lifetime total conv rain mass [x10^1^3 kg]','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 edges(end) 0 0.22 ])

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_convrainmass_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LSMPMCS_convrainmass_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSconvmass(:),MCSwithMPconvmass_list(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSconvmass(:),MCSwithMPconvmass_list(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPconvmass_list(:),MCSwithoutMPconvmass_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPconvmass_list(:),MCSwithoutMPconvmass_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSconvmass(:),MCSwithoutMPconvmass_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSconvmass(:),MCSwithoutMPconvmass_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end








%%%%%%%%%%%%%%%%%%
%%%  stratiform tot rain mass
%%%%%%%%%%%%%%%%%%




% convrain_MCSstats_ALLYRS
% stratrain_MCSstats_ALLYRS
% 
% convrain_MCSstats_ALLYRS_YESLS
% stratrain_MCSstats_ALLYRS_YESLS


%   totalrain_MCSstats_ALLYRS


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to total conv/strat RAINFALL MASS of MCSs with Syn objs present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% condense [1:5] PF area stats 1-combined MCS pf area:
stratrainmass_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    stratrainmass_MCSstats_ALLYRSb(:) = NaN; 
stratrainmass  =  stratrain_MCSstats_ALLYRS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]

for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        %for t = 1:mtimes
            stratrainmass_MCSstats_ALLYRSb(n,y)  =  sum (   stratrainmass(:,n,y) , 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
        %end
    end
end
stratrainmass_MCSstats_ALLYRSb(stratrainmass_MCSstats_ALLYRSb==0) = NaN;



fact = 10^13 ;



%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hitotmass  = [0.3100000000000001, 10] * fact;
medtotmass = [0.15500000000000001, 0.31] * fact;
lototmass  = [0, 0.155] * fact;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPstratmass_list = [];
MCSwithoutMPstratmass_list = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPstratmass_list = vertcat( MCSwithMPstratmass_list, stratrainmass_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(stratrainmass_MCSstats_ALLYRSb(n,y))==0  &  stratrainmass_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(stratrainmass_MCSstats_ALLYRSb(n,y))==0  &  stratrainmass_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  stratrainmass_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(stratrainmass_MCSstats_ALLYRSb(n,y))==0  &  stratrainmass_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end
            
            
            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPstratmass_list = vertcat(MCSwithoutMPstratmass_list, stratrainmass_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)



%   figure; hist( vertcat(MCSwithoutMPtotmass_list , MCSwithMPtotmass_list ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:.025:2];
hold on
% hist(MCSwithoutMPtotmass_list/fact,edges);
% h = findobj(gca,'Type','patch');
% h.FaceColor = [0 0.5 0.5];
% h.EdgeColor = [0 0 0];
% hold on
% hist(MCSwithMPtotmass_list/fact,edges);
% h2 = findobj(gca,'Type','patch');
% h2(1).FaceColor = [1 0.5 0];
% h2(1).EdgeColor = [0 0 0];
% h2(1).FaceAlpha = 0.8;
[h1,b] = hist(MCSwithoutMPstratmass_list/fact,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPstratmass_list/fact,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPstratmass_list/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPstratmass_list/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPstratmass_list/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPstratmass_list/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' Total lifetime accumulated stratiform rain mass for MCSs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPstratmass_list,MCSwithMPstratmass_list,'Alpha',alvl)
% text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
% if(sh == 0)
%     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
% elseif(sh == 1)
%     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)]) 
% end
[p2,sh2] = ranksum(MCSwithoutMPstratmass_list,MCSwithMPstratmass_list,'Alpha',alvl)
% text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
% if(sh2 == 0)
%     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
% elseif(sh2 == 1)
%     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
% end
ax = gca;
ax.FontSize = 15
xticks( [0:0.05:edges(end)] )
xlabel('MCS lifetime total stratiform rain mass [x10^1^3 kg]','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([0 1 0 0.14 ])



%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MCSIhist_stratrain_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime strat precip mass of : ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_largestratprecip_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total strat PF mass: ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) ' kg.  N = ', num2str(length(mplat_medMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_medstratprecip_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total strat PF mass: < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])


%saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_smallstratprecip_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)







if(filteroutLS==1)

    fact = 10^13 ;

    % condense [1:5] PF area stats 1-combined MCS pf area:
    stratrainmass_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    stratrainmass_MCSstats_ALLYRS_YESLSb(:) = NaN;
    stratrainmass_YESLS  =  stratrain_MCSstats_ALLYRS_YESLS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]

    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            %for t = 1:mtimes
            stratrainmass_MCSstats_ALLYRS_YESLSb(n,y)  =  sum (   stratrainmass_YESLS(:,n,y) , 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
            %end
        end
    end
    stratrainmass_MCSstats_ALLYRS_YESLSb(stratrainmass_MCSstats_ALLYRS_YESLSb==0) = NaN;


    MCSwithoutLSstratmass = stratrainmass_MCSstats_ALLYRSb(:);   MCSwithoutLSstratmass(MCSwithoutLSstratmass==0)=[];  MCSwithoutLSstratmass(isnan(MCSwithoutLSstratmass))=[];
    MCSwithLSstratmass = stratrainmass_MCSstats_ALLYRS_YESLSb(:);   MCSwithLSstratmass(MCSwithLSstratmass==0)=[];  MCSwithLSstratmass(isnan(MCSwithLSstratmass))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' Total lifetime accumulated strat rain mass for MCSs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:.05:4];
    hold on
    % hist(MCSwithoutMPtotmass_list/fact,edges);
    % h = findobj(gca,'Type','patch');
    % h.FaceColor = [0 0.5 0.5];
    % h.EdgeColor = [0 0 0];
    % hold on
    % hist(MCSwithMPtotmass_list/fact,edges);
    % h2 = findobj(gca,'Type','patch');
    % h2(1).FaceColor = [1 0.5 0];
    % h2(1).EdgeColor = [0 0 0];
    % h2(1).FaceAlpha = 0.8;
    [h1,b] = hist(MCSwithoutLSstratmass/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLSstratmass/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLSstratmass/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLSstratmass/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLSstratmass/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLSstratmass/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLSstratmass,MCSwithLSstratmass,'Alpha',alvl)
    % text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
    % if(sh == 0)
    %     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
    % elseif(sh == 1)
    %     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)])
    % end
    [p2,sh2] = ranksum(MCSwithoutLSstratmass,MCSwithLSstratmass,'Alpha',alvl)
    % text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
    % if(sh2 == 0)
    %     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    % elseif(sh2 == 1)
    %     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    % end
    ax = gca;
    ax.FontSize = 15
    xticks( [0:0.1:edges(end)] )
    xlabel('MCS lifetime total strat rain mass [x10^1^3 kg]','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 edges(end) 0 0.22 ])

    saveas(ff,horzcat(imout,'/MCSIhist_stratrain_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
    outlab = horzcat(imout,'/MCSIhist_stratrain_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);







    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_list/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_list/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' Total stratiform rain mass of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:.05:4];
    hold on
    [h1,b] = hist(MCSwithLSstratmass/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPstratmass_list/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPstratmass_list/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLSstratmass/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLSstratmass/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPstratmass_list/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPstratmass_list/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPstratmass_list/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPstratmass_list/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [0:0.1:edges(end)] )
    xlabel('MCS lifetime total strat rain mass [x10^1^3 kg]','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 2.5 0 0.25 ])

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_stratrainmass_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LSMPMCS_stratrainmass_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSstratmass(:),MCSwithMPstratmass_list(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSstratmass(:),MCSwithMPstratmass_list(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPstratmass_list(:),MCSwithoutMPstratmass_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPstratmass_list(:),MCSwithoutMPstratmass_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSstratmass(:),MCSwithoutMPstratmass_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSstratmass(:),MCSwithoutMPstratmass_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end








%%%%%%%%%%%%%%%%%%
%%%  convective/stratiform tot rain mass ratio
%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to total conv/strat RAINFALL MASS of MCSs with Syn objs present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% condense [1:5] PF area stats 1-combined MCS pf area:
stratrainmass_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    stratrainmass_MCSstats_ALLYRSb(:) = NaN; 
stratrainmass  =  stratrain_MCSstats_ALLYRS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        %for t = 1:mtimes
            stratrainmass_MCSstats_ALLYRSb(n,y)  =  sum (   stratrainmass(:,n,y) , 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
        %end
    end
end
stratrainmass_MCSstats_ALLYRSb(stratrainmass_MCSstats_ALLYRSb==0) = NaN;


convrainmass_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    convrainmass_MCSstats_ALLYRSb(:) = NaN; 
convrainmass  =  convrain_MCSstats_ALLYRS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        %for t = 1:mtimes
            convrainmass_MCSstats_ALLYRSb(n,y)  =  sum (   convrainmass(:,n,y) , 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
        %end
    end
end
convrainmass_MCSstats_ALLYRSb(convrainmass_MCSstats_ALLYRSb==0) = NaN;


csratrainmass_MCSstats_ALLYRSb = convrainmass_MCSstats_ALLYRSb ./ stratrainmass_MCSstats_ALLYRSb;




fact = 10^13 ;



%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hitotmass  = [0.60000000000001, 10] ;
medtotmass = [0.40000000000000001, 0.6] ;
lototmass  = [0, 0.4] ;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPcsrat_mass = [];
MCSwithoutMPcsrat_mass = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPcsrat_mass = vertcat( MCSwithMPcsrat_mass, csratrainmass_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(csratrainmass_MCSstats_ALLYRSb(n,y))==0  &  csratrainmass_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(csratrainmass_MCSstats_ALLYRSb(n,y))==0  &  csratrainmass_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  csratrainmass_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(csratrainmass_MCSstats_ALLYRSb(n,y))==0  &  csratrainmass_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end
            
            
            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPcsrat_mass = vertcat(MCSwithoutMPcsrat_mass, csratrainmass_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)



%   figure; hist( vertcat(MCSwithoutMPtotmass_list , MCSwithMPtotmass_list ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:.05:2.5];
hold on
[h1,b] = hist(MCSwithoutMPcsrat_mass,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_mass,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPcsrat_mass,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPcsrat_mass,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPcsrat_mass,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPcsrat_mass,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPcsrat_mass,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' Ratio lifetime accumulated convective/stratiform rain mass for MCSs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPcsrat_mass,MCSwithMPcsrat_mass,'Alpha',alvl)

[p2,sh2] = ranksum(MCSwithoutMPcsrat_mass,MCSwithMPcsrat_mass,'Alpha',alvl)

ax = gca;
ax.FontSize = 15
xticks( [0:0.05:edges(end)] )
xlabel('MCS lifetime ratio convective/stratiform rain mass','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([0 2 0 0.14 ])



%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MCSIhist_csratrain_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime conv/strat precip mass ratio of : ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_largecsratmass_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total conv/strat PF mass ratio: ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) ' kg.  N = ', num2str(length(mplat_medMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_medcsratmass_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total conv/strat PF mass ratio: < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])


%saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_smallcsratmass_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)







if(filteroutLS==1)

    fact = 1.0 ;


    % condense [1:5] PF area stats 1-combined MCS pf area:
    stratrainmass_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    stratrainmass_MCSstats_ALLYRS_YESLSb(:) = NaN;
    stratrainmass_YESLS  =  stratrain_MCSstats_ALLYRS_YESLS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            %for t = 1:mtimes
            stratrainmass_MCSstats_ALLYRS_YESLSb(n,y)  =  sum (   stratrainmass_YESLS(:,n,y) , 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
            %end
        end
    end
    stratrainmass_MCSstats_ALLYRS_YESLSb(stratrainmass_MCSstats_ALLYRS_YESLSb==0) = NaN;


    convrainmass_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    convrainmass_MCSstats_ALLYRS_YESLSb(:) = NaN;
    convrainmass_YESLS  =  convrain_MCSstats_ALLYRS_YESLS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            %for t = 1:mtimes
            convrainmass_MCSstats_ALLYRS_YESLSb(n,y)  =  sum (   convrainmass_YESLS(:,n,y) , 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
            %end
        end
    end
    convrainmass_MCSstats_ALLYRS_YESLSb(convrainmass_MCSstats_ALLYRS_YESLSb==0) = NaN;

    csratrainmass_MCSstats_ALLYRS_YESLSb = convrainmass_MCSstats_ALLYRS_YESLSb ./ stratrainmass_MCSstats_ALLYRS_YESLSb;






    MCSwithoutLScsratmass = csratrainmass_MCSstats_ALLYRSb(:);   MCSwithoutLScsratmass(MCSwithoutLScsratmass==0)=[];  MCSwithoutLScsratmass(isnan(MCSwithoutLScsratmass))=[];
    MCSwithLScsratmass = csratrainmass_MCSstats_ALLYRS_YESLSb(:);   MCSwithLScsratmass(MCSwithLScsratmass==0)=[];  MCSwithLScsratmass(isnan(MCSwithLScsratmass))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' Total lifetime accumulated conv/strat rain mass ratio for MCSs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:.05:4];
    hold on
    [h1,b] = hist(MCSwithoutLScsratmass/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_mass,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLScsratmass/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLScsratmass/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLScsratmass/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLScsratmass/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLScsratmass/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLScsratmass,MCSwithLScsratmass,'Alpha',alvl)

    [p2,sh2] = ranksum(MCSwithoutLScsratmass,MCSwithLScsratmass,'Alpha',alvl)

    ax = gca;
    ax.FontSize = 15
    xticks( [0:0.1:edges(end)] )
    xlabel('MCS lifetime total conv/strat rain mass ratio','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 2 0 0.12 ])

    saveas(ff,horzcat(imout,'/MCSIhist_csratmass_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
    outlab = horzcat(imout,'/MCSIhist_csratmass_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);







    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_mass/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_mass/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' Ratio total conv/strat rain mass of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:.05:4];
    hold on
    [h1,b] = hist(MCSwithLScsratmass/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_mass,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPcsrat_mass/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPcsrat_mass/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLScsratmass/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLScsratmass/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPcsrat_mass/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPcsrat_mass/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPcsrat_mass/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPcsrat_mass/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [0:0.1:edges(end)] )
    xlabel('MCS lifetime conv/strat ratio rain mass','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 2 0 0.12 ])

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_csratrainmass_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LSMPMCS_csratrainmass_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLScsratmass(:),MCSwithMPcsrat_mass(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLScsratmass(:),MCSwithMPcsrat_mass(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPcsrat_mass(:),MCSwithoutMPcsrat_mass,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPcsrat_mass(:),MCSwithoutMPcsrat_mass,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLScsratmass(:),MCSwithoutMPcsrat_mass,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLScsratmass(:),MCSwithoutMPcsrat_mass,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end













%%%%%%%%%%%%%%%%%%
%%%  convective rain area
%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to total conv/strat RAINFALL area of MCSs with Syn objs present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
stratrainarea_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    stratrainarea_MCSstats_ALLYRSb(:) = NaN; 
pfsum = sum( pf_stratarea_MCSstats_ALLYRS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
        if( length(blah) < 2 )
            stratrainarea_MCSstats_ALLYRSb(n,y)  =  blah(1) ;   
        else
            stratrainarea_MCSstats_ALLYRSb(n,y)  =  NaN ;            
        end
    end
end
stratrainarea_MCSstats_ALLYRSb(stratrainarea_MCSstats_ALLYRSb==0) = NaN;


%%%%%%
convrainarea_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    convrainarea_MCSstats_ALLYRSb(:) = NaN; 
pfsum = sum( pf_convarea_MCSstats_ALLYRS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
        if( length(blah) < 2 )
            convrainarea_MCSstats_ALLYRSb(n,y)  =  blah(1) ;   
        else
            convrainarea_MCSstats_ALLYRSb(n,y)  =  NaN ;            
        end
    end
end
convrainarea_MCSstats_ALLYRSb(convrainarea_MCSstats_ALLYRSb==0) = NaN;
csratrainarea_MCSstats_ALLYRSb = convrainarea_MCSstats_ALLYRSb ./ stratrainarea_MCSstats_ALLYRSb;


fact = 10^4 ;

%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed area bins of mcs :
hitotmass  = [15000.0000000000001, 10000000] ;
medtotmass = [9500.0000000000001, 15000.0] ;
lototmass  = [0, 9500.] ;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPconvarea = [];
MCSwithoutMPconvarea = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPconvarea = vertcat( MCSwithMPconvarea, convrainarea_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(convrainarea_MCSstats_ALLYRSb(n,y))==0  &  convrainarea_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
            elseif(  isnan(convrainarea_MCSstats_ALLYRSb(n,y))==0  &  convrainarea_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  convrainarea_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end

            elseif(  isnan(convrainarea_MCSstats_ALLYRSb(n,y))==0  &  convrainarea_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end

            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPconvarea = vertcat(MCSwithoutMPconvarea, convrainarea_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)

%   figure; hist( vertcat(MCSwithoutMPtotmass_area , MCSwithMPtotmass_area ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:1000:50000];
hold on

[h1,b] = hist(MCSwithoutMPconvarea,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_area,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPconvarea,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPconvarea,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPconvarea,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPconvarea,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPconvarea,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' convective  max rain area for MCSs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPconvarea,MCSwithMPconvarea,'Alpha',alvl)

[p2,sh2] = ranksum(MCSwithoutMPconvarea,MCSwithMPconvarea,'Alpha',alvl)

ax = gca;
ax.FontSize = 15
xticks( [0:1000:edges(end)] )
xlabel('MCS lifetime max convective  rain area','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
%axis([0 1.5 0 0.18])



%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MCSIhist_convarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime conv precip area of : ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_largeconvarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max conv area : ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) ' kg.  N = ', num2str(length(mplat_medMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_medconvarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max conv PF area : < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])


%saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_smallconvarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)




if(filteroutLS==1)

    fact = 1.0 ;

    %%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
    stratrainarea_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    stratrainarea_MCSstats_ALLYRS_YESLSb(:) = NaN;
    pfsum = sum( pf_stratarea_MCSstats_ALLYRS_YESLS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
            if( length(blah) < 2 )
                stratrainarea_MCSstats_ALLYRS_YESLSb(n,y)  =  blah(1) ;
            else
                stratrainarea_MCSstats_ALLYRS_YESLSb(n,y)  =  NaN ;
            end
        end
    end
    stratrainarea_MCSstats_ALLYRS_YESLSb(stratrainarea_MCSstats_ALLYRS_YESLSb==0) = NaN;


    %%%%%%
    convrainarea_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    convrainarea_MCSstats_ALLYRS_YESLSb(:) = NaN;
    pfsum = sum( pf_convarea_MCSstats_ALLYRS_YESLS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
            if( length(blah) < 2 )
                convrainarea_MCSstats_ALLYRS_YESLSb(n,y)  =  blah(1) ;
            else
                convrainarea_MCSstats_ALLYRS_YESLSb(n,y)  =  NaN ;
            end
        end
    end
    convrainarea_MCSstats_ALLYRS_YESLSb(convrainarea_MCSstats_ALLYRS_YESLSb==0) = NaN;

    csratrainarea_MCSstats_ALLYRS_YESLSb = convrainarea_MCSstats_ALLYRS_YESLSb ./ stratrainarea_MCSstats_ALLYRS_YESLSb;





    MCSwithoutLSconvarea = convrainarea_MCSstats_ALLYRSb(:);   MCSwithoutLSconvarea(MCSwithoutLSconvarea==0)=[];  MCSwithoutLSconvarea(isnan(MCSwithoutLSconvarea))=[];
    MCSwithLSconvarea = convrainarea_MCSstats_ALLYRS_YESLSb(:);   MCSwithLSconvarea(MCSwithLSconvarea==0)=[];  MCSwithLSconvarea(isnan(MCSwithLSconvarea))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' Total lifetime max  conv rain mass for MCSs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:1000:50000];
    hold on

    [h1,b] = hist(MCSwithoutLSconvarea/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_area,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLSconvarea/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLSconvarea/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLSconvarea/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLSconvarea/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLSconvarea/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLSconvarea,MCSwithLSconvarea,'Alpha',alvl)

    [p2,sh2] = ranksum(MCSwithoutLSconvarea,MCSwithLSconvarea,'Alpha',alvl)

    ax = gca;
    ax.FontSize = 15
    xticks( [0:0.1:edges(end)] )
    xlabel('MCS lifetime max convrain area ','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 1.5 0 0.18 ])

    saveas(ff,horzcat(imout,'/MCSIhist_convarea_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
    outlab = horzcat(imout,'/MCSIhist_convarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);



    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_area/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_area/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' max conv rain area of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:1000:50000];
    hold on
    [h1,b] = hist(MCSwithLSconvarea/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_area,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPconvarea/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPconvarea/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLSconvarea/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLSconvarea/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPconvarea/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPconvarea/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPconvarea/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPconvarea/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [0:1000:edges(end)] )
    xlabel('MCS lifetime max conv area  ','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 1.25 0 0.12 ])

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_convarea_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LSMPMCS_convarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSconvarea(:),MCSwithMPconvarea(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSconvarea(:),MCSwithMPconvarea(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPconvarea(:),MCSwithoutMPconvarea,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPconvarea(:),MCSwithoutMPconvarea,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSconvarea(:),MCSwithoutMPconvarea,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSconvarea(:),MCSwithoutMPconvarea,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end











%%%%%%%%%%%%%%%%%%
%%%  stratiform rain area
%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to total conv/strat RAINFALL area of MCSs with Syn objs present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
stratrainarea_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    stratrainarea_MCSstats_ALLYRSb(:) = NaN; 
pfsum = sum( pf_stratarea_MCSstats_ALLYRS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
        if( length(blah) < 2 )
            stratrainarea_MCSstats_ALLYRSb(n,y)  =  blah(1) ;   
        else
            stratrainarea_MCSstats_ALLYRSb(n,y)  =  NaN ;            
        end
    end
end
stratrainarea_MCSstats_ALLYRSb(stratrainarea_MCSstats_ALLYRSb==0) = NaN;


%%%%%%
convrainarea_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    convrainarea_MCSstats_ALLYRSb(:) = NaN; 
pfsum = sum( pf_convarea_MCSstats_ALLYRS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
        if( length(blah) < 2 )
            convrainarea_MCSstats_ALLYRSb(n,y)  =  blah(1) ;   
        else
            convrainarea_MCSstats_ALLYRSb(n,y)  =  NaN ;            
        end
    end
end
convrainarea_MCSstats_ALLYRSb(convrainarea_MCSstats_ALLYRSb==0) = NaN;
csratrainarea_MCSstats_ALLYRSb = convrainarea_MCSstats_ALLYRSb ./ stratrainarea_MCSstats_ALLYRSb;


fact = 10^13 ;

%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hitotmass  = [54000.0000000000001, 10000000] ;
medtotmass = [28000.0000000000001, 54000.0] ;
lototmass  = [0, 28000.] ;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPstratarea = [];
MCSwithoutMPstratarea = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPstratarea = vertcat( MCSwithMPstratarea, stratrainarea_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(stratrainarea_MCSstats_ALLYRSb(n,y))==0  &  stratrainarea_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
            elseif(  isnan(stratrainarea_MCSstats_ALLYRSb(n,y))==0  &  stratrainarea_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  stratrainarea_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end

            elseif(  isnan(stratrainarea_MCSstats_ALLYRSb(n,y))==0  &  stratrainarea_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end

            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPstratarea = vertcat(MCSwithoutMPstratarea, stratrainarea_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)

%   figure; hist( vertcat(MCSwithoutMPtotmass_area , MCSwithMPtotmass_area ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:1000:50000];
hold on

[h1,b] = hist(MCSwithoutMPstratarea,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_area,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPstratarea,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPstratarea,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPstratarea,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPstratarea,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPstratarea,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' convective  max rain area for MCSs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPstratarea,MCSwithMPstratarea,'Alpha',alvl)

[p2,sh2] = ranksum(MCSwithoutMPstratarea,MCSwithMPstratarea,'Alpha',alvl)

ax = gca;
ax.FontSize = 15
xticks( [0:1000:edges(end)] )
xlabel('MCS lifetime max stratiform rain area','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
%axis([0 1.5 0 0.18])



%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MCSIhist_stratarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime strat precip area of : ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_largestratarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max strat area : ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) ' kg.  N = ', num2str(length(mplat_medMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_medstratarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max strat PF area : < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])


%saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_smallstratarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)




if(filteroutLS==1)

    fact = 1.0 ;

    %%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
    stratrainarea_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    stratrainarea_MCSstats_ALLYRS_YESLSb(:) = NaN;
    pfsum = sum( pf_stratarea_MCSstats_ALLYRS_YESLS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
            if( length(blah) < 2 )
                stratrainarea_MCSstats_ALLYRS_YESLSb(n,y)  =  blah(1) ;
            else
                stratrainarea_MCSstats_ALLYRS_YESLSb(n,y)  =  NaN ;
            end
        end
    end
    stratrainarea_MCSstats_ALLYRS_YESLSb(stratrainarea_MCSstats_ALLYRS_YESLSb==0) = NaN;


    %%%%%%
    convrainarea_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    convrainarea_MCSstats_ALLYRS_YESLSb(:) = NaN;
    pfsum = sum( pf_stratarea_MCSstats_ALLYRS_YESLS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
            if( length(blah) < 2 )
                convrainarea_MCSstats_ALLYRS_YESLSb(n,y)  =  blah(1) ;
            else
                convrainarea_MCSstats_ALLYRS_YESLSb(n,y)  =  NaN ;
            end
        end
    end
    convrainarea_MCSstats_ALLYRS_YESLSb(convrainarea_MCSstats_ALLYRS_YESLSb==0) = NaN;

    csratrainarea_MCSstats_ALLYRS_YESLSb = convrainarea_MCSstats_ALLYRS_YESLSb ./ stratrainarea_MCSstats_ALLYRS_YESLSb;





    MCSwithoutLSstratarea = stratrainarea_MCSstats_ALLYRSb(:);   MCSwithoutLSstratarea(MCSwithoutLSstratarea==0)=[];  MCSwithoutLSstratarea(isnan(MCSwithoutLSstratarea))=[];
    MCSwithLSstratarea = stratrainarea_MCSstats_ALLYRS_YESLSb(:);   MCSwithLSstratarea(MCSwithLSstratarea==0)=[];  MCSwithLSstratarea(isnan(MCSwithLSstratarea))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' Total lifetime max  conv rain mass for MCSs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:1000:100000];
    hold on

    [h1,b] = hist(MCSwithoutLSstratarea/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_area,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLSstratarea/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLSstratarea/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLSstratarea/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLSstratarea/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLSstratarea/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLSstratarea,MCSwithLSstratarea,'Alpha',alvl)

    [p2,sh2] = ranksum(MCSwithoutLSstratarea,MCSwithLSstratarea,'Alpha',alvl)

    ax = gca;
    ax.FontSize = 15
    xticks( [0:0.1:edges(end)] )
    xlabel('MCS lifetime max stratrain area ','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 1.5 0 0.18 ])

    saveas(ff,horzcat(imout,'/MCSIhist_stratarea_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
    outlab = horzcat(imout,'/MCSIhist_stratarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);



    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_area/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_area/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' max strat rain area of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:10000:500000];
    hold on
    [h1,b] = hist(MCSwithLSstratarea/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_area,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPstratarea/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPstratarea/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLSstratarea/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLSstratarea/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPstratarea/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPstratarea/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPstratarea/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPstratarea/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [0:1000:edges(end)] )
    xlabel('MCS lifetime max strat area','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 1.25 0 0.12 ])

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_stratarea_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LSMPMCS_stratarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSstratarea(:),MCSwithMPstratarea(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSstratarea(:),MCSwithMPstratarea(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPstratarea(:),MCSwithoutMPstratarea,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPstratarea(:),MCSwithoutMPstratarea,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSstratarea(:),MCSwithoutMPstratarea,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSstratarea(:),MCSwithoutMPstratarea,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end

















%%%%%%%%%%%%%%%%%%
%%%  convective/stratiform rain area
%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to total conv/strat RAINFALL area of MCSs with Syn objs present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
stratrainarea_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    stratrainarea_MCSstats_ALLYRSb(:) = NaN; 
pfsum = sum( pf_stratarea_MCSstats_ALLYRS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
        if( length(blah) < 2 )
            stratrainarea_MCSstats_ALLYRSb(n,y)  =  blah(1) ;   
        else
            stratrainarea_MCSstats_ALLYRSb(n,y)  =  NaN ;            
        end
    end
end
stratrainarea_MCSstats_ALLYRSb(stratrainarea_MCSstats_ALLYRSb==0) = NaN;


%%%%%%
convrainarea_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    convrainarea_MCSstats_ALLYRSb(:) = NaN; 
pfsum = sum( pf_convarea_MCSstats_ALLYRS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
        if( length(blah) < 2 )
            convrainarea_MCSstats_ALLYRSb(n,y)  =  blah(1) ;   
        else
            convrainarea_MCSstats_ALLYRSb(n,y)  =  NaN ;            
        end
    end
end
convrainarea_MCSstats_ALLYRSb(convrainarea_MCSstats_ALLYRSb==0) = NaN;

csratrainarea_MCSstats_ALLYRSb = convrainarea_MCSstats_ALLYRSb ./ stratrainarea_MCSstats_ALLYRSb;




fact = 10^13 ;

%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hitotmass  = [0.380000000000001, 10] ;
medtotmass = [0.260000000000000001, 0.38] ;
lototmass  = [0, 0.26] ;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPcsrat_area = [];
MCSwithoutMPcsrat_area = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPcsrat_area = vertcat( MCSwithMPcsrat_area, csratrainarea_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(csratrainarea_MCSstats_ALLYRSb(n,y))==0  &  csratrainarea_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
            elseif(  isnan(csratrainarea_MCSstats_ALLYRSb(n,y))==0  &  csratrainarea_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  csratrainarea_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end

            elseif(  isnan(csratrainarea_MCSstats_ALLYRSb(n,y))==0  &  csratrainarea_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end

            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPcsrat_area = vertcat(MCSwithoutMPcsrat_area, csratrainarea_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)

%   figure; hist( vertcat(MCSwithoutMPtotmass_area , MCSwithMPtotmass_area ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:.05:2.5];
hold on

[h1,b] = hist(MCSwithoutMPcsrat_area,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_area,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPcsrat_area,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPcsrat_area,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPcsrat_area,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPcsrat_area,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPcsrat_area,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' Ratio lifetime accumulated convective/stratiform rain area for MCSs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPcsrat_area,MCSwithMPcsrat_area,'Alpha',alvl)

[p2,sh2] = ranksum(MCSwithoutMPcsrat_area,MCSwithMPcsrat_area,'Alpha',alvl)

ax = gca;
ax.FontSize = 15
xticks( [0:0.05:edges(end)] )
xlabel('MCS lifetime ratio convective/stratiform rain area','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([0 1.5 0 0.18])



%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MCSIhist_csratarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime conv/strat precip area ratio of : ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_largecsratarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total conv/strat PF area ratio: ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) ' kg.  N = ', num2str(length(mplat_medMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_medcsratarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total conv/strat PF area ratio: < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])


%saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_smallcsratarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)







if(filteroutLS==1)

    fact = 1.0 ;

    %%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
    stratrainarea_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    stratrainarea_MCSstats_ALLYRS_YESLSb(:) = NaN;
    pfsum = sum( pf_stratarea_MCSstats_ALLYRS_YESLS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
            if( length(blah) < 2 )
                stratrainarea_MCSstats_ALLYRS_YESLSb(n,y)  =  blah(1) ;
            else
                stratrainarea_MCSstats_ALLYRS_YESLSb(n,y)  =  NaN ;
            end
        end
    end
    stratrainarea_MCSstats_ALLYRS_YESLSb(stratrainarea_MCSstats_ALLYRS_YESLSb==0) = NaN;


    %%%%%%
    convrainarea_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    convrainarea_MCSstats_ALLYRS_YESLSb(:) = NaN;
    pfsum = sum( pf_convarea_MCSstats_ALLYRS_YESLS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
            if( length(blah) < 2 )
                convrainarea_MCSstats_ALLYRS_YESLSb(n,y)  =  blah(1) ;
            else
                convrainarea_MCSstats_ALLYRS_YESLSb(n,y)  =  NaN ;
            end
        end
    end
    convrainarea_MCSstats_ALLYRS_YESLSb(convrainarea_MCSstats_ALLYRS_YESLSb==0) = NaN;

    csratrainarea_MCSstats_ALLYRS_YESLSb = convrainarea_MCSstats_ALLYRS_YESLSb ./ stratrainarea_MCSstats_ALLYRS_YESLSb;





    MCSwithoutLScsratarea = csratrainarea_MCSstats_ALLYRSb(:);   MCSwithoutLScsratarea(MCSwithoutLScsratarea==0)=[];  MCSwithoutLScsratarea(isnan(MCSwithoutLScsratarea))=[];
    MCSwithLScsratarea = csratrainarea_MCSstats_ALLYRS_YESLSb(:);   MCSwithLScsratarea(MCSwithLScsratarea==0)=[];  MCSwithLScsratarea(isnan(MCSwithLScsratarea))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' Total lifetime accumulated conv/strat rain mass ratio for MCSs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:.05:4];
    hold on

    [h1,b] = hist(MCSwithoutLScsratarea/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_area,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLScsratarea/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLScsratarea/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLScsratarea/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLScsratarea/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLScsratarea/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLScsratmass,MCSwithLScsratarea,'Alpha',alvl)

    [p2,sh2] = ranksum(MCSwithoutLScsratmass,MCSwithLScsratarea,'Alpha',alvl)

    ax = gca;
    ax.FontSize = 15
    xticks( [0:0.1:edges(end)] )
    xlabel('MCS lifetime total conv/strat rain area ratio','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 1.5 0 0.18 ])

    saveas(ff,horzcat(imout,'/MCSIhist_csratarea_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
    outlab = horzcat(imout,'/MCSIhist_csratarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);







    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_area/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_area/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' Ratio total conv/strat rain area of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:.025:4];
    hold on
    [h1,b] = hist(MCSwithLScsratarea/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_area,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPcsrat_area/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPcsrat_area/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLScsratarea/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLScsratarea/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPcsrat_area/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPcsrat_area/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPcsrat_area/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPcsrat_area/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [0:0.05:edges(end)] )
    xlabel('MCS lifetime total conv/strat area ratio ','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 1.25 0 0.12 ])

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_csratrainarea_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LSMPMCS_csratrainarea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLScsratarea(:),MCSwithMPcsrat_area(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLScsratarea(:),MCSwithMPcsrat_area(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPcsrat_area(:),MCSwithoutMPcsrat_area,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPcsrat_area(:),MCSwithoutMPcsrat_area,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLScsratarea(:),MCSwithoutMPcsrat_area,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLScsratarea(:),MCSwithoutMPcsrat_area,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end











%%%%%%%%%%%%%%%%%%
%%%  convective/stratiform rain rate
%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to total conv/strat RAINFALL rate of MCSs with Syn objs present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
stratrainrate_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    stratrainrate_MCSstats_ALLYRSb(:) = NaN; 
pfsum = sum( pf_stratrate_MCSstats_ALLYRS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
        if( length(blah) < 2 )
            stratrainrate_MCSstats_ALLYRSb(n,y)  =  blah(1) ;   
        else
            stratrainrate_MCSstats_ALLYRSb(n,y)  =  NaN ;            
        end
    end
end
stratrainrate_MCSstats_ALLYRSb(stratrainrate_MCSstats_ALLYRSb==0) = NaN;


%%%%%%
convrainrate_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    convrainrate_MCSstats_ALLYRSb(:) = NaN; 
pfsum = sum( pf_convrate_MCSstats_ALLYRS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
        if( length(blah) < 2 )
            convrainrate_MCSstats_ALLYRSb(n,y)  =  blah(1) ;   
        else
            convrainrate_MCSstats_ALLYRSb(n,y)  =  NaN ;            
        end
    end
end
convrainrate_MCSstats_ALLYRSb(convrainrate_MCSstats_ALLYRSb==0) = NaN;

csratrainrate_MCSstats_ALLYRSb = convrainrate_MCSstats_ALLYRSb ./ stratrainrate_MCSstats_ALLYRSb;




fact = 10^13 ;

%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs 
hitotmass  = [1.240000000000001, 10] ;
medtotmass = [1.05000000000000001, 1.24] ;
lototmass  = [0, 1.05] ;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPcsrat_rate = [];
MCSwithoutMPcsrat_rate = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPcsrat_rate = vertcat( MCSwithMPcsrat_rate, csratrainrate_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(csratrainrate_MCSstats_ALLYRSb(n,y))==0  &  csratrainrate_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
            elseif(  isnan(csratrainrate_MCSstats_ALLYRSb(n,y))==0  &  csratrainrate_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  csratrainrate_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end

            elseif(  isnan(csratrainrate_MCSstats_ALLYRSb(n,y))==0  &  csratrainrate_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end

            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPcsrat_rate = vertcat(MCSwithoutMPcsrat_rate, csratrainrate_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)

%   figure; hist( vertcat(MCSwithoutMPtotmass_rate , MCSwithMPtotmass_rate ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:.05:2.5];
hold on

[h1,b] = hist(MCSwithoutMPcsrat_rate,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_rate,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPcsrat_rate,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPcsrat_rate,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPcsrat_rate,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPcsrat_rate,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPcsrat_rate,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' Ratio lifetime accumulated convective/stratiform rain rate for MCSs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPcsrat_rate,MCSwithMPcsrat_rate,'Alpha',alvl)

[p2,sh2] = ranksum(MCSwithoutMPcsrat_rate,MCSwithMPcsrat_rate,'Alpha',alvl)

ax = gca;
ax.FontSize = 15
xticks( [0:0.05:edges(end)] )
xlabel('MCS lifetime ratio convective/stratiform rain rate','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([0.5 2 0 0.14])



%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MCSIhist_csratrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime conv/strat precip rate ratio of : ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_largecsratrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total conv/strat PF rate ratio: ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) ' kg.  N = ', num2str(length(mplat_medMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_medcsratrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total conv/strat PF rate ratio: < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])


%saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_smallcsratrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)







if(filteroutLS==1)

    fact = 1.0 ;

    %%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
    stratrainrate_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    stratrainrate_MCSstats_ALLYRS_YESLSb(:) = NaN;
    pfsum = sum( pf_stratrate_MCSstats_ALLYRS_YESLS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
            if( length(blah) < 2 )
                stratrainrate_MCSstats_ALLYRS_YESLSb(n,y)  =  blah(1) ;
            else
                stratrainrate_MCSstats_ALLYRS_YESLSb(n,y)  =  NaN ;
            end
        end
    end
    stratrainrate_MCSstats_ALLYRS_YESLSb(stratrainrate_MCSstats_ALLYRS_YESLSb==0) = NaN;


    %%%%%%
    convrainrate_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    convrainrate_MCSstats_ALLYRS_YESLSb(:) = NaN;
    pfsum = sum( pf_convrate_MCSstats_ALLYRS_YESLS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
            if( length(blah) < 2 )
                convrainrate_MCSstats_ALLYRS_YESLSb(n,y)  =  blah(1) ;
            else
                convrainrate_MCSstats_ALLYRS_YESLSb(n,y)  =  NaN ;
            end
        end
    end
    convrainrate_MCSstats_ALLYRS_YESLSb(convrainrate_MCSstats_ALLYRS_YESLSb==0) = NaN;

    csratrainrate_MCSstats_ALLYRS_YESLSb = convrainrate_MCSstats_ALLYRS_YESLSb ./ stratrainrate_MCSstats_ALLYRS_YESLSb;





    MCSwithoutLScsratrate = csratrainrate_MCSstats_ALLYRSb(:);   MCSwithoutLScsratrate(MCSwithoutLScsratrate==0)=[];  MCSwithoutLScsratrate(isnan(MCSwithoutLScsratrate))=[];
    MCSwithLScsratrate = csratrainrate_MCSstats_ALLYRS_YESLSb(:);   MCSwithLScsratrate(MCSwithLScsratrate==0)=[];  MCSwithLScsratrate(isnan(MCSwithLScsratrate))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' Total lifetime accumulated conv/strat rain rate ratio for MCSs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:.05:4];
    hold on
    [h1,b] = hist(MCSwithoutLScsratrate/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_rate,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLScsratrate/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLScsratrate/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLScsratrate/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLScsratrate/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLScsratrate/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLScsratrate,MCSwithLScsratrate,'Alpha',alvl)
    % text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
    % if(sh == 0)
    %     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
    % elseif(sh == 1)
    %     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)])
    % end
    [p2,sh2] = ranksum(MCSwithoutLScsratrate,MCSwithLScsratrate,'Alpha',alvl)
    % text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
    % if(sh2 == 0)
    %     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    % elseif(sh2 == 1)
    %     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    % end
    ax = gca;
    ax.FontSize = 15
    xticks( [0:0.1:edges(end)] )
    xlabel('MCS lifetime total conv/strat rain rate ratio','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 1.5 0 0.18 ])

    saveas(ff,horzcat(imout,'/MCSIhist_csratrate_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
    outlab = horzcat(imout,'/MCSIhist_csratrainrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);







    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_rate/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_rate/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' Ratio total conv/strat rain rate of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:.025:4];
    hold on
    [h1,b] = hist(MCSwithLScsratrate/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_rate,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPcsrat_rate/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPcsrat_rate/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLScsratrate/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLScsratrate/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPcsrat_rate/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPcsrat_rate/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPcsrat_rate/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPcsrat_rate/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [0:0.05:edges(end)] )
    xlabel('MCS lifetime total conv/strat rate ratio ','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0.5 2 0 0.08 ])

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_csratrainrate_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LSMPMCS_csratrainrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLScsratrate(:),MCSwithMPcsrat_rate(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLScsratrate(:),MCSwithMPcsrat_rate(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPcsrat_rate(:),MCSwithoutMPcsrat_rate,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPcsrat_rate(:),MCSwithoutMPcsrat_rate,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLScsratrate(:),MCSwithoutMPcsrat_rate,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLScsratrate(:),MCSwithoutMPcsrat_rate,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end













%%%%%%%%%%%%%%%%%%
%%%  stratiform rain rate
%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to total strat RAINFALL rate of MCSs with Syn objs present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
stratrainrate_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    stratrainrate_MCSstats_ALLYRSb(:) = NaN; 
pfsum = sum( pf_stratrate_MCSstats_ALLYRS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
        if( length(blah) < 2 )
            stratrainrate_MCSstats_ALLYRSb(n,y)  =  blah(1) ;   
        else
            stratrainrate_MCSstats_ALLYRSb(n,y)  =  NaN ;            
        end
    end
end
stratrainrate_MCSstats_ALLYRSb(stratrainrate_MCSstats_ALLYRSb==0) = NaN;


fact = 1 ;

%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs 
hitotmass  = [44.5000000000001, 100] ;
medtotmass = [36.0000000000000001, 44.5] ;
lototmass  = [0, 36.] ;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPstratrate = [];
MCSwithoutMPstratrate = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPstratrate = vertcat( MCSwithMPstratrate, stratrainrate_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(stratrainrate_MCSstats_ALLYRSb(n,y))==0  &  stratrainrate_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
            elseif(  isnan(stratrainrate_MCSstats_ALLYRSb(n,y))==0  &  stratrainrate_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  stratrainrate_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end

            elseif(  isnan(stratrainrate_MCSstats_ALLYRSb(n,y))==0  &  stratrainrate_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end

            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPstratrate = vertcat(MCSwithoutMPstratrate, stratrainrate_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)

%   figure; hist( vertcat(MCSwithoutMPtotmass_list , MCSwithMPtotmass_list ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:2:80];
hold on

[h1,b] = hist(MCSwithoutMPstratrate,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPstratrate,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPstratrate,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPstratrate,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPstratrate,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPstratrate,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' max lifetime stratiform rain rate for MCSs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPstratrate,MCSwithMPstratrate,'Alpha',alvl)

[p2,sh2] = ranksum(MCSwithoutMPstratrate,MCSwithMPstratrate,'Alpha',alvl)

ax = gca;
ax.FontSize = 15
xticks( [0:2:80] )
xlabel('MCS lifetime max stratiform rain rate','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([8 80 0 0.1])



%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MCSIhist_stratrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime strat precip rate : ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_largestratrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);




%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total strat PF rate : ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) ' kg.  N = ', num2str(length(mplat_medMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_medstratrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total strat PF rate: < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])


%saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_smallstratrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)




if(filteroutLS==1)

    fact = 1.0 ;

    %%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
    stratrainrate_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    stratrainrate_MCSstats_ALLYRS_YESLSb(:) = NaN;
    pfsum = sum( pf_stratrate_MCSstats_ALLYRS_YESLS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
            if( length(blah) < 2 )
                stratrainrate_MCSstats_ALLYRS_YESLSb(n,y)  =  blah(1) ;
            else
                stratrainrate_MCSstats_ALLYRS_YESLSb(n,y)  =  NaN ;
            end
        end
    end
    stratrainrate_MCSstats_ALLYRS_YESLSb(stratrainrate_MCSstats_ALLYRS_YESLSb==0) = NaN;



    MCSwithoutLSstratrate = stratrainrate_MCSstats_ALLYRSb(:);   MCSwithoutLSstratrate(MCSwithoutLSstratrate==0)=[];  MCSwithoutLSstratrate(isnan(MCSwithoutLSstratrate))=[];
    MCSwithLSstratrate = stratrainrate_MCSstats_ALLYRS_YESLSb(:);   MCSwithLSstratrate(MCSwithLSstratrate==0)=[];  MCSwithLSstratrate(isnan(MCSwithLSstratrate))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' max lifetime accumulated strat rain rate for MCSs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:2:90];
    hold on
    [h1,b] = hist(MCSwithoutLSstratrate/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLSstratrate/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLSstratrate/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLSstratrate/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLSstratrate/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLSstratrate/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLSstratrate,MCSwithLSstratrate,'Alpha',alvl)
    % text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
    % if(sh == 0)
    %     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
    % elseif(sh == 1)
    %     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)])
    % end
    [p2,sh2] = ranksum(MCSwithoutLSstratrate,MCSwithLSstratrate,'Alpha',alvl)
    % text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
    % if(sh2 == 0)
    %     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    % elseif(sh2 == 1)
    %     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    % end
    ax = gca;
    ax.FontSize = 15
    xticks( [0:2:edges(end)] )
    xlabel('MCS lifetime max strat rain rate ','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([8 80 0 0.1 ])

    saveas(ff,horzcat(imout,'/MCSIhist_stratrate_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
    outlab = horzcat(imout,'/MCSIhist_stratrainrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);


    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_list/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_list/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' max strat rain rate of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:2:90];
    hold on
    [h1,b] = hist(MCSwithLSstratrate/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPstratrate/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPstratrate/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLSstratrate/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLSstratrate/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPstratrate/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPstratrate/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPstratrate/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPstratrate/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [0:2:90] )
    xlabel('MCS lifetime max strat rate ','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([8 80 0 0.1 ])

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_stratrainrate_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LSMPMCS_stratrainrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSstratrate(:),MCSwithMPstratrate(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSstratrate(:),MCSwithMPstratrate(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPstratrate(:),MCSwithoutMPstratrate,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPstratrate(:),MCSwithoutMPstratrate,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSstratrate(:),MCSwithoutMPstratrate,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSstratrate(:),MCSwithoutMPstratrate,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end













%%%%%%%%%%%%%%%%%%
%%%  convective rain rate
%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to total conv rate of MCSs with Syn objs present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
convrainrate_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    convrainrate_MCSstats_ALLYRSb(:) = NaN; 
pfsum = sum( pf_convrate_MCSstats_ALLYRS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
        if( length(blah) < 2 )
            convrainrate_MCSstats_ALLYRSb(n,y)  =  blah(1) ;   
        else
            convrainrate_MCSstats_ALLYRSb(n,y)  =  NaN ;            
        end
    end
end
convrainrate_MCSstats_ALLYRSb(convrainrate_MCSstats_ALLYRSb==0) = NaN;


fact = 1 ;

%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs 
hitotmass  = [52.000000000001, 100] ;
medtotmass = [39.0000000000000001, 52.] ;
lototmass  = [0, 39.] ;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPconvrate = [];
MCSwithoutMPconvrate = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPconvrate = vertcat( MCSwithMPconvrate, convrainrate_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(convrainrate_MCSstats_ALLYRSb(n,y))==0  &  convrainrate_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
            elseif(  isnan(convrainrate_MCSstats_ALLYRSb(n,y))==0  &  convrainrate_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  convrainrate_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end

            elseif(  isnan(convrainrate_MCSstats_ALLYRSb(n,y))==0  &  convrainrate_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end

            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPconvrate = vertcat(MCSwithoutMPconvrate, convrainrate_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)

%   figure; hist( vertcat(MCSwithoutMPtotmass_list , MCSwithMPtotmass_list ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:2:100];
hold on

[h1,b] = hist(MCSwithoutMPconvrate,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPconvrate,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPconvrate,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPconvrate,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPconvrate,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPconvrate,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' max lifetime convective rain rate for MCSs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPconvrate,MCSwithMPconvrate,'Alpha',alvl)

[p2,sh2] = ranksum(MCSwithoutMPconvrate,MCSwithMPconvrate,'Alpha',alvl)

ax = gca;
ax.FontSize = 15
xticks( [0:2:96] )
xlabel('MCS lifetime max convective rain rate','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([8 96 0 0.1])



%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MCSIhist_convrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime conv precip rate : ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_largeconvrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total conv PF rate : ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) '.  N = ', num2str(length(mplat_medMCS)) ])

%saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_medconvrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max total conv PF rate: < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])


%saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
outlab = horzcat(imout,'/MPorigin_smallconvrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)







if(filteroutLS==1)

    fact = 1.0 ;

    %%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
    convrainrate_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    convrainrate_MCSstats_ALLYRS_YESLSb(:) = NaN;
    pfsum = sum( pf_convrate_MCSstats_ALLYRS_YESLS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
            if( length(blah) < 2 )
                convrainrate_MCSstats_ALLYRS_YESLSb(n,y)  =  blah(1) ;
            else
                convrainrate_MCSstats_ALLYRS_YESLSb(n,y)  =  NaN ;
            end
        end
    end
    convrainrate_MCSstats_ALLYRS_YESLSb(convrainrate_MCSstats_ALLYRS_YESLSb==0) = NaN;



    MCSwithoutLSconvrate = convrainrate_MCSstats_ALLYRSb(:);   MCSwithoutLSconvrate(MCSwithoutLSconvrate==0)=[];  MCSwithoutLSconvrate(isnan(MCSwithoutLSconvrate))=[];
    MCSwithLSconvrate = convrainrate_MCSstats_ALLYRS_YESLSb(:);   MCSwithLSconvrate(MCSwithLSconvrate==0)=[];  MCSwithLSconvrate(isnan(MCSwithLSconvrate))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' max lifetime accumulated conv rain rate for MCSs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:2:110];
    hold on
    [h1,b] = hist(MCSwithoutLSconvrate/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLSconvrate/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLSconvrate/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLSconvrate/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLSconvrate/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLSconvrate/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLSconvrate,MCSwithLSconvrate,'Alpha',alvl)
    % text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
    % if(sh == 0)
    %     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
    % elseif(sh == 1)
    %     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)])
    % end
    [p2,sh2] = ranksum(MCSwithoutLSconvrate,MCSwithLSconvrate,'Alpha',alvl)
    % text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
    % if(sh2 == 0)
    %     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    % elseif(sh2 == 1)
    %     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    % end
    ax = gca;
    ax.FontSize = 15
    xticks( [0:2:edges(end)] )
    xlabel('MCS lifetime max conv rain rate ','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([6 100 0 0.1 ])

    saveas(ff,horzcat(imout,'/MCSIhist_convrate_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
    outlab = horzcat(imout,'/MCSIhist_convrainrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);







    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_list/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_list/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' max conv rain rate of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:2:120];
    hold on
    [h1,b] = hist(MCSwithLSconvrate/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPconvrate/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPconvrate/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLSconvrate/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLSconvrate/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPconvrate/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPconvrate/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPconvrate/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPconvrate/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [0:2:130] )
    xlabel('MCS lifetime max conv rate ','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([6 98 0 0.1 ])

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_convrainrate_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_LSMPMCS_convrainrate_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSconvrate(:),MCSwithMPconvrate(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSconvrate(:),MCSwithMPconvrate(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPconvrate(:),MCSwithoutMPconvrate,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPconvrate(:),MCSwithoutMPconvrate,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSconvrate(:),MCSwithoutMPconvrate,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSconvrate(:),MCSwithoutMPconvrate,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end









%%%%%%%%%%%%%%%%%%
%%%  accumulated heavy rain
%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to total conv rate of MCSs with Syn objs present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
pf_accumrainheavy_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    pf_accumrainheavy_MCSstats_ALLYRSb(:) = NaN; 
pfsum = sum( pf_accumrainheavy_MCSstats_ALLYRS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
        if( length(blah) < 2 )
            pf_accumrainheavy_MCSstats_ALLYRSb(n,y)  =  blah(1) ;   
        else
            pf_accumrainheavy_MCSstats_ALLYRSb(n,y)  =  NaN ;            
        end
    end
end
pf_accumrainheavy_MCSstats_ALLYRSb(pf_accumrainheavy_MCSstats_ALLYRSb==0) = NaN;


fact = 1 ;

%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs 
hitotmass  = [18000.000000000001, 100000] ;
medtotmass = [10000.0000000000000001, 18000.] ;
lototmass  = [0, 10000.] ;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPhvyaccum = [];
MCSwithoutMPhvyaccum = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPhvyaccum = vertcat( MCSwithMPhvyaccum, pf_accumrainheavy_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(pf_accumrainheavy_MCSstats_ALLYRSb(n,y))==0  &  pf_accumrainheavy_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
            elseif(  isnan(pf_accumrainheavy_MCSstats_ALLYRSb(n,y))==0  &  pf_accumrainheavy_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  pf_accumrainheavy_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end

            elseif(  isnan(pf_accumrainheavy_MCSstats_ALLYRSb(n,y))==0  &  pf_accumrainheavy_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end

            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPhvyaccum = vertcat(MCSwithoutMPhvyaccum, pf_accumrainheavy_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)

%   figure; hist( vertcat(MCSwithoutMPtotmass_list , MCSwithMPtotmass_list ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:1000:70000];
hold on

[h1,b] = hist(MCSwithoutMPhvyaccum,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPhvyaccum,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPhvyaccum,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPhvyaccum,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPhvyaccum,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPhvyaccum,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' max lifetime convective rain rate for MCSs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPhvyaccum,MCSwithMPhvyaccum,'Alpha',alvl)

[p2,sh2] = ranksum(MCSwithoutMPhvyaccum,MCSwithMPhvyaccum,'Alpha',alvl)

ax = gca;
ax.FontSize = 15
xticks( [0:1000:70000] )
xlabel('MCS lifetime accum hvy rain','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([0 50000 0 0.1])



% %saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
% outlab = horzcat(imout,'/MCSIhist_accumhvyrain_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with lifetime accum hvy rain: ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

% %saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
% outlab = horzcat(imout,'/MPorigin_accumhvyrain_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);









%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with accum hvy rain: ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) '.  N = ', num2str(length(mplat_medMCS)) ])

% %saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
% outlab = horzcat(imout,'/MPorigin_accumhvyrain_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with accum hvy rain: < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])


% %saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
% outlab = horzcat(imout,'/MPorigin_accumhvyrain_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)







if(filteroutLS==1)

    fact = 1.0 ;

    %%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
    pf_accumrainheavy_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    pf_accumrainheavy_MCSstats_ALLYRS_YESLSb(:) = NaN;
    pfsum = sum( pf_accumrainheavy_MCSstats_ALLYRS_YESLS, 1,  'omitnan'   );   pfsum = permute(pfsum,[2 3 4 1]);  pfsum(pfsum==0) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            blah = max( pfsum(:,n,y),[],1, 'omitnan') ;
            if( length(blah) < 2 )
                pf_accumrainheavy_MCSstats_ALLYRS_YESLSb(n,y)  =  blah(1) ;
            else
                pf_accumrainheavy_MCSstats_ALLYRS_YESLSb(n,y)  =  NaN ;
            end
        end
    end
    pf_accumrainheavy_MCSstats_ALLYRS_YESLSb(pf_accumrainheavy_MCSstats_ALLYRS_YESLSb==0) = NaN;



    MCSwithoutLSaccumhvy = pf_accumrainheavy_MCSstats_ALLYRSb(:);   MCSwithoutLSaccumhvy(MCSwithoutLSaccumhvy==0)=[];  MCSwithoutLSaccumhvy(isnan(MCSwithoutLSaccumhvy))=[];
    MCSwithLSaccumhvy = pf_accumrainheavy_MCSstats_ALLYRS_YESLSb(:);   MCSwithLSaccumhvy(MCSwithLSaccumhvy==0)=[];  MCSwithLSaccumhvy(isnan(MCSwithLSaccumhvy))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' max lifetime accumulated conv rain rate for MCSs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:1000:70000];
    hold on
    [h1,b] = hist(MCSwithoutLSaccumhvy/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLSaccumhvy/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLSaccumhvy/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLSaccumhvy/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLSaccumhvy/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLSaccumhvy/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLSaccumhvy,MCSwithLSaccumhvy,'Alpha',alvl)
    % text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
    % if(sh == 0)
    %     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
    % elseif(sh == 1)
    %     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)])
    % end
    [p2,sh2] = ranksum(MCSwithoutLSaccumhvy,MCSwithLSaccumhvy,'Alpha',alvl)
    % text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
    % if(sh2 == 0)
    %     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    % elseif(sh2 == 1)
    %     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    % end
    ax = gca;
    ax.FontSize = 15
    xticks( [0:1000:edges(end)] )
    xlabel('MCS lifetime accum hvy rain ','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 50000 0 0.1 ])

%     saveas(ff,horzcat(imout,'/MCSIhist_accumhvyrain_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
%     outlab = horzcat(imout,'/MCSIhist_accumhvyrain_filtLS',num2str(filteroutLS),'.eps')
%     EPSprint = horzcat('print -painters -depsc ',outlab);
%     %eval([EPSprint]);







    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_list/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_list/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' Accum hvy rain of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:1000:90000];
    hold on
    [h1,b] = hist(MCSwithLSaccumhvy/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPhvyaccum/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPhvyaccum/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLSaccumhvy/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLSaccumhvy/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPhvyaccum/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPhvyaccum/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPhvyaccum/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPhvyaccum/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [0:1000:90000] )
    xlabel('MCS lifetime accum hvy rain','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 72000 0 0.1 ])

    %%%%%%%% image out:

%     saveas(ff,horzcat(imout,'/MCSIhist_accumhvyrain_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));
% 
%     outlab = horzcat(imout,'/MCSIhist_LSMPMCS_accumhvyrain_filtLS',num2str(filteroutLS),'.eps')
%     EPSprint = horzcat('print -painters -depsc ',outlab);
%     %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSaccumhvy(:),MCSwithMPhvyaccum(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSaccumhvy(:),MCSwithMPhvyaccum(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPhvyaccum(:),MCSwithoutMPhvyaccum,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPhvyaccum(:),MCSwithoutMPhvyaccum,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSaccumhvy(:),MCSwithoutMPhvyaccum,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSaccumhvy(:),MCSwithoutMPhvyaccum,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  MCS max area growth rate
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to total conv/strat RAINFALL MASS of MCSs with Syn objs present
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% condense [1:5] PF area stats 1-combined MCS pf area:
dAdt_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    dAdt_MCSstats_ALLYRSb(:) = NaN;  

for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        %for t = 1:mtimes
            dAdt_MCSstats_ALLYRSb(n,y)  =  max (   dAdt_MCSstats_ALLYRS(1:6,n,y) ,[], 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
        %end
    end
end
dAdt_MCSstats_ALLYRSb(dAdt_MCSstats_ALLYRSb==0) = NaN;


fact = 1.0 ;



%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hitotmass  = [32500.000000000000001, 10000] * fact;
medtotmass = [14500.0000000000000001, 32500] * fact;
lototmass  = [0, 14500] * fact;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPdadt_list = [];
MCSwithoutMPdadt_list = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPdadt_list = vertcat( MCSwithMPdadt_list, dAdt_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(dAdt_MCSstats_ALLYRSb(n,y))==0  &  dAdt_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(dAdt_MCSstats_ALLYRSb(n,y))==0  &  dAdt_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  dAdt_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan(dAdt_MCSstats_ALLYRSb(n,y))==0  &  dAdt_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end
            
            
            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPdadt_list = vertcat(MCSwithoutMPdadt_list, dAdt_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)



%   figure; hist( vertcat(MCSwithoutMPtotmass_list , MCSwithMPtotmass_list ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[-10000:2000:190000];
hold on
% hist(MCSwithoutMPtotmass_list/fact,edges);
% h = findobj(gca,'Type','patch');
% h.FaceColor = [0 0.5 0.5];
% h.EdgeColor = [0 0 0];
% hold on
% hist(MCSwithMPtotmass_list/fact,edges);
% h2 = findobj(gca,'Type','patch');
% h2(1).FaceColor = [1 0.5 0];
% h2(1).EdgeColor = [0 0 0];
% h2(1).FaceAlpha = 0.8;
[h1,b] = hist(MCSwithoutMPdadt_list/fact,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPdadt_list/fact,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPdadt_list/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPdadt_list/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPdadt_list/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPdadt_list/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' max MCS da/dt for MCSs first 6 hrs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPdadt_list,MCSwithMPdadt_list,'Alpha',alvl)
% text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
% if(sh == 0)
%     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
% elseif(sh == 1)
%     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)]) 
% end
[p2,sh2] = ranksum(MCSwithoutMPdadt_list,MCSwithMPdadt_list,'Alpha',alvl)
% text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
% if(sh2 == 0)
%     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
% elseif(sh2 == 1)
%     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
% end
ax = gca;
ax.FontSize = 15
xticks( [-6000:2000:150000] )
xlabel('MCS lifetime max dA/dt','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([-6000 105000 0 0.08 ])

% %saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
% outlab = horzcat(imout,'/MCSIhist_maxdadt_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with  max dA/dt in first 6hrs of mcs: ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

% %saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
% outlab = horzcat(imout,'/MPorigin_maxdadt_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);









%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with  max dA/dt in first 6hrs of mcs: ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) ' kg.  N = ', num2str(length(mplat_medMCS)) ])

% %saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
% outlab = horzcat(imout,'/MPorigin_maxdadt_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max dA/dt in first 6hrs of mcs: < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])


% %saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
% outlab = horzcat(imout,'/MPorigin_maxdadt_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)







if(filteroutLS==1)

    fact = 1 ;

    % condense [1:5] PF area stats 1-combined MCS pf area:
    dAdt_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    dAdt_MCSstats_ALLYRS_YESLSb(:) = NaN;
  
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            %for t = 1:mtimes
            dAdt_MCSstats_ALLYRS_YESLSb(n,y)  =  max( dAdt_MCSstats_ALLYRS_YESLS(1:6,n,y) ,[], 'omitnan'   )  ;  
            %end
        end
    end
    dAdt_MCSstats_ALLYRS_YESLSb(dAdt_MCSstats_ALLYRS_YESLSb==0) = NaN;


    MCSwithoutLSdadt = dAdt_MCSstats_ALLYRSb(:);         MCSwithoutLSdadt(MCSwithoutLSdadt==0)=[];  MCSwithoutLSdadt(isnan(MCSwithoutLSdadt))=[];
    MCSwithLSdadt    = dAdt_MCSstats_ALLYRS_YESLSb(:);   MCSwithLSdadt(MCSwithLSdadt==0)=[];  MCSwithLSdadt(isnan(MCSwithLSdadt))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' max dA/dt for MCSs first 6 hrs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[-10000:2000:190000];
    hold on
    % hist(MCSwithoutMPtotmass_list/fact,edges);
    % h = findobj(gca,'Type','patch');
    % h.FaceColor = [0 0.5 0.5];
    % h.EdgeColor = [0 0 0];
    % hold on
    % hist(MCSwithMPtotmass_list/fact,edges);
    % h2 = findobj(gca,'Type','patch');
    % h2(1).FaceColor = [1 0.5 0];
    % h2(1).EdgeColor = [0 0 0];
    % h2(1).FaceAlpha = 0.8;
    [h1,b] = hist(MCSwithoutLSdadt/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLSdadt/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLSdadt/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLSdadt/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLSdadt/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLSdadt/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLSdadt,MCSwithLSdadt,'Alpha',alvl)
    % text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
    % if(sh == 0)
    %     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
    % elseif(sh == 1)
    %     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)])
    % end
    [p2,sh2] = ranksum(MCSwithoutLSdadt,MCSwithLSdadt,'Alpha',alvl)
    % text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
    % if(sh2 == 0)
    %     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    % elseif(sh2 == 1)
    %     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    % end
    ax = gca;
    ax.FontSize = 15
    xticks( [-6000:2000:105000] )
    xlabel('MCS lifetime max dA/dt','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([-6000 105000 0 0.1 ])

%     saveas(ff,horzcat(imout,'/MCSIhist_maxdadt_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
%     outlab = horzcat(imout,'/MCSIhist_maxdadt_filtLS',num2str(filteroutLS),'.eps')
%     EPSprint = horzcat('print -painters -depsc ',outlab);
%     %eval([EPSprint]);







    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_list/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_list/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' Max dA/dt in first 6 hrs of  MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[-20000:2000:170000];
    hold on
    [h1,b] = hist(MCSwithLSdadt/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPdadt_list/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPdadt_list/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLSdadt/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLSdadt/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPdadt_list/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPdadt_list/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPdadt_list/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPdadt_list/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [-6000:2000:105000] )
    xlabel('MCS max dA/dt in first 6 hours','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([-6000 105000 0 0.1 ])

    %%%%%%%% image out:

%     saveas(ff,horzcat(imout,'/MCSIhist_maxdadt_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));
% 
%     outlab = horzcat(imout,'/MCSIhist_LSMPMCS_maxdadt_filtLS',num2str(filteroutLS),'.eps')
%     EPSprint = horzcat('print -painters -depsc ',outlab);
%     %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSdadt(:),MCSwithMPdadt_list(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSdadt(:),MCSwithMPdadt_list(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPdadt_list(:),MCSwithoutMPdadt_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPdadt_list(:),MCSwithoutMPdadt_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSdadt(:),MCSwithoutMPdadt_list,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSdadt(:),MCSwithoutMPdadt_list,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end
















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  MCS max ETH50
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
pf_ETH50_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    pf_ETH50_MCSstats_ALLYRSb(:) = NaN; 
pfmax = max( pf_ETH50_MCSstats_ALLYRS, [], 1,  'omitnan'   );   pfmax = permute(pfmax,[2 3 4 1]);  pfmax(pfmax==0) = NaN;

tstart = 1;
tend = 100;

for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        blah = max( pfmax(tstart:tend,n,y),[],1, 'omitnan') ;
        if( length(blah) < 2 )
            pf_ETH50_MCSstats_ALLYRSb(n,y)  =  blah(1) ;   
        else
            pf_ETH50_MCSstats_ALLYRSb(n,y)  =  NaN ;            
        end
    end
end
pf_ETH50_MCSstats_ALLYRSb(pf_ETH50_MCSstats_ALLYRSb==0) = NaN;



fact = 1 ;

%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs 
hitotmass  = [12.000001, 29] ;
medtotmass = [9.00000000000001, 12.] ;
lototmass  = [0, 9] ;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPmax50eth = [];
MCSwithoutMPmax50eth = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPmax50eth = vertcat( MCSwithMPmax50eth, pf_ETH50_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(pf_ETH50_MCSstats_ALLYRSb(n,y))==0  &  pf_ETH50_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
            elseif(  isnan(pf_ETH50_MCSstats_ALLYRSb(n,y))==0  &  pf_ETH50_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  pf_ETH50_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end

            elseif(  isnan(pf_ETH50_MCSstats_ALLYRSb(n,y))==0  &  pf_ETH50_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end

            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPmax50eth = vertcat(MCSwithoutMPmax50eth, pf_ETH50_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)

%   figure; hist( vertcat(MCSwithoutMPtotmass_list , MCSwithMPtotmass_list ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:1:28];
hold on

[h1,b] = hist(MCSwithoutMPmax50eth,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPmax50eth,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPmax50eth,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPmax50eth,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPmax50eth,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPmax50eth,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' max ETH50 for MCSs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPmax50eth,MCSwithMPmax50eth,'Alpha',alvl)

[p2,sh2] = ranksum(MCSwithoutMPmax50eth,MCSwithMPmax50eth,'Alpha',alvl)

ax = gca;
ax.FontSize = 15
xticks( [5:1:22] )
xlabel('MCS lifetime max ETH50','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([5 22 0 0.3])



% %saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
% outlab = horzcat(imout,'/MCSIhist_ETH50_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max ETH50 : ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

% %saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
% outlab = horzcat(imout,'/MPorigin_largemaxETH50_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);









%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max ETH50: ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) ' kg.  N = ', num2str(length(mplat_medMCS)) ])

% %saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
% outlab = horzcat(imout,'/MPorigin_medmaxETH50_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max ETH50: < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])

% %saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
% outlab = horzcat(imout,'/MPorigin_smallETH50_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)







if(filteroutLS==1)

    fact = 1.0 ;

    %%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
    pf_ETH50_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    pf_ETH50_MCSstats_ALLYRS_YESLSb(:) = NaN;
    pfmax = max( pf_ETH50_MCSstats_ALLYRS_YESLS, [], 1,  'omitnan'   );   pfmax = permute(pfmax,[2 3 4 1]);  pfmax(pfmax==0) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            blah = max( pfmax(tstart:tend,n,y),[],1, 'omitnan') ;
            if( length(blah) < 2 )
                pf_ETH50_MCSstats_ALLYRS_YESLSb(n,y)  =  blah(1) ;
            else
                pf_ETH50_MCSstats_ALLYRS_YESLSb(n,y)  =  NaN ;
            end
        end
    end
    pf_ETH50_MCSstats_ALLYRS_YESLSb(pf_ETH50_MCSstats_ALLYRS_YESLSb==0) = NaN;

    MCSwithoutLSeth50 = pf_ETH50_MCSstats_ALLYRSb(:);   MCSwithoutLSeth50(MCSwithoutLSeth50==0)=[];  MCSwithoutLSeth50(isnan(MCSwithoutLSeth50))=[];
    MCSwithLSeth50 = pf_ETH50_MCSstats_ALLYRS_YESLSb(:);   MCSwithLSeth50(MCSwithLSeth50==0)=[];  MCSwithLSeth50(isnan(MCSwithLSeth50))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' Max ETH50 for MCSs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:1:28];
    hold on
    [h1,b] = hist(MCSwithoutLSeth50/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLSeth50/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLSeth50/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLSeth50/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLSeth50/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLSeth50/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLSeth50,MCSwithLSeth50,'Alpha',alvl)
    % text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
    % if(sh == 0)
    %     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
    % elseif(sh == 1)
    %     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)])
    % end
    [p2,sh2] = ranksum(MCSwithoutLSeth50,MCSwithLSeth50,'Alpha',alvl)
    % text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
    % if(sh2 == 0)
    %     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    % elseif(sh2 == 1)
    %     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    % end
    ax = gca;
    ax.FontSize = 15
    xticks( [0:1:22] )
    xlabel('MCS max ETH50','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 19 0 0.25 ])

%     saveas(ff,horzcat(imout,'/MCSIhist_maxETH50_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
%     outlab = horzcat(imout,'/MCSIhist_maxETH50_filtLS',num2str(filteroutLS),'.eps')
%     EPSprint = horzcat('print -painters -depsc ',outlab);
%     %eval([EPSprint]);







    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_list/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_list/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' max ETH50 of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:1:22];
    hold on
    [h1,b] = hist(MCSwithLSeth50/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPmax50eth/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPmax50eth/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLSeth50/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLSeth50/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPmax50eth/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPmax50eth/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPmax50eth/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPmax50eth/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [0:1:22] )
    xlabel('MCS max ETH50 ','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 19 0 0.20 ])

    %%%%%%%% image out:

%     saveas(ff,horzcat(imout,'/MCSIhist_maxETH50_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));
% 
%     outlab = horzcat(imout,'/MCSIhist_LSMPMCS_maxETH50_filtLS',num2str(filteroutLS),'.eps')
%     EPSprint = horzcat('print -painters -depsc ',outlab);
%     %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSeth50(:),MCSwithMPmax50eth(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSeth50(:),MCSwithMPmax50eth(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPmax50eth(:),MCSwithoutMPmax50eth,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPmax50eth(:),MCSwithoutMPmax50eth,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSeth50(:),MCSwithoutMPmax50eth,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSeth50(:),MCSwithoutMPmax50eth,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end











%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  MCS max ETH30
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
pf_ETH30_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    pf_ETH30_MCSstats_ALLYRSb(:) = NaN; 
pfmax = max( pf_ETH30_MCSstats_ALLYRS, [], 1,  'omitnan'   );   pfmax = permute(pfmax,[2 3 4 1]);  pfmax(pfmax==0) = NaN;

tstart = 1;
tend = 3;

for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        blah = max( pfmax(tstart:tend,n,y),[],1, 'omitnan') ;
        if( length(blah) < 2 )
            pf_ETH30_MCSstats_ALLYRSb(n,y)  =  blah(1) ;   
        else
            pf_ETH30_MCSstats_ALLYRSb(n,y)  =  NaN ;            
        end
    end
end
pf_ETH30_MCSstats_ALLYRSb(pf_ETH30_MCSstats_ALLYRSb==0) = NaN;



fact = 1 ;

%%%%% make mp origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs 
hitotmass  = [15.000001, 29] ;
medtotmass = [13.00000000000001, 15.] ;
lototmass  = [0, 13] ;

% grab MCS duration and mp obj for all events with syn present at MCSI:

MCSwithMPmax30eth = [];
MCSwithoutMPmax30eth = [];

%lat/lons of origin site of mp obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPmax30eth = vertcat( MCSwithMPmax30eth, pf_ETH30_MCSstats_ALLYRSb(n,y) );
            
            %find the mp obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(pf_ETH30_MCSstats_ALLYRSb(n,y))==0  &  pf_ETH30_MCSstats_ALLYRSb(n,y) > hitotmass(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
            elseif(  isnan(pf_ETH30_MCSstats_ALLYRSb(n,y))==0  &  pf_ETH30_MCSstats_ALLYRSb(n,y) > medtotmass(1)  &  pf_ETH30_MCSstats_ALLYRSb(n,y) < medtotmass(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end

            elseif(  isnan(pf_ETH30_MCSstats_ALLYRSb(n,y))==0  &  pf_ETH30_MCSstats_ALLYRSb(n,y) < lototmass(end)  )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end

            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPmax30eth = vertcat(MCSwithoutMPmax30eth, pf_ETH30_MCSstats_ALLYRSb(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)

%   figure; hist( vertcat(MCSwithoutMPtotmass_list , MCSwithMPtotmass_list ) /fact  ,400); axis([0 4 0 500])


%histogram of MCS durations with & without synoptic objs at birth:
ff = figure('position',[84,497,1032,451]);
edges=[0:1:28];
hold on

[h1,b] = hist(MCSwithoutMPmax30eth,edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSwithMPmax30eth,edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MCSwithoutMPmax30eth,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSwithoutMPmax30eth,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSwithMPmax30eth,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSwithMPmax30eth,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' max ETH30 for MCSs','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(MCSwithoutMPmax30eth,MCSwithMPmax30eth,'Alpha',alvl)

[p2,sh2] = ranksum(MCSwithoutMPmax30eth,MCSwithMPmax30eth,'Alpha',alvl)

ax = gca;
ax.FontSize = 15
xticks( [5:1:22] )
xlabel('MCS lifetime max ETH30','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([5 22 0 0.3])



% %saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
% outlab = horzcat(imout,'/MCSIhist_ETH30_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);









% now plot histograms of syn origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];


%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max ETH30 : ', num2str(hitotmass(1)),'+ kg.  N = ', num2str(length(mplat_hiMCS)) ])

% %saveas(ff,horzcat(imout,'/MPorigin_largetotprecipMCS.png'));
% outlab = horzcat(imout,'/MPorigin_largemaxETH30_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);









%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max ETH30: ', num2str(medtotmass(1)),'-',num2str(medtotmass(end)) ' kg.  N = ', num2str(length(mplat_medMCS)) ])

% %saveas(ff,horzcat(imout,'/MPorigin_medtotprecipMCS.png'));
% outlab = horzcat(imout,'/MPorigin_medmaxETH30_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);





%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with max ETH30: < ',num2str(lototmass(end)) ' kg.  N = ', num2str(length(mplat_loMCS)) ])


% %saveas(ff,horzcat(imout,'/MPorigin_smalltotprecipMCS.png'));
% outlab = horzcat(imout,'/MPorigin_smallETH30_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS-360)
mean(mplat_hiMCS-360) 
median(mplat_loMCS-360)
median(mplat_hiMCS-360) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)







if(filteroutLS==1)

    fact = 1.0 ;

    %%%%%% condense [1:5] PF area stats 1-combined MCS pf area:
    pf_ETH30_MCSstats_ALLYRS_YESLSb = duration_MCSstats_ALLYRS;    pf_ETH30_MCSstats_ALLYRS_YESLSb(:) = NaN;
    pfmax = max( pf_ETH30_MCSstats_ALLYRS_YESLS, [], 1,  'omitnan'   );   pfmax = permute(pfmax,[2 3 4 1]);  pfmax(pfmax==0) = NaN;
    for y = 1 : mcs_years        % which is same as num years of syn objects
        for n = 1 : mcs_tracks
            blah = max( pfmax(tstart:tend,n,y),[],1, 'omitnan') ;
            if( length(blah) < 2 )
                pf_ETH30_MCSstats_ALLYRS_YESLSb(n,y)  =  blah(1) ;
            else
                pf_ETH30_MCSstats_ALLYRS_YESLSb(n,y)  =  NaN ;
            end
        end
    end
    pf_ETH30_MCSstats_ALLYRS_YESLSb(pf_ETH30_MCSstats_ALLYRS_YESLSb==0) = NaN;

    MCSwithoutLSeth30 = pf_ETH30_MCSstats_ALLYRSb(:);   MCSwithoutLSeth30(MCSwithoutLSeth30==0)=[];  MCSwithoutLSeth30(isnan(MCSwithoutLSeth30))=[];
    MCSwithLSeth30 = pf_ETH30_MCSstats_ALLYRS_YESLSb(:);   MCSwithLSeth30(MCSwithLSeth30==0)=[];  MCSwithLSeth30(isnan(MCSwithLSeth30))=[];

    %histogram of MCS durations with & without synoptic objs at birth:
    ff = figure('position',[84,497,1032,451]);
    
    title(strcat(' Max ETH30 for MCSs. filtLS=',num2str(filteroutLS)),'FontSize',15)
    edges=[0:1:28];
    hold on
    [h1,b] = hist(MCSwithoutLSeth30/fact,edges) ;  blahwithout =  h1/(sum(h1));
    bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
    xticks(b);
    alpha 0.7
    hold on
    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithLSeth30/fact,edges) ;  blahwith =  h1/(sum(h1));
    bar(b,blahwith,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on
    plot(median(MCSwithoutLSeth30/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithoutLSeth30/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithLSeth30/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithLSeth30/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
    legend('MCSI without LS obj','MCSI with LS obj','FontSize',15)

    alvl = 0.05;
    [sh,p] = kstest2(MCSwithoutLSeth30,MCSwithLSeth30,'Alpha',alvl)
    % text(2,250,['K-S test at ', num2str(alvl),' significance lvl:'])
    % if(sh == 0)
    %     text(2,230,['Sig diff distributions? NO.  P-val:',num2str(p)])
    % elseif(sh == 1)
    %     text(2,230,['Sig diff distributions? YES.  P-val:',num2str(p)])
    % end
    [p2,sh2] = ranksum(MCSwithoutLSeth30,MCSwithLSeth30,'Alpha',alvl)
    % text(2,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
    % if(sh2 == 0)
    %     text(2,130,['Sig diff distributions? NO.  P-val:',num2str(p2)])
    % elseif(sh2 == 1)
    %     text(2,130,['Sig diff distributions? YES.  P-val:',num2str(p2)])
    % end
    ax = gca;
    ax.FontSize = 15
    xticks( [0:1:22] )
    xlabel('MCS max ETH30','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 19 0 0.25 ])

%     saveas(ff,horzcat(imout,'/MCSIhist_maxETH30_yesLSnoLS_filtLS',num2str(filteroutLS),'.png'));
%     outlab = horzcat(imout,'/MCSIhist_maxETH30_filtLS',num2str(filteroutLS),'.eps')
%     EPSprint = horzcat('print -painters -depsc ',outlab);
%     %eval([EPSprint]);



    %%%   Now do a fun one with:
    %       i)   MCSs with LSs (MCSwithLStotmass/fact);
    %       ii)  MCSs without LSs but with MPs (MCSwithMPtotmass_list/fact);
    %       iii) MCSs without LSs or MPs (MCSwithoutMPtotmass_list/fact);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' max ETH30 of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:1:22];
    hold on
    [h1,b] = hist(MCSwithLSeth30/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSwithMPmax30eth/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSwithoutMPmax30eth/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with LS','MCS without LS but with MPs','MCS without LS or MPs'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSwithLSeth30/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSwithLSeth30/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSwithMPmax30eth/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSwithMPmax30eth/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSwithoutMPmax30eth/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSwithoutMPmax30eth/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    alvl = 0.05;

    xticks( [0:1:22] )
    xlabel('MCS max ETH30 ','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([2 20 0 0.25 ])

    %%%%%%%% image out:

%     saveas(ff,horzcat(imout,'/MCSIhist_maxETH30_LSMPMCS_filtLS',num2str(filteroutLS),'.png'));
% 
%     outlab = horzcat(imout,'/MCSIhist_LSMPMCS_maxETH30_filtLS',num2str(filteroutLS),'.eps')
%     EPSprint = horzcat('print -painters -depsc ',outlab);
%     %eval([EPSprint]);

end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSeth30(:),MCSwithMPmax30eth(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSeth30(:),MCSwithMPmax30eth(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithMPmax30eth(:),MCSwithoutMPmax30eth,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithMPmax30eth(:),MCSwithoutMPmax30eth,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSwithLSeth30(:),MCSwithoutMPmax30eth,'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSwithLSeth30(:),MCSwithoutMPmax30eth,'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end














% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%   MP origins for MPs present at MCSI (broken down by MP area)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% [mpt mpy] =  size(mparea_atMCSI)  ;
% 
% %%%%% make syn origin locations broken down by hi, med, lo MCS duration:
% 
% % prescribed duration bins of mcs (hours):
% hiarea  = [200000.1, 100000000000];
% miarea  = [100000.1, 200000];
% loarea  = [0, 100000];
% 
% % grab MCS duration and syn obj for all events with syn present at MCSI:
% 
% MPwithMCSdir_list = [];
% MPwithoutMCSdir_list = [];
% 
% %lat/lons of origin site of synoptic obj present at bith of lon-, med-, short- duration MCSs
% mplat_hiMCS = [];
% mplat_medMCS = [];
% mplat_loMCS = [];
% mplon_hiMCS = [];
% mplon_medMCS = [];
% mplon_loMCS = [];
% 
% for y = 1 : mpy        % which is same as num years of MP objects
%     for n = 1 : mpt
% 
%         if(  isnan(mparea_atMCSI(n,y))==0  &  mparea_atMCSI(n,y) > hiarea(1)  &  mparea_atMCSI(n,y) < hiarea(end)    )
% 
%             mplat_hiMCS = vertcat(mplat_hiMCS, mpI_vs_mcsI_dt_lat(n,y) );
%             mplon_hiMCS = vertcat(mplon_hiMCS, mpI_vs_mcsI_dt_lon(n,y) );
% 
%         elseif(  isnan(mparea_atMCSI(n,y))==0  &  mparea_atMCSI(n,y) > miarea(1)  &  mparea_atMCSI(n,y) < miarea(end)      )
% 
%             mplat_medMCS = vertcat(mplat_medMCS, mpI_vs_mcsI_dt_lat(n,y) );
%             mplon_medMCS = vertcat(mplon_medMCS, mpI_vs_mcsI_dt_lon(n,y) );
% 
%         elseif(  isnan(mparea_atMCSI(n,y))==0  &  mparea_atMCSI(n,y) > loarea(1)  &  mparea_atMCSI(n,y) < loarea(end)   )
% 
%             mplat_loMCS = vertcat(mplat_loMCS, mpI_vs_mcsI_dt_lat(n,y) );
%             mplon_loMCS = vertcat(mplon_loMCS, mpI_vs_mcsI_dt_lon(n,y) );
%         end
% 
%     end
% end
% 
% length(mplat_hiMCS)
% length(mplat_medMCS)
% length(mplat_loMCS)
% 
% % now plot histograms of MP origins tied to MCSI of hi-, med-, lo-duration MCSs
% 
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% title([' Origin locations of MPs present at MCSI with MP area: ',num2str(hiarea(1)),' to ', num2str(hiarea(end)) ,' N = ', num2str(length(mplat_hiMCS)) ])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 15])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% axis([-160 -50 15 60])
% 
% % %saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
% % outlab = horzcat(imout,'/MPorigin_hiMParea_filtLS',num2str(filteroutLS),'.eps')
% % EPSprint = horzcat('print -painters -depsc ',outlab);
% % %eval([EPSprint]);
% 
% 
% 
% 
% 
% 
% 
% %subplot(3,1,2)
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% 
% title([' Origin locations of MPs present at MCSI with MP area: ',num2str(miarea(1)),' to ', num2str(miarea(end)) ,' N = ', num2str(length(mplat_medMCS)) ])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 15])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% axis([-160 -50 15 60])
% 
% % %saveas(ff,horzcat(imout,'/MPorigin_medareaMCS.png'));
% % outlab = horzcat(imout,'/MPorigin_midMParea_filtLS',num2str(filteroutLS),'.eps')
% % EPSprint = horzcat('print -painters -depsc ',outlab);
% % %eval([EPSprint]);
% 
% 
% 
% 
% 
% 
% 
% 
% %subplot(3,1,3)
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% 
% title([' Origin locations of MPs present at MCSI with MP area: ',num2str(loarea(1)),' to ', num2str(loarea(end)) ,' N = ', num2str(length(mplat_loMCS)) ])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 15])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% axis([-160 -50 15 60])
% 
% % %saveas(ff,horzcat(imout,'/MPorigin_smallareaMCS.png'));
% % outlab = horzcat(imout,'/MPorigin_loMParea_filtLS',num2str(filteroutLS),'.eps')
% % EPSprint = horzcat('print -painters -depsc ',outlab);
% % %eval([EPSprint]);
% 
% 
% %stat diff tests, is lare-area-MCS MP obj origin different than for small-area-mcs?:
% 
% mean(mplon_loMCS-360)
% mean(mplon_hiMCS-360) 
% median(mplon_loMCS-360)
% median(mplon_hiMCS-360) 
% 
% alvl = 0.05;
% [sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
% [p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)
% 
% mean(mplat_loMCS)
% mean(mplat_hiMCS) 
% median(mplat_loMCS)
% median(mplat_hiMCS) 
% 
% [sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
% [p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%   MP origins for MPs present at MCSI (broken down by MP peak vorticity)
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% [mpt mpy] =  size(mpvort_atMCSI)  ;
% 
% %%%%% make syn origin locations broken down by hi, med, lo MCS duration:
% 
% % prescribed duration bins of mcs (hours):
% hivort  = [0.05200001, 100]*0.001;
% mivort   = [0.0380000001, 0.052]*0.001;
% lovort   = [0, 0.038]*0.001;
% 
% % grab MCS duration and syn obj for all events with syn present at MCSI:
% 
% MPwithMCSdir_list = [];
% MPwithoutMCSdir_list = [];
% 
% %lat/lons of origin site of synoptic obj present at bith of lon-, med-, short- duration MCSs
% mplat_hiMCS = [];
% mplat_medMCS = [];
% mplat_loMCS = [];
% mplon_hiMCS = [];
% mplon_medMCS = [];
% mplon_loMCS = [];
% 
% for y = 1 : mpy        % which is same as num years of MP objects
%     for n = 1 : mpt
% 
%         if(  isnan(mpvort_atMCSI(n,y))==0  &  mpvort_atMCSI(n,y) > hivort(1)  &  mpvort_atMCSI(n,y) < hivort(end)    )
% 
%             mplat_hiMCS = vertcat(mplat_hiMCS, mpI_vs_mcsI_dt_lat(n,y) );
%             mplon_hiMCS = vertcat(mplon_hiMCS, mpI_vs_mcsI_dt_lon(n,y) );
% 
%         elseif(  isnan(mpvort_atMCSI(n,y))==0  &  mpvort_atMCSI(n,y) > mivort(1)  &  mpvort_atMCSI(n,y) < mivort(end)      )
% 
%             mplat_medMCS = vertcat(mplat_medMCS, mpI_vs_mcsI_dt_lat(n,y) );
%             mplon_medMCS = vertcat(mplon_medMCS, mpI_vs_mcsI_dt_lon(n,y) );
% 
%         elseif(  isnan(mpvort_atMCSI(n,y))==0  &  mpvort_atMCSI(n,y) > lovort(1)  &  mpvort_atMCSI(n,y) < lovort(end)   )
% 
%             mplat_loMCS = vertcat(mplat_loMCS, mpI_vs_mcsI_dt_lat(n,y) );
%             mplon_loMCS = vertcat(mplon_loMCS, mpI_vs_mcsI_dt_lon(n,y) );
%         end
% 
%     end
% end
% 
% length(mplat_hiMCS)
% length(mplat_medMCS)
% length(mplat_loMCS)
% 
% % now plot histograms of MP origins tied to MCSI of hi-, med-, lo-duration MCSs
% 
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% title([' Origin locations of MPs present at MCSI with MP vorticity: ',num2str(hivort(1)),' to ', num2str(hivort(end)) ,' N = ', num2str(length(mplat_hiMCS)) ])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 15])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% axis([-160 -50 15 60])
% 
% % %saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
% % outlab = horzcat(imout,'/MPorigin_hiMPvort_filtLS',num2str(filteroutLS),'.eps')
% % EPSprint = horzcat('print -painters -depsc ',outlab);
% % %eval([EPSprint]);
% 
% 
% 
% 
% 
% 
% 
% %subplot(3,1,2)
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% 
% title([' Origin locations of MPs present at MCSI with MP vorticty: ',num2str(mivort(1)),' to ', num2str(mivort(end)) ,' N = ', num2str(length(mplat_medMCS)) ])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 15])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% axis([-160 -50 15 60])
% 
% % %saveas(ff,horzcat(imout,'/MPorigin_medareaMCS.png'));
% % outlab = horzcat(imout,'/MPorigin_midMPvort_filtLS',num2str(filteroutLS),'.eps')
% % EPSprint = horzcat('print -painters -depsc ',outlab);
% % %eval([EPSprint]);
% 
% 
% 
% 
% 
% 
% 
% 
% %subplot(3,1,3)
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% 
% title([' Origin locations of MPs present at MCSI with MP vorticity: ',num2str(lovort(1)),' to ', num2str(lovort(end)) ,' N = ', num2str(length(mplat_loMCS)) ])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 15])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% axis([-160 -50 15 60])
% 
% % %saveas(ff,horzcat(imout,'/MPorigin_smallareaMCS.png'));
% % outlab = horzcat(imout,'/MPorigin_loMPvort_filtLS',num2str(filteroutLS),'.eps')
% % EPSprint = horzcat('print -painters -depsc ',outlab);
% % %eval([EPSprint]);
% 
% 
% %stat diff tests, is lare-area-MCS MP obj origin different than for small-area-mcs?:
% 
% mean(mplon_loMCS-360)
% mean(mplon_hiMCS-360) 
% median(mplon_loMCS-360)
% median(mplon_hiMCS-360) 
% 
% alvl = 0.05;
% [sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
% [p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)
% 
% mean(mplat_loMCS)
% mean(mplat_hiMCS) 
% median(mplat_loMCS)
% median(mplat_hiMCS) 
% 
% [sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
% [p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)
% 
% 
% 
% 
% 
% 
% 
% 
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%     plots of MP origins based on their duration prior to MCSI
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %  mpI_vs_mcsI_dt
% %  mpI_vs_mcsI_dt_lat
% %  mpI_vs_mcsI_dt_lon
% 
% 
% [mpt mpy] =  size(mpI_vs_mcsI_dt)  ;
% % meanlat_MPstats_ALLYRS
% 
% % prescribed duration bins of mcs (hours):
% hidur    = [22.00001:1000];
% middur   = [9.00001:22];
% lodur    = [0:9];
% 
% % grab MCS duration and syn obj for all events with syn present at MCSI:
% 
% MPwithMCSdir_list = [];
% MPwithoutMCSdir_list = [];
% 
% %lat/lons of origin site of synoptic obj present at bith of lon-, med-, short- duration MCSs
% mplat_hiMCS = [];
% mplat_medMCS = [];
% mplat_loMCS = [];
% mplon_hiMCS = [];
% mplon_medMCS = [];
% mplon_loMCS = [];
% 
% 
% % blah = MPwithMCS_meanWNDDIR600_ALLYRS(:);
% % blah2 = find(blah > NWwind(1)  &  blah  < NWwind(end)) ;
% % blah(blah2)
% 
% 
% for y = 1 : mpy        % which is same as num years of syn objects
%     for n = 1 : mpt
% 
%         if(  isnan(mpI_vs_mcsI_dt(n,y))==0  &  mpI_vs_mcsI_dt(n,y) > hidur(1)  &  mpI_vs_mcsI_dt(n,y) < hidur(end)    )
% 
%             mplat_hiMCS = vertcat(mplat_hiMCS, mpI_vs_mcsI_dt_lat(n,y) );
%             mplon_hiMCS = vertcat(mplon_hiMCS, mpI_vs_mcsI_dt_lon(n,y) );
% 
%         elseif(  isnan(mpI_vs_mcsI_dt(n,y))==0  &  mpI_vs_mcsI_dt(n,y) > middur(1)  &  mpI_vs_mcsI_dt(n,y) < middur(end)      )
% 
%             mplat_medMCS = vertcat(mplat_medMCS, mpI_vs_mcsI_dt_lat(n,y) );
%             mplon_medMCS = vertcat(mplon_medMCS, mpI_vs_mcsI_dt_lon(n,y) );
% 
%         elseif(  isnan( mpI_vs_mcsI_dt(n,y))==0  &  mpI_vs_mcsI_dt(n,y) > lodur(1)  &  mpI_vs_mcsI_dt(n,y) < lodur(end)   )
% 
%             mplat_loMCS = vertcat(mplat_loMCS, mpI_vs_mcsI_dt_lat(n,y) );
%             mplon_loMCS = vertcat(mplon_loMCS, mpI_vs_mcsI_dt_lon(n,y) );
%         end
% 
%     end
% end
% 
% length(mplat_hiMCS)
% length(mplat_medMCS)
% length(mplat_loMCS)
% 
% 
% 
% 
% % NWwind  = [285:315];  %hi
% % Wwind   = [255:285];  %med
% % SWwind  = [225:255];  %lo
% 
% % now plot histograms of MP origins tied to MCSI of hi-, med-, lo-duration MCSs
% 
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% title([' Origin locations of MPs with preMCSI MP duration: ',num2str(hidur(1)),' to ', num2str(hidur(end)) ,' N = ', num2str(length(mplat_hiMCS)) ])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 15])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% axis([-160 -50 15 60])
% 
% %saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
% outlab = horzcat(imout,'/MPorigin_MPhidur_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);
% 
% 
% 
% 
% 
% 
% 
% %subplot(3,1,2)
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% 
% title([' Origin locations of MPs with preMCSI MP duration: ',num2str(middur(1)),' to ', num2str(middur(end)) ,' N = ', num2str(length(mplat_medMCS)) ])
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 15])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% axis([-160 -50 15 60])
% 
% %saveas(ff,horzcat(imout,'/MPorigin_medareaMCS.png'));
% outlab = horzcat(imout,'/MPorigin_MPmiddur_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);
% 
% 
% 
% 
% 
% 
% 
% 
% %subplot(3,1,3)
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% 
% title([' Origin locations of MPs with preMCSI MP duration: ',num2str(lodur(1)),' to ', num2str(lodur(end)) ,' N = ', num2str(length(mplat_loMCS)) ])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 15])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% axis([-160 -50 15 60])
% 
% %saveas(ff,horzcat(imout,'/MPorigin_smallareaMCS.png'));
% outlab = horzcat(imout,'/MPorigin_MPlodur_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);
% 
% 
% %stat diff tests, is lare-area-MCS MP obj origin different than for small-area-mcs?:
% 
% mean(mplon_loMCS-360)
% mean(mplon_hiMCS-360) 
% median(mplon_loMCS-360)
% median(mplon_hiMCS-360) 
% 
% alvl = 0.05;
% [sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
% [p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)
% 
% mean(mplat_loMCS)
% mean(mplat_hiMCS) 
% median(mplat_loMCS)
% median(mplat_hiMCS) 
% 
% [sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
% [p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%  make masks to optinonally filter out some things:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% 1: mask to kill dry MPs (mean lifetime PW < prescribed threshold)
% blacks out the dry MPs
[ad bd cd] = size( meanPW_MPstats_ALLYRS ) ;
maskPW_MPstats_ALLYRS = zeros(ad, bd, cd);   maskPW_MPstats_ALLYRS(:) = NaN;
for m = 1:bd
    for y = 1:cd
        %  m = 1200;  y = 6;
        meantrackPW = mean(meanPW_MPstats_ALLYRS(:,m,y),'omitnan') ;
        if( meantrackPW > 24.0)
            maskPW_MPstats_ALLYRS(:,m,y) = 1;
        end
    end
end
% pblah = maskPW_MPstats_ALLYRS(:,:,y)  ;
% pwblah = meanPW_MPstats_ALLYRS(:,:,y) ; 



%%%% 2: diurnal time of day: 
% blacks out non-dirunal hours
maskKEEPAFTERNOONEVENING_MPstats_ALLYRS = zeros(ad, bd, cd);   maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(:) = NaN;
MPhr = string(  datetime(basetime_MPstats_ALLYRS, 'convertfrom','posixtime','Format','HH') )  ;
keeps = find( MPhr == '00' | MPhr == '01' | MPhr == '02' | ...
              MPhr == '17' | MPhr == '18' | MPhr == '19' | MPhr == '20' | MPhr == '21' | MPhr == '22' | MPhr == '23');
maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(keeps) = 1;




%%%%%3: duration of MP-MCS collocation period.  Note, for reference, "MPCOLLOCMCS_ALLYRS (same but in MCSstats space) is defined below "

%first make list of MCSs touching each MP (will log multiple MCS encounters per MP - second index of four)
dd = 20; % index is taking stab at num of MCSs could overlap each MP (probably overkill)
MCStracks_MPstats_ALLYRS = zeros(ad, dd, bd, cd);     MCStracks_MPstats_ALLYRS(:) = NaN;   
for y = 1:cd
    touchedMCSs = MPtracks_perMCS_ALLYRS(:,:,y);  %MCSs contacted by a MP
    for m = 1:bd  % loop thru all MP numbers and log all MCS overlaps in MP time index space
        [tm nm] = find(touchedMCSs == m) ;   %nm = mcs number touched by mp, tm = time in mcs space mcs is touched by mp
        unm = unique(nm);  %list of unique MCS numbers touching MP_m
        if(length(tm)>1)
            for nn = 1 : length(tm)
                tmcs      =  basetime_MCSstats_ALLYRS(tm(nn),nm(nn),y) ;  %current time of touched MCS_nm
                timesmp   =  basetime_MPstats_ALLYRS(:,m,y) ; %full time record of MP that might be touching it
                % time index in mp_space when MCS_nn touches this MP_m:
                tind_mp       =  find( floor(tmcs/100) == floor(timesmp/100) )  ;
                % this nn's unique MCS number log index
                nmm = find(nm(nn) == unm);
                % log of ALL MCS nums touching each MP
                MCStracks_MPstats_ALLYRS(tind_mp,nmm,m,y) = nm(nn) ;
            end
        end
    end
end
% now count the duration (hours) of overlap for each MP-MCS interaction
MPMCS_collocDur_MPstats = zeros(dd, bd, cd);     MPMCS_collocDur_MPstats(:) = NaN; 
for y = 1:cd
    for m = 1:bd
        for n = 1:dd
            %  y = 6; m = 547; n = 1;
            MPMCS_collocDur_MPstats(n,m,y)  =  length(  find( isnan( MCStracks_MPstats_ALLYRS(:,n,m,y) ) == 0 )   )   ; 
        end
    end
end


%%%%% repeat for a PW & daytime filtered version(s):

%first make list of MCSs touching each MP (will log multiple MCS encounters per MP - second index of four)
dd = 20; % index is taking stab at num of MCSs could overlap each MP (probably overkill)
filtPW_MCStracks_MPstats_ALLYRS = zeros(ad, dd, bd, cd);            filtPW_MCStracks_MPstats_ALLYRS(:) = NaN;   
filtPWDAYTIME_MCStracks_MPstats_ALLYRS = zeros(ad, dd, bd, cd);     filtPWDAYTIME_MCStracks_MPstats_ALLYRS(:) = NaN;   
for y = 1:cd

    touchedMCSs = MPtracks_perMCS_ALLYRS(:,:,y);  %MCSs contacted by a MP
    for m = 1:bd  % loop thru all MP numbers and log all MCS overlaps in MP time index space
        [tm nm] = find(touchedMCSs == m) ;   %nm = mcs number touched by mp, tm = time in mcs space mcs is touched by mp
        unm = unique(nm);  %list of unique MCS numbers touching MP_m
        if(length(tm)>1)

            %PW filtered
            for nn = 1 : length(tm)
                tmcs      =  basetime_MCSstats_ALLYRS(tm(nn),nm(nn),y) ;  %current time of touched MCS_nm
                timesmp   =  basetime_MPstats_ALLYRS(:,m,y) ; %full time record of MP that might be touching it
          
                % time index in mp_space when MCS_nn touches this MP_m:
                tind_mp       =  find( floor(tmcs/100) == floor(timesmp/100) )  ;
                % this nn's unique MCS number log index
                nmm = find(nm(nn) == unm);
                if(  isnan(maskPW_MPstats_ALLYRS(tind_mp,m,y))==0  )
                    % log of ALL MCS nums touching each MP
                    filtPW_MCStracks_MPstats_ALLYRS(tind_mp,nmm,m,y) = nm(nn) ;
                end
            end

            %PW + daytime filtered
            for nn = 1 : length(tm)
                tmcs      =  basetime_MCSstats_ALLYRS(tm(nn),nm(nn),y) ;  %current time of touched MCS_nm
                timesmp   =  basetime_MPstats_ALLYRS(:,m,y) ; %full time record of MP that might be touching it
                % time index in mp_space when MCS_nn touches this MP_m:
                tind_mp       =  find( floor(tmcs/100) == floor(timesmp/100) )  ;
                % this nn's unique MCS number log index
                nmm = find(nm(nn) == unm);
                if(  isnan(maskPW_MPstats_ALLYRS(tind_mp,m,y))==0    &   isnan( maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(tind_mp,m,y) ) == 0 )
                    % log of ALL MCS numbers touching each MP
                    filtPWDAYTIME_MCStracks_MPstats_ALLYRS(tind_mp,nmm,m,y) = nm(nn) ;
                end
            end


        end
    end
end


%   mblah  = find(isnan( maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(1,:,y) ) == 0) ;
%   mbblah = find(isnan( maskPW_MPstats_ALLYRS(1,:,y) ) == 0)   ;

%   nblah  = length( find(isnan( filtPW_MCStracks_MPstats_ALLYRS(:,1,:,y) ) == 0)         );
%   nbblah = length( find(isnan( filtPWDAYTIME_MCStracks_MPstats_ALLYRS(:,1,:,y) ) == 0)  );

% now count the duration (hours) of overlap for each MP-MCS interaction
filtPW_MPMCS_collocDur_MPstats = zeros(dd, bd, cd);          filtPW_MPMCS_collocDur_MPstats(:) = NaN;
filtPWDAYTIME_MPMCS_collocDur_MPstats = zeros(dd, bd, cd);   filtPWDAYTIME_MPMCS_collocDur_MPstats(:) = NaN;
for y = 1:cd
    for m = 1:bd
        for n = 1:dd
            %  y = 6; m = 547; n = 1;
            if( length(  find( isnan( filtPW_MCStracks_MPstats_ALLYRS(:,n,m,y) ) == 0 )  > 0)  )
                filtPW_MPMCS_collocDur_MPstats(n,m,y)  =  length(  find( isnan( filtPW_MCStracks_MPstats_ALLYRS(:,n,m,y) ) == 0 )   )   ;
            end
            if( length(  find( isnan( filtPWDAYTIME_MCStracks_MPstats_ALLYRS(:,n,m,y) ) == 0 ) > 0 ) )
                filtPWDAYTIME_MPMCS_collocDur_MPstats(n,m,y)  =  length(  find( isnan( filtPWDAYTIME_MCStracks_MPstats_ALLYRS(:,n,m,y) ) == 0 )   )   ;
            end
        end
    end
end


filtPW_MPMCS_MAXncollocDur_MPstats         = max(filtPW_MPMCS_collocDur_MPstats,[],1);           filtPW_MPMCS_MAXncollocDur_MPstats = permute(filtPW_MPMCS_MAXncollocDur_MPstats,[2 3 1]);
filtPWDAYTIME_MPMCS_MAXncollocDur_MPstats  = max(filtPWDAYTIME_MPMCS_collocDur_MPstats,[],1);    filtPWDAYTIME_MPMCS_MAXncollocDur_MPstats = permute(filtPWDAYTIME_MPMCS_MAXncollocDur_MPstats,[2 3 1]);


length( find( isnan(filtPW_MPMCS_collocDur_MPstats)==0  )  )
length( find( isnan(filtPWDAYTIME_MPMCS_collocDur_MPstats)==0  )  )

% y = 6
%  mmmss = MPMCS_collocDur_MPstats(:, :, y);
%  mmmss = MCStracks_MPstats_ALLYRS(:,:,1034,6) ;
%  mmmss = MCStracks_MPstats_ALLYRS(:,1,:,6) ;   mmmss = permute(mmmss,[1, 3, 2, 4]);

% mmmss = filtPWDAYTIME_MCStracks_MPstats_ALLYRS(:,1,:,y);   mmmss = permute(mmmss,[1 3 2 4]);



% tmp = length(  find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  )  ;
% MPCOLLOCMCS_perMCS_ALLYRS(n,y) = tmp  ;  % NOTE: this includes all syn objs, not only the one(s) presnt during mcsi period




%%%%%4: when in MCS lifecycle they are collocated?










%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%   MP origins for MPs present at MCSI (broken down by MP area)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[mpt mpy] =  size(mparea_atMCSI_PWfilt)  ;

%%%%% make syn origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hiarea  = [190000.1, 100000000000];
miarea  = [95000.1, 190000];
loarea  = [0, 95000];

hiarea  = [prctile(mparea_atMCSI_PWfilt,[200/3],'all')+0.0000001, 100000000000];
miarea  = [prctile(mparea_atMCSI_PWfilt,[100/3],'all')+0.0000001, prctile(mparea_atMCSI_PWfilt,[200/3],'all')];
loarea  = [0, prctile(mparea_atMCSI_PWfilt,[100/3],'all')];


% grab MCS duration and syn obj for all events with syn present at MCSI:

MPwithMCSdir_list = [];
MPwithoutMCSdir_list = [];

%lat/lons of origin site of synoptic obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];

for y = 1 : mpy        % which is same as num years of MP objects
    for n = 1 : mpt

        if(  isnan(mparea_atMCSI_PWfilt(n,y))==0  &  mparea_atMCSI_PWfilt(n,y) > hiarea(1)  &  mparea_atMCSI_PWfilt(n,y) < hiarea(end)    )

            mplat_hiMCS = vertcat(mplat_hiMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_hiMCS = vertcat(mplon_hiMCS, mpI_vs_mcsI_dt_lon(n,y) );

        elseif(  isnan(mparea_atMCSI_PWfilt(n,y))==0  &  mparea_atMCSI_PWfilt(n,y) > miarea(1)  &  mparea_atMCSI_PWfilt(n,y) < miarea(end)      )

            mplat_medMCS = vertcat(mplat_medMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_medMCS = vertcat(mplon_medMCS, mpI_vs_mcsI_dt_lon(n,y) );

        elseif(  isnan(mparea_atMCSI_PWfilt(n,y))==0  &  mparea_atMCSI_PWfilt(n,y) > loarea(1)  &  mparea_atMCSI_PWfilt(n,y) < loarea(end)   )

            mplat_loMCS = vertcat(mplat_loMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_loMCS = vertcat(mplon_loMCS, mpI_vs_mcsI_dt_lon(n,y) );
        end

    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)

% now plot histograms of MP origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [2008,332,683,428];
set(gca,'XTick',[])
set(gca,'YTick',[])

title([' Origin locations of MPs (PW>24mm) present at MCSI with MP area: ',num2str(hiarea(1)),' to ', num2str(hiarea(end)) ,' N = ', num2str(length(mplat_hiMCS)) ])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes; 
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy');  

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

plot(ax5,mean(mean(mplon_hiMCS-360,'omitnan')),mean(mean(mplat_hiMCS,'omitnan')),'xr')

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

axis([-125 -70 25 55])

%saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_hiMParea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);



%%%%%%%%%%%%%%%%%%%%%%%%



%subplot(3,1,3)
ff = figure  
ff.Position = [2008,332,683,428];
set(gca,'XTick',[])
set(gca,'YTick',[])

title([' Origin locations of MPs (PW>24mm) present at MCSI with MP area: ',num2str(loarea(1)),' to ', num2str(loarea(end)) ,' N = ', num2str(length(mplat_loMCS)) ])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes; 
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

plot(ax5,mean(mean(mplon_loMCS-360,'omitnan')),mean(mean(mplat_loMCS,'omitnan')),'xr')

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

axis([-125 -70 25 55])

%saveas(ff,horzcat(imout,'/MPorigin_smallareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_loMParea_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);


%stat diff tests, is lare-area-MCS MP obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS)
mean(mplat_hiMCS) 
median(mplat_loMCS)
median(mplat_hiMCS) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)


















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%   MP origins for MPs present at MCSI (broken down by MP peak vorticity)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[mpt mpy] =  size(mpvort_atMCSI_PWfilt)  ;

%%%%% make syn origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hivort  = [0.05200001, 100]*0.001;
mivort   = [0.0390000001, 0.052]*0.001;
lovort   = [0, 0.039]*0.001;

hivort  = [prctile(mpvort_atMCSI_PWfilt,[200/3],'all')+0.0000001, 100000000000];
mivort  = [prctile(mpvort_atMCSI_PWfilt,[100/3],'all')+0.0000001, prctile(mpvort_atMCSI_PWfilt,[200/3],'all')];
lovort  = [0, prctile(mpvort_atMCSI_PWfilt,[100/3],'all')];

% grab MCS duration and syn obj for all events with syn present at MCSI:

MPwithMCSdir_list = [];
MPwithoutMCSdir_list = [];

%lat/lons of origin site of synoptic obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];

for y = 1 : mpy        % which is same as num years of MP objects
    for n = 1 : mpt

        if(  isnan(mpvort_atMCSI_PWfilt(n,y))==0  &  mpvort_atMCSI_PWfilt(n,y) > hivort(1)  &  mpvort_atMCSI_PWfilt(n,y) < hivort(end)    )

            mplat_hiMCS = vertcat(mplat_hiMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_hiMCS = vertcat(mplon_hiMCS, mpI_vs_mcsI_dt_lon(n,y) );

        elseif(  isnan(mpvort_atMCSI_PWfilt(n,y))==0  &  mpvort_atMCSI_PWfilt(n,y) > mivort(1)  &  mpvort_atMCSI_PWfilt(n,y) < mivort(end)      )

            mplat_medMCS = vertcat(mplat_medMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_medMCS = vertcat(mplon_medMCS, mpI_vs_mcsI_dt_lon(n,y) );

        elseif(  isnan(mpvort_atMCSI_PWfilt(n,y))==0  &  mpvort_atMCSI_PWfilt(n,y) > lovort(1)  &  mpvort_atMCSI_PWfilt(n,y) < lovort(end)   )

            mplat_loMCS = vertcat(mplat_loMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_loMCS = vertcat(mplon_loMCS, mpI_vs_mcsI_dt_lon(n,y) );
        end

    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)

% now plot histograms of MP origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [2008,332,683,428];
set(gca,'XTick',[])
set(gca,'YTick',[])

title([' Origin locations of MPs (PW>24mm) present at MCSI with MP vorticity: ',num2str(hivort(1)),' to ', num2str(hivort(end)) ,' N = ', num2str(length(mplat_hiMCS)) ])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes; 
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy');

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

plot(ax5,mean(mean(mplon_hiMCS-360,'omitnan')),mean(mean(mplat_hiMCS,'omitnan')),'xr')

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

axis([-125 -70 25 55])

%saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_hiMPvort_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);



%%%%%%%%%%%%%%%%%%%%%%%%%%%



ff = figure  
ff.Position = [2008,332,683,428];
set(gca,'XTick',[])
set(gca,'YTick',[])

title([' Origin locations of MPs (PW>24mm) present at MCSI with MP vorticity: ',num2str(lovort(1)),' to ', num2str(lovort(end)) ,' N = ', num2str(length(mplat_loMCS)) ])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes; 
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

plot(ax5,mean(mean(mplon_loMCS-360,'omitnan')),mean(mean(mplat_loMCS,'omitnan')),'xr')

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

axis([-125 -70 25 55])

%saveas(ff,horzcat(imout,'/MPorigin_smallareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_loMPvort_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);


%stat diff tests, is lare-area-MCS MP obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS)
mean(mplat_hiMCS) 
median(mplat_loMCS)
median(mplat_hiMCS) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)










% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%     plots of MP origins based on their duration prior to MCSI
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% %  mpI_vs_mcsI_dt
% %  mpI_vs_mcsI_dt_lat
% %  mpI_vs_mcsI_dt_lon
% 
% 
% [mpt mpy] =  size(mpI_vs_mcsI_dt)  ;
% % meanlat_MPstats_ALLYRS
% 
% % prescribed duration bins of mcs (hours):
% hidur    = [22.00001:1000];
% middur   = [9.00001:22];
% lodur    = [0:9];
% 
% % grab MCS duration and syn obj for all events with syn present at MCSI:
% 
% MPwithMCSdir_list = [];
% MPwithoutMCSdir_list = [];
% 
% %lat/lons of origin site of synoptic obj present at bith of lon-, med-, short- duration MCSs
% mplat_hiMCS = [];
% mplat_medMCS = [];
% mplat_loMCS = [];
% mplon_hiMCS = [];
% mplon_medMCS = [];
% mplon_loMCS = [];
% 
% 
% % blah = MPwithMCS_meanWNDDIR600_ALLYRS(:);
% % blah2 = find(blah > NWwind(1)  &  blah  < NWwind(end)) ;
% % blah(blah2)
% 
% 
% for y = 1 : mpy        % which is same as num years of syn objects
%     for n = 1 : mpt
% 
%         if(  isnan(mpI_vs_mcsI_dt(n,y))==0  &  mpI_vs_mcsI_dt(n,y) > hidur(1)  &  mpI_vs_mcsI_dt(n,y) < hidur(end)    )
% 
%             mplat_hiMCS = vertcat(mplat_hiMCS, mpI_vs_mcsI_dt_lat(n,y) );
%             mplon_hiMCS = vertcat(mplon_hiMCS, mpI_vs_mcsI_dt_lon(n,y) );
% 
%         elseif(  isnan(mpI_vs_mcsI_dt(n,y))==0  &  mpI_vs_mcsI_dt(n,y) > middur(1)  &  mpI_vs_mcsI_dt(n,y) < middur(end)      )
% 
%             mplat_medMCS = vertcat(mplat_medMCS, mpI_vs_mcsI_dt_lat(n,y) );
%             mplon_medMCS = vertcat(mplon_medMCS, mpI_vs_mcsI_dt_lon(n,y) );
% 
%         elseif(  isnan( mpI_vs_mcsI_dt(n,y))==0  &  mpI_vs_mcsI_dt(n,y) > lodur(1)  &  mpI_vs_mcsI_dt(n,y) < lodur(end)   )
% 
%             mplat_loMCS = vertcat(mplat_loMCS, mpI_vs_mcsI_dt_lat(n,y) );
%             mplon_loMCS = vertcat(mplon_loMCS, mpI_vs_mcsI_dt_lon(n,y) );
%         end
% 
%     end
% end
% 
% length(mplat_hiMCS)
% length(mplat_medMCS)
% length(mplat_loMCS)
% 
% 
% 
% 
% % NWwind  = [285:315];  %hi
% % Wwind   = [255:285];  %med
% % SWwind  = [225:255];  %lo
% 
% % now plot histograms of MP origins tied to MCSI of hi-, med-, lo-duration MCSs
% 
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% title([' Origin locations of MPs with preMCSI MP duration: ',num2str(hidur(1)),' to ', num2str(hidur(end)) ,' N = ', num2str(length(mplat_hiMCS)) ])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 15])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% axis([-160 -50 15 60])
% 
% %saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
% outlab = horzcat(imout,'/MPorigin_MPhidur_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% %subplot(3,1,3)
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% 
% title([' Origin locations of MPs with preMCSI MP duration: ',num2str(lodur(1)),' to ', num2str(lodur(end)) ,' N = ', num2str(length(mplat_loMCS)) ])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 15])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% axis([-160 -50 15 60])
% 
% %saveas(ff,horzcat(imout,'/MPorigin_smallareaMCS.png'));
% outlab = horzcat(imout,'/MPorigin_MPlodur_filtLS',num2str(filteroutLS),'.eps')
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);
% 
% 
% %stat diff tests, is lare-area-MCS MP obj origin different than for small-area-mcs?:
% 
% mean(mplon_loMCS-360)
% mean(mplon_hiMCS-360) 
% median(mplon_loMCS-360)
% median(mplon_hiMCS-360) 
% 
% alvl = 0.05;
% [sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
% [p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)
% 
% mean(mplat_loMCS)
% mean(mplat_hiMCS) 
% median(mplat_loMCS)
% median(mplat_hiMCS) 
% 
% [sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
% [p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)













%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%   MP origins for MPs present at MCSI (broken down MP sub-600mb min omega)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[mpt mpy] =  size(mpminOMEGAsub600_atMCSI_PWfilt)  ;

%%%%% make syn origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hiw  = [-2.400001, -100];
miw  = [-1.300001, -2.4];
low  = [10, -1.3];

hiw  = [ prctile(mpminOMEGAsub600_atMCSI_PWfilt,[100/3],'all')-0.0000001, prctile(mpminOMEGAsub600_atMCSI_PWfilt,[0/3],'all')];
miw  = [prctile(mpminOMEGAsub600_atMCSI_PWfilt,[200/3],'all')-0.0000001, prctile(mpminOMEGAsub600_atMCSI_PWfilt,[100/3],'all')];
low  = [prctile(mpminOMEGAsub600_atMCSI_PWfilt,[300/3],'all'), prctile(mpminOMEGAsub600_atMCSI_PWfilt,[200/3],'all')];

% grab MCS duration and syn obj for all events with syn present at MCSI:

MPwithMCSdir_list = [];
MPwithoutMCSdir_list = [];

%lat/lons of origin site of synoptic obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];

for y = 1 : mpy        % which is same as num years of MP objects
    for n = 1 : mpt

        if(  isnan(mpminOMEGAsub600_atMCSI_PWfilt(n,y))==0  &  mpminOMEGAsub600_atMCSI_PWfilt(n,y) < hiw(1)  &  mpminOMEGAsub600_atMCSI_PWfilt(n,y) > hiw(end)    )

            mplat_hiMCS = vertcat(mplat_hiMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_hiMCS = vertcat(mplon_hiMCS, mpI_vs_mcsI_dt_lon(n,y) );

        elseif(  isnan(mpminOMEGAsub600_atMCSI_PWfilt(n,y))==0  &  mpminOMEGAsub600_atMCSI_PWfilt(n,y) < miw(1)  &  mpminOMEGAsub600_atMCSI_PWfilt(n,y) > miw(end)      )

            mplat_medMCS = vertcat(mplat_medMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_medMCS = vertcat(mplon_medMCS, mpI_vs_mcsI_dt_lon(n,y) );

        elseif(  isnan(mpminOMEGAsub600_atMCSI_PWfilt(n,y))==0  &  mpminOMEGAsub600_atMCSI_PWfilt(n,y) < low(1)  &  mpminOMEGAsub600_atMCSI_PWfilt(n,y) > low(end)   )

            mplat_loMCS = vertcat(mplat_loMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_loMCS = vertcat(mplon_loMCS, mpI_vs_mcsI_dt_lon(n,y) );
        end

    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)


% now plot histograms of MP origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [2008,332,683,428];

set(gca,'XTick',[])
set(gca,'YTick',[])

title([' Origin locations of MPs (PW>24mm) present at MCSI with MP sub-600 hPa omega: ',num2str(hiw(1)),' to ', num2str(hiw(end)) ,' N = ', num2str(length(mplat_hiMCS)) ])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes;
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

plot(ax5,mean(mean(mplon_hiMCS-360,'omitnan')),mean(mean(mplat_hiMCS,'omitnan')),'xr')

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

axis([-125 -70 25 55])

%saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_hiMPw_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);


%%%%%%%%%%%%%%%%%%%%%%%%%


ff = figure  
ff.Position = [2008,332,683,428];

set(gca,'XTick',[])
set(gca,'YTick',[])

title([' Origin locations of MPs (PW>24mm) present at MCSI with MP sub-600 hPa omega: ',num2str(low(1)),' to ', num2str(low(end)) ,' N = ', num2str(length(mplat_loMCS)) ])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes;
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

plot(ax5,mean(mean(mplon_hiMCS-360,'omitnan')),mean(mean(mplat_loMCS,'omitnan')),'xr')

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

axis([-125 -70 25 55])

%saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_loMPw_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);

%stat diff tests, is lare-area-MCS MP obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS)
mean(mplat_hiMCS) 
median(mplat_loMCS)
median(mplat_hiMCS) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%   MP origins for MPs present at MCSI (broken down MP 0-6 shear)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[mpt mpy] =  size(mpmeanshearmag0to6_atMCSI_PWfilt)  ;

%%%%% make syn origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hiw  = [15.700001, 100];
miw  = [10.800001, 15.7];
low  = [0, 10.8];

hiw  = [prctile(mpmeanshearmag0to6_atMCSI_PWfilt,[200/3],'all')+0.0000001, prctile(mpmeanshearmag0to6_atMCSI_PWfilt,[300/3],'all')];
miw  = [prctile(mpmeanshearmag0to6_atMCSI_PWfilt,[100/3],'all')+0.0000001, prctile(mpmeanshearmag0to6_atMCSI_PWfilt,[200/3],'all')];
low  = [prctile(mpmeanshearmag0to6_atMCSI_PWfilt,[000/3],'all'), prctile(mpmeanshearmag0to6_atMCSI_PWfilt,[100/3],'all')];

% grab MCS duration and syn obj for all events with syn present at MCSI:

MPwithMCSdir_list = [];
MPwithoutMCSdir_list = [];

%lat/lons of origin site of synoptic obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];

for y = 1 : mpy        % which is same as num years of MP objects
    for n = 1 : mpt

        if(  isnan(mpmeanshearmag0to6_atMCSI_PWfilt(n,y))==0  &  mpmeanshearmag0to6_atMCSI_PWfilt(n,y) > hiw(1)  &  mpmeanshearmag0to6_atMCSI_PWfilt(n,y) < hiw(end)    )

            mplat_hiMCS = vertcat(mplat_hiMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_hiMCS = vertcat(mplon_hiMCS, mpI_vs_mcsI_dt_lon(n,y) );

        elseif(  isnan(mpmeanshearmag0to6_atMCSI_PWfilt(n,y))==0  &  mpmeanshearmag0to6_atMCSI_PWfilt(n,y) > miw(1)  &  mpmeanshearmag0to6_atMCSI_PWfilt(n,y) < miw(end)      )

            mplat_medMCS = vertcat(mplat_medMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_medMCS = vertcat(mplon_medMCS, mpI_vs_mcsI_dt_lon(n,y) );

        elseif(  isnan(mpmeanshearmag0to6_atMCSI_PWfilt(n,y))==0  &  mpmeanshearmag0to6_atMCSI_PWfilt(n,y) > low(1)  &  mpmeanshearmag0to6_atMCSI_PWfilt(n,y) < low(end)   )

            mplat_loMCS = vertcat(mplat_loMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_loMCS = vertcat(mplon_loMCS, mpI_vs_mcsI_dt_lon(n,y) );
        end

    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)


% now plot histograms of MP origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [2008,332,683,428];

set(gca,'XTick',[])
set(gca,'YTick',[])

title([' Origin locations of MPs (PW>24mm) present at MCSI with MP 0-6km shear: ',num2str(hiw(1)),' to ', num2str(hiw(end)) ,' N = ', num2str(length(mplat_hiMCS)) ])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes;
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

plot(ax5,mean(mean(mplon_hiMCS-360,'omitnan')),mean(mean(mplat_hiMCS,'omitnan')),'xr')

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

axis([-125 -70 25 55])

%saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_hiMP06shear_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);


%%%%%%%%%%%%%%%%%%%%%%%%%


ff = figure  
ff.Position = [2008,332,683,428];

set(gca,'XTick',[])
set(gca,'YTick',[])

title([' Origin locations of MPs (PW>24mm) present at MCSI with MP 0-6km shear: ',num2str(low(1)),' to ', num2str(low(end)) ,' N = ', num2str(length(mplat_loMCS)) ])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes;
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

plot(ax5,mean(mean(mplon_hiMCS-360,'omitnan')),mean(mean(mplat_loMCS,'omitnan')),'xr')

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

axis([-125 -70 25 55])

%saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_loMP06shear_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);

%stat diff tests, is lare-area-MCS MP obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS)
mean(mplat_hiMCS) 
median(mplat_loMCS)
median(mplat_hiMCS) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%   MP origins for MPs present at MCSI (PW)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[mpt mpy] =  size(mpmeanPW_atMCSI_PWfilt)  ;

%%%%% make syn origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hiw  = [39.000001, 100];
miw  = [29.500001, 39.0];
low  = [0, 29.5];

hiw  = [prctile(mpmeanPW_atMCSI_PWfilt,[200/3],'all')+0.0000001, prctile(mpmeanPW_atMCSI_PWfilt,[300/3],'all')];
miw  = [prctile(mpmeanPW_atMCSI_PWfilt,[100/3],'all')+0.0000001, prctile(mpmeanPW_atMCSI_PWfilt,[200/3],'all')];
low  = [prctile(mpmeanPW_atMCSI_PWfilt,[000/3],'all'), prctile(mpmeanPW_atMCSI_PWfilt,[100/3],'all')];


% grab MCS duration and syn obj for all events with syn present at MCSI:

MPwithMCSdir_list = [];
MPwithoutMCSdir_list = [];

%lat/lons of origin site of synoptic obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];

for y = 1 : mpy        % which is same as num years of MP objects
    for n = 1 : mpt

        if(  isnan(mpmeanPW_atMCSI_PWfilt(n,y))==0  &  mpmeanPW_atMCSI_PWfilt(n,y) > hiw(1)  &  mpmeanPW_atMCSI_PWfilt(n,y) < hiw(end)    )

            mplat_hiMCS = vertcat(mplat_hiMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_hiMCS = vertcat(mplon_hiMCS, mpI_vs_mcsI_dt_lon(n,y) );

        elseif(  isnan(mpmeanPW_atMCSI_PWfilt(n,y))==0  &  mpmeanPW_atMCSI_PWfilt(n,y) > miw(1)  &  mpmeanPW_atMCSI_PWfilt(n,y) < miw(end)      )

            mplat_medMCS = vertcat(mplat_medMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_medMCS = vertcat(mplon_medMCS, mpI_vs_mcsI_dt_lon(n,y) );

        elseif(  isnan(mpmeanPW_atMCSI_PWfilt(n,y))==0  &  mpmeanPW_atMCSI_PWfilt(n,y) > low(1)  &  mpmeanPW_atMCSI_PWfilt(n,y) < low(end)   )

            mplat_loMCS = vertcat(mplat_loMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_loMCS = vertcat(mplon_loMCS, mpI_vs_mcsI_dt_lon(n,y) );
        end

    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)


% now plot histograms of MP origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [2008,332,683,428];

set(gca,'XTick',[])
set(gca,'YTick',[])

title([' Origin locations of MPs (PW>24mm) present at MCSI with MP 0-6km shear: ',num2str(hiw(1)),' to ', num2str(hiw(end)) ,' N = ', num2str(length(mplat_hiMCS)) ])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes;
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

plot(ax5,mean(mean(mplon_hiMCS-360,'omitnan')),mean(mean(mplat_hiMCS,'omitnan')),'xr')

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

axis([-125 -70 25 55])

%saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_hiMPpw_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);


%%%%%%%%%%%%%%%%%%%%%%%%%


ff = figure  
ff.Position = [2008,332,683,428];

set(gca,'XTick',[])
set(gca,'YTick',[])

title([' Origin locations of MPs (PW>24mm) present at MCSI with MP mean PW: ',num2str(low(1)),' to ', num2str(low(end)) ,' N = ', num2str(length(mplat_loMCS)) ])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes;
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

plot(ax5,mean(mean(mplon_loMCS-360,'omitnan')),mean(mean(mplat_loMCS,'omitnan')),'xr')

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

axis([-125 -70 25 55])

%saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_loMPpw_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);

%stat diff tests, is lare-area-MCS MP obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS)
mean(mplat_hiMCS) 
median(mplat_loMCS)
median(mplat_hiMCS) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%   MP origins for MPs present at MCSI (NW/SW flow)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


[mpt mpy] =  size(mpmeanWNDDIR600_atMCSI_PWfilt)  ;

%%%%% make syn origin locations broken down by hi, med, lo MCS duration:

% prescribed duration bins of mcs (hours):
hiw  = [292.5000001, 338];
miw  = [247.5000001, 292.5];
low  = [202.5, 247.5];

% hiw  = [prctile(mpmeanPW_atMCSI_PWfilt,[200/3],'all')+0.0000001, prctile(mpmeanPW_atMCSI_PWfilt,[300/3],'all')];
% miw  = [prctile(mpmeanPW_atMCSI_PWfilt,[100/3],'all')+0.0000001, prctile(mpmeanPW_atMCSI_PWfilt,[200/3],'all')];
% low  = [prctile(mpmeanPW_atMCSI_PWfilt,[000/3],'all'), prctile(mpmeanPW_atMCSI_PWfilt,[100/3],'all')];


% grab MCS duration and syn obj for all events with syn present at MCSI:

MPwithMCSdir_list = [];
MPwithoutMCSdir_list = [];

%lat/lons of origin site of synoptic obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];

for y = 1 : mpy        % which is same as num years of MP objects
    for n = 1 : mpt

        if(  isnan(mpmeanWNDDIR600_atMCSI_PWfilt(n,y))==0  &  mpmeanWNDDIR600_atMCSI_PWfilt(n,y) > hiw(1)  &  mpmeanWNDDIR600_atMCSI_PWfilt(n,y) < hiw(end)    )

            mplat_hiMCS = vertcat(mplat_hiMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_hiMCS = vertcat(mplon_hiMCS, mpI_vs_mcsI_dt_lon(n,y) );

        elseif(  isnan(mpmeanWNDDIR600_atMCSI_PWfilt(n,y))==0  &  mpmeanWNDDIR600_atMCSI_PWfilt(n,y) > miw(1)  &  mpmeanWNDDIR600_atMCSI_PWfilt(n,y) < miw(end)      )

            mplat_medMCS = vertcat(mplat_medMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_medMCS = vertcat(mplon_medMCS, mpI_vs_mcsI_dt_lon(n,y) );

        elseif(  isnan(mpmeanWNDDIR600_atMCSI_PWfilt(n,y))==0  &  mpmeanWNDDIR600_atMCSI_PWfilt(n,y) > low(1)  &  mpmeanWNDDIR600_atMCSI_PWfilt(n,y) < low(end)   )

            mplat_loMCS = vertcat(mplat_loMCS, mpI_vs_mcsI_dt_lat(n,y) );
            mplon_loMCS = vertcat(mplon_loMCS, mpI_vs_mcsI_dt_lon(n,y) );
        end

    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)


% now plot histograms of MP origins tied to MCSI of hi-, med-, lo-duration MCSs

ff = figure  
ff.Position = [2008,332,683,428];

set(gca,'XTick',[])
set(gca,'YTick',[])

title([' Origin locations of MPs (PW>24mm) present at MCSI with MP flow dir: ',num2str(hiw(1)),' to ', num2str(hiw(end)) ,' N = ', num2str(length(mplat_hiMCS)) ])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes;
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

plot(ax5,mean(mean(mplon_hiMCS-360,'omitnan')),mean(mean(mplat_hiMCS,'omitnan')),'xr')

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

axis([-125 -70 25 55])

%saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_NW_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);


%%%%%%%%%%%%%%%%%%%%%%%%%


ff = figure  
ff.Position = [2008,332,683,428];

set(gca,'XTick',[])
set(gca,'YTick',[])

title([' Origin locations of MPs (PW>24mm) present at MCSI with flow dir: ',num2str(low(1)),' to ', num2str(low(end)) ,' N = ', num2str(length(mplat_loMCS)) ])

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
ax4 = axes;
ax5 = axes;
linkaxes([ax1,ax2,ax3,ax4,ax5],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax4,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

plot(ax5,mean(mean(mplon_loMCS-360,'omitnan')),mean(mean(mplat_loMCS,'omitnan')),'xr')

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

set(ax4,'Color','None')       %p
set(ax4, 'visible', 'off');   %p

set(ax5,'Color','None')       %p
set(ax5, 'visible', 'off');   %p

axis([-125 -70 25 55])

%saveas(ff,horzcat(imout,'/MPorigin_largeareaMCS.png'));
outlab = horzcat(imout,'/MPorigin_loMPpw_filtLS',num2str(filteroutLS),'_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);

%stat diff tests, is lare-area-MCS MP obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS)
mean(mplat_hiMCS) 
median(mplat_loMCS)
median(mplat_hiMCS) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%
%%%%%%%    Make correlograms of MCS lifetime charactersitics vs: 
%%%%%%%         1) MP vars at time of MCSI
%%%%%%%         2) MP vars during MCS overlap
%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% repeated from above to (re)fix for whatever reason it breaks:
totalrainmass_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    totalrainmass_MCSstats_ALLYRSb(:) = NaN;  
rainmass  =  totalrain_MCSstats_ALLYRS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        %for t = 1:mtimes
            totalrainmass_MCSstats_ALLYRSb(n,y)  =  sum (   rainmass(:,n,y) , 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
        %end
    end
end
totalrainmass_MCSstats_ALLYRSb(totalrainmass_MCSstats_ALLYRSb==0) = NaN;

%recalc speed (though not sure I'm crazy about matlabs motionx,y results?
MP_speeds_ALLYRS = (  MotionX_MPstats_ALLYRS.*MotionX_MPstats_ALLYRS +   MotionY_MPstats_ALLYRS.*MotionY_MPstats_ALLYRS ).^0.5   ;


%%%% For MCSs with a MP obj present at MCSI: 

MPVORTatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;       	MPVORTatMCSI_ALLYRS(:) = NaN ;         % magnitude of the vorticity at time of MCSI
%   MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;                                              % duration of vorticity track prior to time of MCSI   % already defined above
MPAREAatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;      	MPAREAatMCSI_ALLYRS(:) = NaN ;         % area of vorticity at time of MCSI
MPCOLLOCMCS_ALLYRS = zeros(mcs_tracks,mcs_years) ;         MPCOLLOCMCS_ALLYRS(:) = NaN ;    % Number of time steps post-mcsi with a syn obj present 
MPSPEEDatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;       MPSPEEDatMCSI_ALLYRS(:) = NaN ;    % MP obj speed at time of MCSI

MPmeanMUCAPEatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;           MPmeanMUCAPEatMCSI_ALLYRS(:) = NaN ;
MPmaxMUCAPEatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            MPmaxMUCAPEatMCSI_ALLYRS(:) = NaN ;
MPmeanMUCINatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            MPmeanMUCINatMCSI_ALLYRS(:) = NaN ;
MPminMUCINatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;             MPminMUCINatMCSI_ALLYRS(:) = NaN ;
MPmeanMULFCatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            MPmeanMULFCatMCSI_ALLYRS(:) = NaN ;
MPmeanMUELatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;             MPmeanMUELatMCSI_ALLYRS(:) = NaN ;
MPmeanPWatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;               MPmeanPWatMCSI_ALLYRS(:) = NaN ;
MPmaxPWatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;                MPmaxPWatMCSI_ALLYRS(:) = NaN ;
MPminPWatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;                MPminPWatMCSI_ALLYRS(:) = NaN ;
MPmeanshearmag0to2atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     MPmeanshearmag0to2atMCSI_ALLYRS(:) = NaN ;
MPmaxshearmag0to2atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;      MPmaxshearmag0to2atMCSI_ALLYRS(:) = NaN ;
MPmeanshearmag0to6atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     MPmeanshearmag0to6atMCSI_ALLYRS(:) = NaN ;
MPmaxshearmag0to6atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;      MPmaxshearmag0to6atMCSI_ALLYRS(:) = NaN ;
MPmeanshearmag2to9atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     MPmeanshearmag2to9atMCSI_ALLYRS(:) = NaN ;
MPmaxshearmag2to9atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;      MPmaxshearmag2to9atMCSI_ALLYRS(:) = NaN ;
MPmeanOMEGA600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;         MPmeanOMEGA600atMCSI_ALLYRS(:) = NaN ;
MPminOMEGA600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;          MPminOMEGA600atMCSI_ALLYRS(:) = NaN ;
MPminOMEGAsub600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;       MPminOMEGAsub600atMCSI_ALLYRS(:) = NaN ; 
MPmeanVIWVDatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            MPmeanVIWVDatMCSI_ALLYRS(:) = NaN ;
MPminVIWVDatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;             MPminVIWVDatMCSI_ALLYRS(:) = NaN ;
MPmaxVIWVDatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;             MPmaxVIWVDatMCSI_ALLYRS(:) = NaN ;
MPmeanDIV750atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;           MPmeanDIV750atMCSI_ALLYRS(:) = NaN ;
MPminDIV750atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            MPminDIV750atMCSI_ALLYRS(:) = NaN ;
MPminDIVsub600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;         MPminDIVsub600atMCSI_ALLYRS(:) = NaN ;
MPmeanWNDSPD600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;        MPmeanWNDSPD600atMCSI_ALLYRS(:) = NaN ;
MPmeanWNDDIR600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;        MPmeanWNDDIR600atMCSI_ALLYRS(:) = NaN ;

%%% catalog these MP obj traits in MCS(tracks,years) space:
for y = 1:mcs_years
    for n = 1:mcs_tracks
        %  y = 1; n = 76;     y = 15; n = 317;
        %  blah = mcsibasetime_perMCS_ALLYRS(1:2,n,y) ;
        %  blah_yymmddhhmmss = datetime(blah, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;
        
        tmp = length(  find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  )  ;  %num of time in MCS with an MP
        MPCOLLOCMCS_ALLYRS(n,y) = tmp  ;  % NOTE: this includes all syn objs, not only the one(s) presnt during mcsi period
        
        % syn obj characteristics for syn present @ MCSI events:
        if(    isnan( MCSI_with_MP_ALLYRS(n,y) ) == 0    )
            
            %time of MCSI (defined well above)
            MCSItime = mcsibasetime_perMCS_ALLYRS(1:2,n,y) ;
            %the syn object present at MCSI
            mpobj = MCSI_with_MP_ALLYRS(n,y) ;
            
            blad = isnan(floor(basetime_MPstats_ALLYRS(:,mpobj,y)/100))==0 ; blad = find(blad >0) ;

            if( isnan(mpobj)==0 & length(blad)>0      )

                    %    basetime_MPstats_met_yymmddhhmmss_ALLYRS(:,mpobj,y)

                    %to account for mp obj present at second time in MCSI period but not first (since we are letting MCSI period be t = 1:2:
                    MPt1 = find( floor(basetime_MPstats_ALLYRS(:,mpobj,y)/100)  ==  floor(MCSItime(1)/100) )  ;
                    MPt2 = find( floor(basetime_MPstats_ALLYRS(:,mpobj,y)/100)  ==  floor(MCSItime(2)/100) )  ;
                    % time in syn obj's record when MCSI happens:
                    MPt = vertcat(MPt1,MPt2) ;  MPt = MPt(1);
                    
                    %populate the syn obj metrics of interest:
                    MPVORTatMCSI_ALLYRS(n,y) = maxVOR600_MPstats_ALLYRS(MPt,mpobj,y)  .* MPdurMASK_forMPs(MPt,mpobj,y);
                    MPAREAatMCSI_ALLYRS(n,y) = area_MPstats_ALLYRS(MPt,mpobj,y)  .* MPdurMASK_forMPs(MPt,mpobj,y);
                    % MPPREDURatMCSI_ALLYRS -  already cataloged above
                    %tmp = length(  find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  )  ;
                    %MPCOLLOCMCS_ALLYRS(n,y) = tmp  ;  % NOTE: this includes all syn objs, not only the one(s) presnt during mcsi period
                    MPSPEEDatMCSI_ALLYRS(n,y) =  ( ( MotionX_MPstats_ALLYRS(MPt,mpobj,y) .* MotionX_MPstats_ALLYRS(MPt,mpobj,y)  +   MotionY_MPstats_ALLYRS(MPt,mpobj,y).*MotionY_MPstats_ALLYRS(MPt,mpobj,y) ).^0.5 ).* ( MPdurMASK_forMPs(MPt,mpobj,y) )  ;
                   
                    MPmeanMUCAPEatMCSI_ALLYRS(n,y) =           meanMUCAPE_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPmaxMUCAPEatMCSI_ALLYRS(n,y) =            maxMUCAPE_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y); 
                    MPmeanMUCINatMCSI_ALLYRS(n,y) =            meanMUCIN_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y); 
                    MPminMUCINatMCSI_ALLYRS(n,y) =             minMUCIN_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y); 
                    MPmeanMULFCatMCSI_ALLYRS(n,y) =            meanMULFC_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y); 
                    MPmeanMUELatMCSI_ALLYRS(n,y) =             meanMUEL_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y); 
                    MPmeanPWatMCSI_ALLYRS(n,y) =               meanPW_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y); 
                    MPmaxPWatMCSI_ALLYRS(n,y) =                maxPW_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y); 
                    MPminPWatMCSI_ALLYRS(n,y) =                minPW_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y); 
                    MPmeanshearmag0to2atMCSI_ALLYRS(n,y) =     meanshearmag0to2_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y); 
                    MPmaxshearmag0to2atMCSI_ALLYRS(n,y) =      maxshearmag0to2_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPmeanshearmag0to6atMCSI_ALLYRS(n,y) =     meanshearmag0to6_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPmaxshearmag0to6atMCSI_ALLYRS(n,y) =      maxshearmag0to6_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPmeanshearmag2to9atMCSI_ALLYRS(n,y) =     meanshearmag2to9_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPmaxshearmag2to9atMCSI_ALLYRS(n,y) =      maxshearmag2to9_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPmeanOMEGA600atMCSI_ALLYRS(n,y) =         meanOMEGA600_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPminOMEGA600atMCSI_ALLYRS(n,y) =          minOMEGA600_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPminOMEGAsub600atMCSI_ALLYRS(n,y) =       minOMEGAsub600_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPmeanVIWVDatMCSI_ALLYRS(n,y) =            meanVIWVD_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPminVIWVDatMCSI_ALLYRS(n,y) =             minVIWVD_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPmaxVIWVDatMCSI_ALLYRS(n,y) =             maxVIWVD_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPmeanDIV750atMCSI_ALLYRS(n,y) =           meanDIV750_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPminDIV750atMCSI_ALLYRS(n,y) =            minDIV750_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPminDIVsub600atMCSI_ALLYRS(n,y) =         minDIVsub600_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPmeanWNDSPD600atMCSI_ALLYRS(n,y) =        meanWNDSPD600_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  
                    MPmeanWNDDIR600atMCSI_ALLYRS(n,y) =        meanWNDDIR600_MPstats_ALLYRS(MPt,mpobj,y) .* MPdurMASK_forMPs(MPt,mpobj,y);  

            end
            
        end 
    end
end
MPCOLLOCMCS_ALLYRS(MPCOLLOCMCS_ALLYRS==0) = NaN;


length( find(MPCOLLOCMCS_ALLYRS > 0) )


ctop = 15;

dualpol_colmap




%%%   Now calc the 2D histograms of MP obj properties throughout MCS
%%%   lifetime (while they are collocated) rather than just the MP obj 
%%%   properties @ time of MCSI

%%%% For MCSs with a SYN obj present at any time throughout its life: 

MPVORTfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        MPVORTfullmcs_ALLYRS(:) = NaN ;         % magnitude of the max vorticity while syn obj touching mcs
MPAREAfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      	MPAREAfullmcs_ALLYRS(:) = NaN ;         % area of vorticity while syn obj touching mcs
MPSPEEDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;       MPSPEEDfullmcs_ALLYRS(:) = NaN ;        % Syn obj speed while syn obj touching mcs
MPCOLLOCfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      MPCOLLOCfullmcs_ALLYRS(:) = NaN ;       % collocation period of MCS-MP (if multiple MCSs per MP, use the longest collocation per MP?)
% MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     % duration of vorticity track prior to time of MCSI   % already defined above
% MPCOLLOCMCS_ALLYRS = zeros(mcs_tracks,mcs_years) ;    % Number of time steps post-mcsi with a syn obj present - already defined above

MPmeanMUCAPEfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;           MPmeanMUCAPEfullmcs_ALLYRS(:) = NaN ;
MPmaxMUCAPEfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            MPmaxMUCAPEfullmcs_ALLYRS(:) = NaN ;
MPmeanMUCINfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            MPmeanMUCINfullmcs_ALLYRS(:) = NaN ;
MPminMUCINfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             MPminMUCINfullmcs_ALLYRS(:) = NaN ;
MPmeanMULFCfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            MPmeanMULFCfullmcs_ALLYRS(:) = NaN ;
MPmeanMUELfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             MPmeanMUELfullmcs_ALLYRS(:) = NaN ;
MPmeanPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;               MPmeanPWfullmcs_ALLYRS(:) = NaN ;
MPmaxPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;                MPmaxPWfullmcs_ALLYRS(:) = NaN ;
MPminPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;                MPminPWfullmcs_ALLYRS(:) = NaN ;
MPmeanshearmag0to2fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     MPmeanshearmag0to2fullmcs_ALLYRS(:) = NaN ;
MPmaxshearmag0to2fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      MPmaxshearmag0to2fullmcs_ALLYRS(:) = NaN ;
MPmeanshearmag0to6fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     MPmeanshearmag0to6fullmcs_ALLYRS(:) = NaN ;
MPmaxshearmag0to6fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      MPmaxshearmag0to6fullmcs_ALLYRS(:) = NaN ;
MPmeanshearmag2to9fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     MPmeanshearmag2to9fullmcs_ALLYRS(:) = NaN ;
MPmaxshearmag2to9fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      MPmaxshearmag2to9fullmcs_ALLYRS(:) = NaN ;
MPmeanOMEGA600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;         MPmeanOMEGA600fullmcs_ALLYRS(:) = NaN ;
MPminOMEGA600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;          MPminOMEGA600fullmcs_ALLYRS(:) = NaN ;
MPminOMEGAsub600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;       MPminOMEGAsub600fullmcs_ALLYRS(:) = NaN ; 
MPmeanVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            MPmeanVIWVDfullmcs_ALLYRS(:) = NaN ;
MPminVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             MPminVIWVDfullmcs_ALLYRS(:) = NaN ;
MPmaxVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             MPmaxVIWVDfullmcs_ALLYRS(:) = NaN ;
MPmeanDIV750fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;           MPmeanDIV750fullmcs_ALLYRS(:) = NaN ;
MPminDIV750fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            MPminDIV750fullmcs_ALLYRS(:) = NaN ;
MPminDIVsub600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;         MPminDIVsub600fullmcs_ALLYRS(:) = NaN ;
MPmeanWNDSPD600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        MPmeanWNDSPD600fullmcs_ALLYRS(:) = NaN ;
MPmeanWNDDIR600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        MPmeanWNDDIR600fullmcs_ALLYRS(:) = NaN ;



%%% catalog these syn obj traits in MCS(tracks,years) space:
for y = 1:mcs_years
    for n = 1:mcs_tracks
        
        %   n = 79;  y = 2;   blah = MPtracks_perMCS_ALLYRS;
        
        %t-indices in each MCS track where there is a syn present
        mpspresent = find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  ;
        
        if( isempty(mpspresent) == 0)

            %empty vars to hold mean/max metrics for each syn object that
            %you will later mean/max again to relate to MCSs:
            mps_vorts = [] ;
            mps_areas = [] ;
            mps_speeds = [] ;
            mps_colloc = [];
            meanMUCAPE = [] ;
            maxMUCAPE = [] ;
            meanMUCIN = [] ;
            minMUCIN = [] ;
            meanMULFC = [] ;
            meanMUEL = [] ;
            meanPW = [] ;
            maxPW = [] ;
            minPW = [] ;
            meanshearmag0to2 = [] ;
            maxshearmag0to2 = [] ;
            meanshearmag0to6 = [] ;
            maxshearmag0to6 = [] ;
            meanshearmag2to9 = [] ;
            maxshearmag2to9 = [] ;
            meanOMEGA600 = [] ;
            minOMEGA600 = [] ;
            minOMEGAsub600 = [] ;
            meanVIWVD = [] ;
            minVIWVD = [] ;
            maxVIWVD = [] ;
            meanDIV750 = [] ;
            minDIV750 = [] ;
            minDIVsub600 = [] ;
            meanWNDSPD600 = [] ;
            meanWNDDIR600 = [] ;
            
            %all of the unique syn tracks in this MCS's full track:
            mpnums = unique(MPtracks_perMCS_ALLYRS(mpspresent,n,y)) ;
            
            %loop thru all of the syn objs overlapping the current MCS
            for s = 1:length(mpnums)
                
                %find MCS's time indices when current syn object is present, then
                %log the first & last time
                mp_mcst = find( MPtracks_perMCS_ALLYRS(:,n,y) == mpnums(s) )  ;
                mcst1 = basetime_MCSstats_ALLYRS(mp_mcst(1),n,y) ;
                mcst2 = basetime_MCSstats_ALLYRS(mp_mcst(end),n,y) ;
                
                %find the time indices in current syn obj's track corersponding to
                %the MCS overlap period:
                MPti1 = find( floor(mcst1/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;
                MPti2 = find( floor(mcst2/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;    

                % log the max/mean of the current syn obj's
                % characteristics during its overlap period with the MCS.
                % throw it into an array that contains the same for all
                % other syn obj's touching the current MCS:
                mps_vorts =  vertcat(mps_vorts, max( maxVOR600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;      %max vort of syn obj during its contact with MCS
                mps_areas =  vertcat(mps_areas, max( area_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )   ) ;          %max area of syn obj during its contact with MCS  
                mps_speeds = vertcat(mps_speeds, mean( MP_speeds_ALLYRS(MPti1:MPti2,mpnums(s),y) , 'omitnan')) ;  %mean speed of syn obj during its contact with MCS  
                
%                 %calced this seperately above already
%                 mps_colloc =  vercat(mps_colloc,    max(    MPMCS_collocDur_MPstats(:,mpnums(s),y) )          );
             
                meanMUCAPE          = vertcat( meanMUCAPE, max( meanMUCAPE_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                maxMUCAPE           = vertcat( maxMUCAPE, max(  maxMUCAPE_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                meanMUCIN           = vertcat( meanMUCIN, min(  meanMUCIN_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                minMUCIN            = vertcat( minMUCIN, min(   minMUCIN_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                meanMULFC           = vertcat( meanMULFC, min(  meanMULFC_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                meanMUEL            = vertcat( meanMUEL, max(   meanMUEL_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                meanPW              = vertcat( meanPW, max(     meanPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                maxPW               = vertcat( maxPW, max(      maxPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                minPW               = vertcat( minPW, min(      minPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                meanshearmag0to2    = vertcat( meanshearmag0to2, max(  meanshearmag0to2_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                maxshearmag0to2     = vertcat( maxshearmag0to2, max(   maxshearmag0to2_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                meanshearmag0to6    = vertcat( meanshearmag0to6, max(  meanshearmag0to6_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                maxshearmag0to6     = vertcat( maxshearmag0to6, max(   maxshearmag0to6_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                meanshearmag2to9    = vertcat( meanshearmag2to9, max(  meanshearmag2to9_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                maxshearmag2to9     = vertcat( maxshearmag2to9, max(   maxshearmag2to9_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                meanOMEGA600        = vertcat( meanOMEGA600, min(      meanOMEGA600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                minOMEGA600         = vertcat( minOMEGA600, min(       minOMEGA600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                minOMEGAsub600      = vertcat( minOMEGAsub600, min(    minOMEGAsub600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                meanVIWVD           = vertcat( meanVIWVD, max(         meanVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                minVIWVD            = vertcat( minVIWVD, min(          minVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                maxVIWVD            = vertcat( maxVIWVD, max(          maxVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                meanDIV750          = vertcat( meanDIV750, min(        meanDIV750_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                minDIV750           = vertcat( minDIV750, min(         minDIV750_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                minDIVsub600        = vertcat( minDIVsub600, min(      minDIVsub600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                meanWNDSPD600       = vertcat( meanWNDSPD600, max(     meanWNDSPD600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;
                meanWNDDIR600       = vertcat( meanWNDDIR600, mean(    meanWNDDIR600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;

            end
            
            %end up with the means of all of the mean/max MP objs
            %characteristics across all syn objects touching the current MCS:
            MPVORTfullmcs_ALLYRS(n,y)       =  mean( mps_vorts , 'omitnan');       
            MPAREAfullmcs_ALLYRS(n,y)       =  mean( mps_areas , 'omitnan');
            MPSPEEDfullmcs_ALLYRS(n,y)      =  mean( mps_speeds , 'omitnan');

            MPmeanMUCAPEfullmcs_ALLYRS(n,y)         =  mean( meanMUCAPE , 'omitnan'); 
            MPmaxMUCAPEfullmcs_ALLYRS(n,y)          =  mean( maxMUCAPE , 'omitnan'); 
            MPmeanMUCINfullmcs_ALLYRS(n,y)          =  mean( meanMUCIN , 'omitnan'); 
            MPminMUCINfullmcs_ALLYRS(n,y)           =  mean( minMUCIN , 'omitnan'); 
            MPmeanMULFCfullmcs_ALLYRS(n,y)          =  mean( meanMULFC , 'omitnan'); 
            MPmeanMUELfullmcs_ALLYRS(n,y)           =  mean( meanMUEL , 'omitnan'); 
            MPmeanPWfullmcs_ALLYRS(n,y)             =  mean( meanPW , 'omitnan'); 
            MPmaxPWfullmcs_ALLYRS(n,y)              =  mean( maxPW , 'omitnan'); 
            MPminPWfullmcs_ALLYRS(n,y)              =  mean( minPW , 'omitnan'); 
            MPmeanshearmag0to2fullmcs_ALLYRS(n,y)   =  mean( meanshearmag0to2 , 'omitnan'); 
            MPmaxshearmag0to2fullmcs_ALLYRS(n,y)    =  mean( maxshearmag0to2 , 'omitnan'); 
            MPmeanshearmag0to6fullmcs_ALLYRS(n,y)   =  mean( meanshearmag0to6 , 'omitnan'); 
            MPmaxshearmag0to6fullmcs_ALLYRS(n,y)    =  mean( maxshearmag0to6 , 'omitnan'); 
            MPmeanshearmag2to9fullmcs_ALLYRS(n,y)   =  mean( meanshearmag2to9 , 'omitnan'); 
            MPmaxshearmag2to9fullmcs_ALLYRS(n,y)    =  mean( maxshearmag2to9 , 'omitnan'); 
            MPmeanOMEGA600fullmcs_ALLYRS(n,y)       =  mean( meanOMEGA600 , 'omitnan'); 
            MPminOMEGA600fullmcs_ALLYRS(n,y)        =  mean( minOMEGA600 , 'omitnan'); 
            MPminOMEGAsub600fullmcs_ALLYRS(n,y)     =  mean( minOMEGAsub600 , 'omitnan'); 
            MPmeanVIWVDfullmcs_ALLYRS(n,y)          =  mean( meanVIWVD , 'omitnan'); 
            MPminVIWVDfullmcs_ALLYRS(n,y)           =  mean( minVIWVD , 'omitnan'); 
            MPmaxVIWVDfullmcs_ALLYRS(n,y)           =  mean( maxVIWVD , 'omitnan'); 
            MPmeanDIV750fullmcs_ALLYRS(n,y)         =  mean( meanDIV750 , 'omitnan'); 
            MPminDIV750fullmcs_ALLYRS(n,y)          =  mean( minDIV750 , 'omitnan'); 
            MPminDIVsub600fullmcs_ALLYRS(n,y)       =  mean( minDIVsub600 , 'omitnan'); 
            MPmeanWNDSPD600fullmcs_ALLYRS(n,y)      =  mean( meanWNDSPD600 , 'omitnan'); 
            MPmeanWNDDIR600fullmcs_ALLYRS(n,y)      =  mean( meanWNDDIR600 , 'omitnan'); 

        end
    end
end          









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%        correlogram of all vars vs all vars
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%
%%%  for events with MPs present at MCSI

%%%% MCS lifetime metrics
MCS_maxarea        = maxareapf_MCSstats_ALLYRS .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_areagrowthrate = dAdt_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_meanspeed      = MCSspeed_MCSstats_ALLYRS .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_totalrainmass  = totalrainmass_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_HvyRainAccum    =  pf_accumrainheavy_MCSstats_ALLYRSb  .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_EchoTop50dBZ    =   pf_ETH50_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_EchoTop30dBZ    =   pf_ETH30_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_ConvectRainRate  =  convrainrate_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_ConvectRainArea  =  convrainarea_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_ConvectRainMass  =  convrainmass_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_StratiformRainRate  =  stratrainrate_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_StratiformRainArea  =  stratrainarea_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_StratiformRainMass  =  stratrainmass_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;

%%%% MP metric at MCSI
MP_vorticity          =  MPVORTatMCSI_ALLYRS;
MP_speed              =  MPSPEEDatMCSI_ALLYRS;
MP_area               =  MPAREAatMCSI_ALLYRS;
MP_preMCSduration     =  MPPREDURatMCSI_ALLYRS;

%%%% MP env metric at MCSI
%MP_meanMUCAPE  = MPmeanMUCAPEatMCSI_ALLYRS;
MP_maxMUCAPE   = MPmaxMUCAPEatMCSI_ALLYRS;
%MP_meanMUCIN  =  MPmeanMUCINatMCSI_ALLYRS;
MP_minMUCIN  =   MPminMUCINatMCSI_ALLYRS;
MP_meanMULFC  =  MPmeanMULFCatMCSI_ALLYRS;
MP_meanMUEL  =   MPmeanMUELatMCSI_ALLYRS;
MP_meanPW  =     MPmeanPWatMCSI_ALLYRS;
%MP_maxPW  =      MPmaxPWatMCSI_ALLYRS;
%MP_minPW  =       MPminPWatMCSI_ALLYRS;
MP_meanshearmag0to2  =  MPmeanshearmag0to2atMCSI_ALLYRS;
%MP_maxshearmag0to2  =  MPmaxshearmag0to2atMCSI_ALLYRS;
MP_meanshearmag0to6  = MPmeanshearmag0to6atMCSI_ALLYRS;
%MP_maxshearmag0to6  =  MPmaxshearmag0to6atMCSI_ALLYRS;
MP_meanshearmag2to9  =  MPmeanshearmag2to9atMCSI_ALLYRS;
%MP_maxshearmag2to9  =  MPmaxshearmag2to9atMCSI_ALLYRS;
%MP_meanOMEGA600  =    MPmeanOMEGA600atMCSI_ALLYRS;
MP_minOMEGA600  =    MPminOMEGA600atMCSI_ALLYRS;
MP_minOMEGAsub600  =  MPminOMEGAsub600atMCSI_ALLYRS;
%MP_meanVIWVD  =      MPmeanVIWVDatMCSI_ALLYRS;
%MP_minVIWVD  =       MPminVIWVDatMCSI_ALLYRS;
%MP_maxVIWVD  =       MPmaxVIWVDatMCSI_ALLYRS;
%MP_meanDIV750  =     MPmeanDIV750atMCSI_ALLYRS;
MP_minDIV750  =      MPminDIV750atMCSI_ALLYRS;
MP_minDIVsub600  =    MPminDIVsub600atMCSI_ALLYRS;
MP_meanWNDSPD600  =   MPmeanWNDSPD600atMCSI_ALLYRS;
MP_meanWNDDIR600  =   MPmeanWNDDIR600atMCSI_ALLYRS;



ALL_vars = {'MCS_maxarea' ;
    'MCS_areagrowthrate'  ;
    'MCS_meanspeed' ;
    'MCS_totalrainmass' ;
    'MCS_HvyRainAccum'  ;
    'MCS_EchoTop50dBZ'  ;
    'MCS_EchoTop30dBZ'  ;
    'MCS_ConvectRainRate' ;
    'MCS_ConvectRainArea' ;
    'MCS_ConvectRainMass' ;
    'MCS_StratiformRainRate' ;
    'MCS_StratiformRainArea' ;
    'MCS_StratiformRainMass' ;
    'MP_vorticity';
    'MP_speed';
    'MP_area';
    'MP_preMCSduration';
    'MP_maxMUCAPE';
    'MP_minMUCIN';
    'MP_meanMULFC';
    'MP_meanMUEL';
    'MP_meanPW';
    'MP_meanshearmag0to2';
    'MP_meanshearmag0to6';
    'MP_meanshearmag2to9';
    'MP_meanWNDSPD600';
    %'MP_meanWNDDIR600'
    'MP_minOMEGAsub600';
    'MP_minDIVsub600'};

ALL_vars = flipdim(ALL_vars,1) ;

ALL_corrs = zeros(length(ALL_vars),length(ALL_vars));     ALL_corrs(:) = NaN;
ALL_Ps = zeros(length(ALL_vars),length(ALL_vars));        ALL_Ps(:) = NaN;
ALL_statsig = zeros(length(ALL_vars),length(ALL_vars));        ALL_statsig(:) = NaN;
SIGTHRESH = 0.05;
for n = 1:length(ALL_vars)
    for m = 1:length(ALL_vars)
        %  n = 1; m = 3
        AA = char(ALL_vars(n)) ; 
        AA = eval(AA);
        BB = char(ALL_vars(m)) ;  
        BB = eval(BB);
        kill = isnan(BB);
        BB(kill) = []; AA(kill) = [];
        kill = isnan(AA);
        BB(kill) = []; AA(kill) = [];
        [corab, pval] = corrcoef(AA(:),BB(:)); corab = corab(2); pval = pval(2);
        ALL_corrs(n,m) = corab ;
        ALL_Ps(n,m) = pval;
        if(pval < SIGTHRESH)
            ALL_statsig(n,m) = NaN;
        else
            ALL_corrs(n,m) = NaN;
            ALL_statsig(n,m) = 0; %0;    
        end
    end
end
ALL_corrs = single(ALL_corrs);
isupper = logical(triu(ones(size(ALL_corrs)),1));
ALL_corrs(isupper) = NaN;
ALL_corrs(ALL_corrs >= 0.99999999999999999999999) = NaN;

ALL_statsig = single(ALL_statsig);
isupper = logical(triu(ones(size(ALL_statsig)),1));
ALL_statsig(isupper) = NaN;
ALL_statsig(ALL_statsig >= 0.99999999999999999999999) = NaN;

varlab = {};
for l = 1:length(ALL_vars)
   asd = char(ALL_vars(l,:) )   ;
   asd(find(asd=='_'))=' '   ;
   varlab = vertcat(varlab,asd);
end

%round 
ALL_corrs = round(ALL_corrs,2);

dualpol_colmap
ff = figure('Position',[246,77,1187,900])
h = heatmap(ALL_corrs,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
h.NodeChildren(3).YDir='normal';
colormap(flipud(pepsi2))
caxis([-1 1])
h.XDisplayLabels = varlab;
h.YDisplayLabels = varlab;
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';
title(['Correlogram - MCS lifetime stats, MP stats at MCSI (- 3hr) (filter out LS,preMCSIdur<3hrs)',keptmonslab ]) 

% 
% dualpol_colmap
% ff = figure('Position',[246,77,1187,900])
% h = heatmap(ALL_statsig,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
% h.NodeChildren(3).YDir='normal';
% colormap(flipud(pepsi2))
% caxis([-1 1])
% h.XDisplayLabels = varlab;
% h.YDisplayLabels = varlab;
% ax = gca;
% axp = struct(ax);       %you will get a warning
% axp.Axes.XAxisLocation = 'top';
% title('Pvals - MCS lifetime stats, MP stats at MCSI (- 3hr) (filter out LS,preMCSIdur<3hrs)' ) 

%saveas(h, horzcat(imout,'/Correlgram_MPatMCSI.png') );
outlab = horzcat(imout,'/Correlgram_MPatMCSI','_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);


% ff = figure('Position',[246,77,1187,900])
% h = heatmap(ALL_statsig,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
% h.NodeChildren(3).YDir='normal';
% colormap(flipud(pepsi2))
% caxis([-1 1])
% h.XDisplayLabels = varlab;
% h.YDisplayLabels = varlab;
% ax = gca;
% axp = struct(ax);       %you will get a warning
% axp.Axes.XAxisLocation = 'top';
% title('Correlogram - MCS lifetime stats, mean MP stats at MCSI (- 3hr) (filter out LS,preMCSIdur<3hrs)' ) 
% 
% saveas(h, horzcat(imout,'/Correlgram_MPatMCSI_SIGMAP.png') );
% outlab = horzcat(imout,'/Correlgram_MPatMCSI_SIGMAP.eps');
% EPSprint = horzcat('print -painters -depsc ',outlab);
% eval([EPSprint]);










%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  for events with MPs & MCSs collocated. I believe vars in are in MCSstats
%%%  space ( before they are 1D(:) converted)

%%%% MCS lifetime metrics
MCS_maxarea             = maxareapf_MCSstats_ALLYRS(:) ;
MCS_areagrowthrate      = dAdt_MCSstats_ALLYRSb(:) ;
MCS_meanspeed           = MCSspeed_MCSstats_ALLYRS(:) ;
MCS_totalrainmass       = totalrainmass_MCSstats_ALLYRSb(:) ;
MCS_HvyRainAccum        = pf_accumrainheavy_MCSstats_ALLYRSb(:)  ;
MCS_EchoTop50dBZ        = pf_ETH50_MCSstats_ALLYRSb(:)  ;
MCS_EchoTop30dBZ        = pf_ETH30_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainRate     = convrainrate_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainArea     = convrainarea_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainMass     = convrainmass_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainRate  = stratrainrate_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainArea  = stratrainarea_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainMass  = stratrainmass_MCSstats_ALLYRSb(:)  ;

%%%% mean MP metric while collocated with MCS
MP_vorticity          =  MPVORTfullmcs_ALLYRS(:)   ;
MP_speed              =  MPSPEEDfullmcs_ALLYRS(:)  ;
MP_area               =  MPAREAfullmcs_ALLYRS(:)   ;
MP_preMCSduration     =  MPPREDURatMCSI_ALLYRS(:)  ;
MP_collocperiod       =  MPCOLLOCMCS_ALLYRS(:)     ;
%%%% MP env metric at MCSI
MP_maxMUCAPE          =  MPmaxMUCAPEfullmcs_ALLYRS ;
MP_minMUCIN           =  MPminMUCINfullmcs_ALLYRS;
MP_meanMULFC          =  MPmeanMULFCfullmcs_ALLYRS;
MP_meanMUEL           =  MPmeanMUELfullmcs_ALLYRS ; 
MP_meanPW             =  MPmeanPWfullmcs_ALLYRS;
MP_meanshearmag0to2   =  MPmeanshearmag0to2fullmcs_ALLYRS ;
MP_meanshearmag0to6   =  MPmeanshearmag0to6fullmcs_ALLYRS;
MP_meanshearmag2to9   =  MPmeanshearmag2to9fullmcs_ALLYRS; 
MP_minOMEGA600        =  MPminOMEGA600fullmcs_ALLYRS;
MP_minOMEGAsub600     =  MPminOMEGAsub600fullmcs_ALLYRS ; 
MP_minDIV750          =  MPminDIV750fullmcs_ALLYRS;
MP_minDIVsub600       =  MPminDIVsub600fullmcs_ALLYRS;
MP_meanWNDSPD600      =  MPmeanWNDSPD600fullmcs_ALLYRS;
MP_meanWNDDIR600      =  MPmeanWNDDIR600fullmcs_ALLYRS ;



ALL_vars = {'MCS_maxarea' ;
    'MCS_areagrowthrate'  ;
    'MCS_meanspeed' ;
    'MCS_totalrainmass' ;
    'MCS_HvyRainAccum'  ;
    'MCS_EchoTop50dBZ'  ;
    'MCS_EchoTop30dBZ'  ;
    'MCS_ConvectRainRate' ;
    'MCS_ConvectRainArea' ;
    'MCS_ConvectRainMass' ;
    'MCS_StratiformRainRate' ;
    'MCS_StratiformRainArea' ;
    'MCS_StratiformRainMass' ;
    'MP_vorticity';
    'MP_speed';
    'MP_area';
    'MP_preMCSduration';
    'MP_collocperiod'
    'MP_maxMUCAPE';
    'MP_minMUCIN';
    'MP_meanMULFC';
    'MP_meanMUEL';
    'MP_meanPW';
    'MP_meanshearmag0to2';
    'MP_meanshearmag0to6';
    'MP_meanshearmag2to9';
    'MP_meanWNDSPD600';
    %'MP_meanWNDDIR600'
    'MP_minOMEGAsub600';
    'MP_minDIVsub600';};

ALL_vars = flipdim(ALL_vars,1) ;

ALL_corrs = zeros(length(ALL_vars),length(ALL_vars));     ALL_corrs(:) = NaN;
ALL_Ps = zeros(length(ALL_vars),length(ALL_vars));        ALL_Ps(:) = NaN;
ALL_statsig = zeros(length(ALL_vars),length(ALL_vars));        ALL_statsig(:) = NaN;
SIGTHRESH = 0.05;
for n = 1:length(ALL_vars)
    for m = 1:length(ALL_vars)
        %  n = 1; m = 3
        AA = char(ALL_vars(n)) ; 
        AA = eval(AA);
        BB = char(ALL_vars(m)) ;  
        BB = eval(BB);
        kill = isnan(BB);
        BB(kill) = []; AA(kill) = [];
        kill = isnan(AA);
        BB(kill) = []; AA(kill) = [];
        [corab, pval] = corrcoef(AA(:),BB(:)); corab = corab(2); pval = pval(2);
        ALL_corrs(n,m) = corab ;
        ALL_Ps(n,m) = pval;
        if(pval < SIGTHRESH)
            ALL_statsig(n,m) = NaN;
        else
            ALL_corrs(n,m) = NaN;
            ALL_statsig(n,m) = 0; %0;    
        end
    end
end
ALL_corrs = single(ALL_corrs);
isupper = logical(triu(ones(size(ALL_corrs)),1));
ALL_corrs(isupper) = NaN;
ALL_corrs(ALL_corrs >= 0.99999999999999999999999) = NaN;

ALL_statsig = single(ALL_statsig);
isupper = logical(triu(ones(size(ALL_statsig)),1));
ALL_statsig(isupper) = NaN;
ALL_statsig(ALL_statsig >= 0.99999999999999999999999) = NaN;

varlab = {};
for l = 1:length(ALL_vars)
   asd = char(ALL_vars(l,:) )   ;
   asd(find(asd=='_'))=' '   ;
   varlab = vertcat(varlab,asd);
end

%round 
ALL_corrs = round(ALL_corrs,2);

dualpol_colmap
ff = figure('Position',[246,77,1187,900])
h = heatmap(ALL_corrs,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
h.NodeChildren(3).YDir='normal';
colormap(flipud(pepsi2))
caxis([-1 1])
h.XDisplayLabels = varlab;
h.YDisplayLabels = varlab;
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';
title(['Correlogram - MCS lifetime stats, mean MP stats during MCS collocation',keptmonslab])

%saveas(h, horzcat(imout,'/Correlgram_MPcollocMCS.png') );
outlab = horzcat(imout,'/Correlgram_MPcollocMCS','_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);


% ff = figure('Position',[246,77,1187,900])
% h = heatmap(ALL_statsig,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
% h.NodeChildren(3).YDir='normal';
% colormap(flipud(pepsi2))
% caxis([-1 1])
% h.XDisplayLabels = varlab;
% h.YDisplayLabels = varlab;
% ax = gca;
% axp = struct(ax);       %you will get a warning
% axp.Axes.XAxisLocation = 'top';
% title('Correlogram - MCS lifetime stats, mean MP stats during MCS collocation')
% 
% saveas(h, horzcat(imout,'/Correlgram_MPcollocMCS_SIGMAP.png') );
% outlab = horzcat(imout,'/Correlgram_MPcollocMCS_SIGMAP.eps');
% EPSprint = horzcat('print -painters -depsc ',outlab);
% eval([EPSprint]);
% 




%{


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%
%%%                         Now repeat but with PW +  DAYTIME filters applied
%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%recalculate the MPs' pre MCSI duration to apply filters in MPstats space. 
filtPW_MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filtPW_MPPREDURatMCSI_ALLYRS(:) = NaN;  
filtPWDAYTIME_MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;    filtPWDAYTIME_MPPREDURatMCSI_ALLYRS(:) = NaN;  
for y = 1 : mcs_years % which is same as num years of MP objects 
    for n = 1 : mcs_tracks
        %  y = 6; n = 82;
        mpobjs = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ;      % MP object(s) number (or lack thereof) for this MCSI event
        for u = 1:length(mpobjs)   %note, there could be more than one syn obj present at MCSI because of calling MCSI period as t = 1-2 of MCS
            if(  isempty( mpobjs(u) ) == 0  & isnan( mpobjs(u) ) == 0  &  mpobjs(u) > 0 )  
                %now log MPI and MCSI times for each MP-MCS
                mcsItime = basetime_MCSstats_ALLYRS(1:5, n, y) ;   % Mcs obj initiation time for this MCS - considering first few because of annoying sometime nans at first few MCS times(s)
 
                %apply filtering masks here:
                if(  isnan(maskPW_MPstats_ALLYRS(1, mpobjs(u)  , y))==0   )
                    mpItime = basetime_MPstats_ALLYRS(1, mpobjs(u)  , y) ;       %MP obj initiation time for this MCS
                    mpI_vs_mcsI_dt = vertcat( mpI_vs_mcsI_dt , (mcsItime(1) - mpItime)/3600  ) ;  % [HOURS]   %you could alter this loop to make this variable in the format of MCSstats arrays if you want to.
                    filtPW_MPPREDURatMCSI_ALLYRS(n,y) = (mcsItime(1) - mpItime)/3600 ;  % logging it in MCS (tracks, year) space
                end

                %apply filtering masks here:
                if(  isnan(maskPW_MPstats_ALLYRS(1,mpobjs(u),y))==0    &   isnan( maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(1,mpobjs(u),y) ) == 0 )
                    mpItime = basetime_MPstats_ALLYRS(1, mpobjs(u)  , y) ;       %MP obj initiation time for this MCS
                    mpI_vs_mcsI_dt = vertcat( mpI_vs_mcsI_dt , (mcsItime(1) - mpItime)/3600  ) ;  % [HOURS]   %you could alter this loop to make this variable in the format of MCSstats arrays if you want to.
                    filtPWDAYTIME_MPPREDURatMCSI_ALLYRS(n,y) = (mcsItime(1) - mpItime)/3600 ;  % logging it in MCS (tracks, year) space
                end

            end
        end
    end
end

%  datetime( basetime_MPstats_ALLYRS(1,mpobjs(u),y), 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') 
%  length( find( isnan(filtPWDAYTIME_MPPREDURatMCSI_ALLYRS)==0 ) )
%  length( find( isnan(filtPW_MPPREDURatMCSI_ALLYRS)==0 ) )
%  length( find( isnan(MPPREDURatMCSI_ALLYRS)==0 ) )

%%%% repeated from above to (re)fix for whatever reason it breaks:
totalrainmass_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    totalrainmass_MCSstats_ALLYRSb(:) = NaN;  
rainmass  =  totalrain_MCSstats_ALLYRS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        %for t = 1:mtimes
            totalrainmass_MCSstats_ALLYRSb(n,y)  =  sum (   rainmass(:,n,y) , 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
        %end
    end
end
totalrainmass_MCSstats_ALLYRSb(totalrainmass_MCSstats_ALLYRSb==0) = NaN;

%recalc speed (though not sure I'm crazy about matlabs motionx,y results?
MP_speeds_ALLYRS = (  MotionX_MPstats_ALLYRS.*MotionX_MPstats_ALLYRS +   MotionY_MPstats_ALLYRS.*MotionY_MPstats_ALLYRS ).^0.5   ;


%%%% For MCSs with a MP obj present at MCSI: 

filt_MPVORTatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;       	filt_MPVORTatMCSI_ALLYRS(:) = NaN ;         % magnitude of the vorticity at time of MCSI
%   MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;                                              % duration of vorticity track prior to time of MCSI   % already defined above
filt_MPAREAatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;      	filt_MPAREAatMCSI_ALLYRS(:) = NaN ;         % area of vorticity at time of MCSI
filt_MPCOLLOCMCS_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPCOLLOCMCS_ALLYRS(:) = NaN ;    % Number of time steps post-mcsi with a syn obj present 
filt_MPSPEEDatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;       filt_MPSPEEDatMCSI_ALLYRS(:) = NaN ;    % MP obj speed at time of MCSI

filt_MPmeanMUCAPEatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filt_MPmeanMUCAPEatMCSI_ALLYRS(:) = NaN ;
filt_MPmaxMUCAPEatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmaxMUCAPEatMCSI_ALLYRS(:) = NaN ;
filt_MPmeanMUCINatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanMUCINatMCSI_ALLYRS(:) = NaN ;
filt_MPminMUCINatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPminMUCINatMCSI_ALLYRS(:) = NaN ;
filt_MPmeanMULFCatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanMULFCatMCSI_ALLYRS(:) = NaN ;
filt_MPmeanMUELatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPmeanMUELatMCSI_ALLYRS(:) = NaN ;
filt_MPmeanPWatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;               filt_MPmeanPWatMCSI_ALLYRS(:) = NaN ;
filt_MPmaxPWatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;                filt_MPmaxPWatMCSI_ALLYRS(:) = NaN ;
filt_MPminPWatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;                filt_MPminPWatMCSI_ALLYRS(:) = NaN ;
filt_MPmeanshearmag0to2atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag0to2atMCSI_ALLYRS(:) = NaN ;
filt_MPmaxshearmag0to2atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag0to2atMCSI_ALLYRS(:) = NaN ;
filt_MPmeanshearmag0to6atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag0to6atMCSI_ALLYRS(:) = NaN ;
filt_MPmaxshearmag0to6atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag0to6atMCSI_ALLYRS(:) = NaN ;
filt_MPmeanshearmag2to9atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag2to9atMCSI_ALLYRS(:) = NaN ;
filt_MPmaxshearmag2to9atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag2to9atMCSI_ALLYRS(:) = NaN ;
filt_MPmeanOMEGA600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPmeanOMEGA600atMCSI_ALLYRS(:) = NaN ;
filt_MPminOMEGA600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;          filt_MPminOMEGA600atMCSI_ALLYRS(:) = NaN ;
filt_MPminOMEGAsub600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;       filt_MPminOMEGAsub600atMCSI_ALLYRS(:) = NaN ; 
filt_MPmeanVIWVDatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanVIWVDatMCSI_ALLYRS(:) = NaN ;
filt_MPminVIWVDatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPminVIWVDatMCSI_ALLYRS(:) = NaN ;
filt_MPmaxVIWVDatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPmaxVIWVDatMCSI_ALLYRS(:) = NaN ;
filt_MPmeanDIV750atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filt_MPmeanDIV750atMCSI_ALLYRS(:) = NaN ;
filt_MPminDIV750atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPminDIV750atMCSI_ALLYRS(:) = NaN ;
filt_MPminDIVsub600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPminDIVsub600atMCSI_ALLYRS(:) = NaN ;
filt_MPmeanWNDSPD600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPmeanWNDSPD600atMCSI_ALLYRS(:) = NaN ;
filt_MPmeanWNDDIR600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPmeanWNDDIR600atMCSI_ALLYRS(:) = NaN ;

%%% catalog these MP obj traits in MCS(tracks,years) space:
for y = 1:mcs_years
    for n = 1:mcs_tracks
        
        tmp = length(  find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  )  ;  %num of time in MCS with an MP
        MPCOLLOCMCS_ALLYRS(n,y) = tmp  ;  % NOTE: this includes all syn objs, not only the one(s) presnt during mcsi period
        
        % syn obj characteristics for syn present @ MCSI events:
        if(    isnan( MCSI_with_MP_ALLYRS(n,y) ) == 0    )
            
            %time of MCSI (defined well above)
            MCSItime = mcsibasetime_perMCS_ALLYRS(1:2,n,y) ;
            %the syn object present at MCSI
            mpobj = MCSI_with_MP_ALLYRS(n,y) ;
            
            if( isnan(mpobj)==0 )

                    %    basetime_MPstats_met_yymmddhhmmss_ALLYRS(:,mpobj,y)

                    %to account for mp obj present at second time in MCSI period but not first (since we are letting MCSI period be t = 1:2:
                    MPt1 = find( floor(basetime_MPstats_ALLYRS(:,mpobj,y)/100)  ==  floor(MCSItime(1)/100) )  ;
                    MPt2 = find( floor(basetime_MPstats_ALLYRS(:,mpobj,y)/100)  ==  floor(MCSItime(2)/100) )  ;
                    % time in syn obj's record when MCSI happens:
                    MPt = vertcat(MPt1,MPt2) ;  MPt = MPt(1);
                    
                    %populate the syn obj metrics of interest:
                    filt_MPVORTatMCSI_ALLYRS(n,y) = maxVOR600_MPstats_ALLYRS(MPt,mpobj,y)  .* MPdurMASK_forMPs(MPt,mpobj,y);
                    filt_MPAREAatMCSI_ALLYRS(n,y) = area_MPstats_ALLYRS(MPt,mpobj,y)  .* MPdurMASK_forMPs(MPt,mpobj,y);
                    % MPPREDURatMCSI_ALLYRS -  already cataloged above
                    %tmp = length(  find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  )  ;
                    %MPCOLLOCMCS_ALLYRS(n,y) = tmp  ;  % NOTE: this includes all syn objs, not only the one(s) presnt during mcsi period
                    filt_MPSPEEDatMCSI_ALLYRS(n,y) =  ( ( MotionX_MPstats_ALLYRS(MPt,mpobj,y) .* MotionX_MPstats_ALLYRS(MPt,mpobj,y)  +   MotionY_MPstats_ALLYRS(MPt,mpobj,y).*MotionY_MPstats_ALLYRS(MPt,mpobj,y) ).^0.5 ).* ( MPdurMASK_forMPs(MPt,mpobj,y) )  ;
                   
                    filt_MPmeanMUCAPEatMCSI_ALLYRS(n,y) =           meanMUCAPE_MPstats_ALLYRS(MPt,mpobj,y)       .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y) .*  maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(MPt,mpobj,y) ;   
                    filt_MPmaxMUCAPEatMCSI_ALLYRS(n,y) =            maxMUCAPE_MPstats_ALLYRS(MPt,mpobj,y)        .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y) .*  maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(MPt,mpobj,y) ;    
                    filt_MPmeanMUCINatMCSI_ALLYRS(n,y) =            meanMUCIN_MPstats_ALLYRS(MPt,mpobj,y)        .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y) .*  maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(MPt,mpobj,y) ;    
                    filt_MPminMUCINatMCSI_ALLYRS(n,y) =             minMUCIN_MPstats_ALLYRS(MPt,mpobj,y)         .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y) .*  maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(MPt,mpobj,y) ;    
                    filt_MPmeanMULFCatMCSI_ALLYRS(n,y) =            meanMULFC_MPstats_ALLYRS(MPt,mpobj,y)        .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y) .*  maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(MPt,mpobj,y) ;    
                    filt_MPmeanMUELatMCSI_ALLYRS(n,y) =             meanMUEL_MPstats_ALLYRS(MPt,mpobj,y)         .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y) .*  maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(MPt,mpobj,y) ;  
                    filt_MPmeanPWatMCSI_ALLYRS(n,y) =               meanPW_MPstats_ALLYRS(MPt,mpobj,y)           .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y); 
                    filt_MPmaxPWatMCSI_ALLYRS(n,y) =                maxPW_MPstats_ALLYRS(MPt,mpobj,y)            .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);  
                    filt_MPminPWatMCSI_ALLYRS(n,y) =                minPW_MPstats_ALLYRS(MPt,mpobj,y)            .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);  
                    filt_MPmeanshearmag0to2atMCSI_ALLYRS(n,y) =     meanshearmag0to2_MPstats_ALLYRS(MPt,mpobj,y) .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);  
                    filt_MPmaxshearmag0to2atMCSI_ALLYRS(n,y) =      maxshearmag0to2_MPstats_ALLYRS(MPt,mpobj,y)  .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmeanshearmag0to6atMCSI_ALLYRS(n,y) =     meanshearmag0to6_MPstats_ALLYRS(MPt,mpobj,y) .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmaxshearmag0to6atMCSI_ALLYRS(n,y) =      maxshearmag0to6_MPstats_ALLYRS(MPt,mpobj,y)  .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmeanshearmag2to9atMCSI_ALLYRS(n,y) =     meanshearmag2to9_MPstats_ALLYRS(MPt,mpobj,y) .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmaxshearmag2to9atMCSI_ALLYRS(n,y) =      maxshearmag2to9_MPstats_ALLYRS(MPt,mpobj,y)  .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);  
                    filt_MPmeanOMEGA600atMCSI_ALLYRS(n,y) =         meanOMEGA600_MPstats_ALLYRS(MPt,mpobj,y)     .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPminOMEGA600atMCSI_ALLYRS(n,y) =          minOMEGA600_MPstats_ALLYRS(MPt,mpobj,y)      .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPminOMEGAsub600atMCSI_ALLYRS(n,y) =       minOMEGAsub600_MPstats_ALLYRS(MPt,mpobj,y)   .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmeanVIWVDatMCSI_ALLYRS(n,y) =            meanVIWVD_MPstats_ALLYRS(MPt,mpobj,y)        .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPminVIWVDatMCSI_ALLYRS(n,y) =             minVIWVD_MPstats_ALLYRS(MPt,mpobj,y)         .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmaxVIWVDatMCSI_ALLYRS(n,y) =             maxVIWVD_MPstats_ALLYRS(MPt,mpobj,y)         .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);    
                    filt_MPmeanDIV750atMCSI_ALLYRS(n,y) =           meanDIV750_MPstats_ALLYRS(MPt,mpobj,y)       .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPminDIV750atMCSI_ALLYRS(n,y) =            minDIV750_MPstats_ALLYRS(MPt,mpobj,y)        .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPminDIVsub600atMCSI_ALLYRS(n,y) =         minDIVsub600_MPstats_ALLYRS(MPt,mpobj,y)     .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmeanWNDSPD600atMCSI_ALLYRS(n,y) =        meanWNDSPD600_MPstats_ALLYRS(MPt,mpobj,y)    .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);    
                    filt_MPmeanWNDDIR600atMCSI_ALLYRS(n,y) =        meanWNDDIR600_MPstats_ALLYRS(MPt,mpobj,y)    .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
            end
            
        end 
    end
end
MPCOLLOCMCS_ALLYRS(MPCOLLOCMCS_ALLYRS==0) = NaN;






%%%%%%%%%
%%%  for events with MPs present at MCSI

%%%% MCS lifetime metrics
MCS_maxarea             =  maxareapf_MCSstats_ALLYRS .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_areagrowthrate      =  dAdt_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_meanspeed           =  MCSspeed_MCSstats_ALLYRS .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_totalrainmass       =  totalrainmass_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_HvyRainAccum        =  pf_accumrainheavy_MCSstats_ALLYRSb  .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_EchoTop50dBZ        =  pf_ETH50_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_EchoTop30dBZ        =  pf_ETH30_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_ConvectRainRate     =  convrainrate_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_ConvectRainArea     =  convrainarea_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_ConvectRainMass     =  convrainmass_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_StratiformRainRate  =  stratrainrate_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_StratiformRainArea  =  stratrainarea_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_StratiformRainMass  =  stratrainmass_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;

%%%% MP metric at MCSI
MP_vorticity            =  filt_MPVORTatMCSI_ALLYRS;
MP_speed                =  filt_MPSPEEDatMCSI_ALLYRS;
MP_area                 =  filt_MPAREAatMCSI_ALLYRS;
MPpwfilt_preMCSduration =  filtPW_MPPREDURatMCSI_ALLYRS;
MPpwdaytimefilt_preMCSduration       =  filtPWDAYTIME_MPPREDURatMCSI_ALLYRS;
%%%% MP env metric at MCSI
MP_maxMUCAPE            =  filt_MPmaxMUCAPEatMCSI_ALLYRS;
MP_minMUCIN             =  filt_MPminMUCINatMCSI_ALLYRS;
MP_meanMULFC            =  filt_MPmeanMULFCatMCSI_ALLYRS;
MP_meanMUEL             =  filt_MPmeanMUELatMCSI_ALLYRS;
MP_meanPW               =  filt_MPmeanPWatMCSI_ALLYRS;
MP_meanshearmag0to2     =  filt_MPmeanshearmag0to2atMCSI_ALLYRS;
MP_meanshearmag0to6     =  filt_MPmeanshearmag0to6atMCSI_ALLYRS;
MP_meanshearmag2to9     =  filt_MPmeanshearmag2to9atMCSI_ALLYRS;
MP_minOMEGAsub600       =  filt_MPminOMEGAsub600atMCSI_ALLYRS;
MP_minDIVsub600         =  filt_MPminDIVsub600atMCSI_ALLYRS;
MP_meanWNDSPD600        =  filt_MPmeanWNDSPD600atMCSI_ALLYRS;

ALL_vars = {'MCS_maxarea' ;
    'MCS_areagrowthrate'  ;
    'MCS_meanspeed' ;
    'MCS_totalrainmass' ;
    'MCS_HvyRainAccum'  ;
    'MCS_EchoTop50dBZ'  ;
    'MCS_EchoTop30dBZ'  ;
    'MCS_ConvectRainRate' ;
    'MCS_ConvectRainArea' ;
    'MCS_ConvectRainMass' ;
    'MCS_StratiformRainRate' ;
    'MCS_StratiformRainArea' ;
    'MCS_StratiformRainMass' ;
    'MP_vorticity';
    'MP_speed';
    'MP_area';
    'MPpwfilt_preMCSduration';
    'MPpwdaytimefilt_preMCSduration';
    'MP_maxMUCAPE';
    'MP_minMUCIN';
    'MP_meanMULFC';
    'MP_meanMUEL';
    'MP_meanPW';
    'MP_meanshearmag0to2';
    'MP_meanshearmag0to6';
    'MP_meanshearmag2to9';
    'MP_minOMEGAsub600';
    'MP_minDIVsub600';
    'MP_meanWNDSPD600';
    'MP_meanWNDDIR600'};

ALL_vars = flipdim(ALL_vars,1) ;

ALL_corrs = zeros(length(ALL_vars),length(ALL_vars));     ALL_corrs(:) = NaN;
ALL_Ps = zeros(length(ALL_vars),length(ALL_vars));        ALL_Ps(:) = NaN;
ALL_statsig = zeros(length(ALL_vars),length(ALL_vars));        ALL_statsig(:) = NaN;
SIGTHRESH = 0.05;
for n = 1:length(ALL_vars)
    for m = 1:length(ALL_vars)
        %  n = 1; m = 3
        AA = char(ALL_vars(n)) ; 
        AA = eval(AA);
        BB = char(ALL_vars(m)) ;  
        BB = eval(BB);
        kill = isnan(BB);
        BB(kill) = []; AA(kill) = [];
        kill = isnan(AA);
        BB(kill) = []; AA(kill) = [];
        [corab, pval] = corrcoef(AA(:),BB(:)); corab = corab(2); pval = pval(2);
        ALL_corrs(n,m) = corab ;
        ALL_Ps(n,m) = pval;
        if(pval < SIGTHRESH)
            ALL_statsig(n,m) = NaN;
        else
            ALL_statsig(n,m) = 0; %0;    
        end
    end
end
ALL_corrs = single(ALL_corrs);
isupper = logical(triu(ones(size(ALL_corrs)),1));
ALL_corrs(isupper) = NaN;
ALL_corrs(ALL_corrs >= 0.99999999999999999999999) = NaN;

ALL_statsig = single(ALL_statsig);
isupper = logical(triu(ones(size(ALL_statsig)),1));
ALL_statsig(isupper) = NaN;
ALL_statsig(ALL_statsig >= 0.99999999999999999999999) = NaN;

varlab = {};
for l = 1:length(ALL_vars)
   asd = char(ALL_vars(l,:) )   ;
   asd(find(asd=='_'))=' '   ;
   varlab = vertcat(varlab,asd);
end

dualpol_colmap
ff = figure('Position',[246,77,1187,900])
h = heatmap(ALL_corrs,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
h.NodeChildren(3).YDir='normal';
colormap(flipud(pepsi2))
caxis([-1 1])
h.XDisplayLabels = varlab;
h.YDisplayLabels = varlab;
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';
title('Correlogram - MCS lifetime stats, MP stats at MCSI(-3hr) (filters out LS, filters out preMCSIdur<3hrs, daytime thermo only, filters out PW < 24mm)' ) 

saveas(h, horzcat(imout,'/Correlgram_MPatMCSI_PWDAYfilt.png') );
outlab = horzcat(imout,'/Correlgram_MPatMCSI_PWDAYfilt.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);

ff = figure('Position',[246,77,1187,900])
h = heatmap(ALL_statsig,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
h.NodeChildren(3).YDir='normal';
colormap(flipud(pepsi2))
caxis([-1 1])
h.XDisplayLabels = varlab;
h.YDisplayLabels = varlab;
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';
title('Correlogram - MCS lifetime stats, mean MP stats at MCSI(-3hr) (filters out LS, filters out preMCSIdur<3hrs, daytime thermo only, filters out PW < 24mm)')

saveas(h, horzcat(imout,'/Correlgram_MPatMCSI_SIGMAP_PWDAYfilt.png') );
outlab = horzcat(imout,'/Correlgram_MPatMCSI_SIGMAP_PWDAYfilt.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);












%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%   Now calc the 2D histograms of MP obj properties throughout MCS
%%%   lifetime (while they are collocated) rather than just the MP obj 
%%%   properties @ time of MCSI - filtered versions

%%%% For MCSs with a SYN obj present at any time throughout its life: 

%notes (May 13 2024): The MPstats metrics (that are converted to [mcsnum,year] space below)
%                     are now hit with the PW & DAYTIME masks made above.
%                     The MCS metrics themselves are NOT filtered becasue
%                     that is more complicated than my ADHD brain can
%                     handle right now. however, when you're looking at the MP-MCS relationships, 
%                     the MP-filtered fields will take care of this. So
%                     MCS-MCS relationships dont have this filter, but I
%                     think that's ok because I am not really looking at
%                     these (and they may not need to be filtered anyway?)

filt_MPVORTfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPVORTfullmcs_ALLYRS(:) = NaN ;         % magnitude of the max vorticity while syn obj touching mcs
filt_MPAREAfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      	 filt_MPAREAfullmcs_ALLYRS(:) = NaN ;         % area of vorticity while syn obj touching mcs
filt_MPSPEEDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;       filt_MPSPEEDfullmcs_ALLYRS(:) = NaN ;        % Syn obj speed while syn obj touching mcs
filt_MPcollocdurfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;   filt_MPcollocdurfullmcs_ALLYRS(:) = NaN ;       % collocation period of MCS-MP (if multiple MCSs per MP, use the longest collocation per MP?)
% MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     % duration of vorticity track prior to time of MCSI   % already defined above
% MPCOLLOCMCS_ALLYRS = zeros(mcs_tracks,mcs_years) ;    % Number of time steps post-mcsi with a syn obj present - already defined above

filt_MPmeanMUCAPEfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filt_MPmeanMUCAPEfullmcs_ALLYRS(:) = NaN ;
filt_MPmaxMUCAPEfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmaxMUCAPEfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanMUCINfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanMUCINfullmcs_ALLYRS(:) = NaN ;
filt_MPminMUCINfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPminMUCINfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanMULFCfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanMULFCfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanMUELfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPmeanMUELfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;               filt_MPmeanPWfullmcs_ALLYRS(:) = NaN ;
filt_MPmaxPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;                filt_MPmaxPWfullmcs_ALLYRS(:) = NaN ;
filt_MPminPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;                filt_MPminPWfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanshearmag0to2fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag0to2fullmcs_ALLYRS(:) = NaN ;
filt_MPmaxshearmag0to2fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag0to2fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanshearmag0to6fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag0to6fullmcs_ALLYRS(:) = NaN ;
filt_MPmaxshearmag0to6fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag0to6fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanshearmag2to9fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag2to9fullmcs_ALLYRS(:) = NaN ;
filt_MPmaxshearmag2to9fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag2to9fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanOMEGA600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPmeanOMEGA600fullmcs_ALLYRS(:) = NaN ;
filt_MPminOMEGA600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;          filt_MPminOMEGA600fullmcs_ALLYRS(:) = NaN ;
filt_MPminOMEGAsub600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;       filt_MPminOMEGAsub600fullmcs_ALLYRS(:) = NaN ; 
filt_MPmeanVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanVIWVDfullmcs_ALLYRS(:) = NaN ;
filt_MPminVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPminVIWVDfullmcs_ALLYRS(:) = NaN ;
filt_MPmaxVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPmaxVIWVDfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanDIV750fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filt_MPmeanDIV750fullmcs_ALLYRS(:) = NaN ;
filt_MPminDIV750fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPminDIV750fullmcs_ALLYRS(:) = NaN ;
filt_MPminDIVsub600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPminDIVsub600fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanWNDSPD600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPmeanWNDSPD600fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanWNDDIR600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPmeanWNDDIR600fullmcs_ALLYRS(:) = NaN ;


%%% catalog these syn obj traits in MCS(tracks,years) space:
for y = 1:mcs_years
    for n = 1:mcs_tracks

        %   n = 79;  y = 2;  
        
        %t-indices in each MCS track where there is a syn present
        mpspresent = find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  ;
        
        if( isempty(mpspresent) == 0)

            %empty vars to hold mean/max metrics for each syn object that
            %you will later mean/max again to relate to MCSs:
            mps_vorts = [] ;
            mps_areas = [] ;
            mps_speeds = [] ;
            mps_colloc = [];
            meanMUCAPE = [] ;
            maxMUCAPE = [] ;
            meanMUCIN = [] ;
            minMUCIN = [] ;
            meanMULFC = [] ;
            meanMUEL = [] ;
            meanPW = [] ;
            maxPW = [] ;
            minPW = [] ;
            meanshearmag0to2 = [] ;
            maxshearmag0to2 = [] ;
            meanshearmag0to6 = [] ;
            maxshearmag0to6 = [] ;
            meanshearmag2to9 = [] ;
            maxshearmag2to9 = [] ;
            meanOMEGA600 = [] ;
            minOMEGA600 = [] ;
            minOMEGAsub600 = [] ;
            meanVIWVD = [] ;
            minVIWVD = [] ;
            maxVIWVD = [] ;
            meanDIV750 = [] ;
            minDIV750 = [] ;
            minDIVsub600 = [] ;
            meanWNDSPD600 = [] ;
            meanWNDDIR600 = [] ;
            collocdur = [];

            % diagnostic example:     y = 6; n = 80;
            % locate time and mp numbers corresponding to this MCS by referecing a masked/filtered PW/daytime MPstats list:
            found = find( filtPWDAYTIME_MCStracks_MPstats_ALLYRS(:,:,:,y) == n )  ;
            [tind_f,  mcsind_f,  mpind_f] = ind2sub(size(filtPWDAYTIME_MCStracks_MPstats_ALLYRS(:,:,:,y)),found) ;     clear found
            unimps = unique(mpind_f) ;
            colls = [];
            for mm = 1:length(unimps)
                colls = vertcat(colls,length(find(mpind_f==unimps(mm))));
            end
            %going to call the final MCS's MP collocation the mean of all of the MP collocations. Or does it make sense to do max? sum?  
            collocdur = vertcat(collocdur, mean(colls) );
            
            %all of the unique syn tracks in this MCS's full track:
            mpnums = unique(MPtracks_perMCS_ALLYRS(mpspresent,n,y)) ;
            
            %loop thru all of the syn objs overlapping the current MCS
            for s = 1:length(mpnums)
                
                %find MCS's time indices when current syn object is present, then
                %log the first & last time
                mp_mcst = find( MPtracks_perMCS_ALLYRS(:,n,y) == mpnums(s) )  ;
                mcst1 = basetime_MCSstats_ALLYRS(mp_mcst(1),n,y) ;
                mcst2 = basetime_MCSstats_ALLYRS(mp_mcst(end),n,y) ;
                
                %find the time indices in current syn obj's track corersponding to
                %the MCS overlap period:
                MPti1 = find( floor(mcst1/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;
                MPti2 = find( floor(mcst2/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;    

                % log the max/mean of the current syn obj's
                % characteristics during its overlap period with the MCS.
                % throw it into an array that contains the same for all
                % other syn obj's touching the current MCS:
                mps_vorts =  vertcat(mps_vorts, max( maxVOR600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;      %max vort of syn obj during its contact with MCS
                mps_areas =  vertcat(mps_areas, max( area_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )   ) ;          %max area of syn obj during its contact with MCS  
                mps_speeds = vertcat(mps_speeds, mean( MP_speeds_ALLYRS(MPti1:MPti2,mpnums(s),y) , 'omitnan')) ;  %mean speed of syn obj during its contact with MCS  
                
%                 %calced this seperately above already
%                 mps_colloc =  vercat(mps_colloc,    max(    MPMCS_collocDur_MPstats(:,mpnums(s),y) )          );
%                 blah = meanMUCAPE_MPstats_ALLYRS(:,mpnums(s),y) .* maskPW_MPstats_ALLYRS(:,mpobj,y) .*  maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(:,mpobj,y);
%                 meanMUCAPE          = vertcat( meanMUCAPE,       max(  blah(MPti1:MPti2)       , [] ,'omitnan' )  ) ;

                maxMUCAPE           = vertcat( maxMUCAPE,        max(  maxMUCAPE_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .*  maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanMUCIN           = vertcat( meanMUCIN,        min(  meanMUCIN_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .*  maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minMUCIN            = vertcat( minMUCIN,         min(  minMUCIN_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .*  maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanMULFC           = vertcat( meanMULFC,        min(  meanMULFC_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .*  maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanMUEL            = vertcat( meanMUEL,         max(  meanMUEL_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .*  maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanPW              = vertcat( meanPW,           max(  meanPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)           .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxPW               = vertcat( maxPW,            max(  maxPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)            .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minPW               = vertcat( minPW,            min(  minPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)            .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanshearmag0to2    = vertcat( meanshearmag0to2, max(  meanshearmag0to2_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxshearmag0to2     = vertcat( maxshearmag0to2,  max(  maxshearmag0to2_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)  .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanshearmag0to6    = vertcat( meanshearmag0to6, max(  meanshearmag0to6_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxshearmag0to6     = vertcat( maxshearmag0to6,  max(  maxshearmag0to6_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)  .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanshearmag2to9    = vertcat( meanshearmag2to9, max(  meanshearmag2to9_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxshearmag2to9     = vertcat( maxshearmag2to9,  max(  maxshearmag2to9_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)  .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanOMEGA600        = vertcat( meanOMEGA600,     min(  meanOMEGA600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)     .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minOMEGA600         = vertcat( minOMEGA600,      min(  minOMEGA600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)      .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minOMEGAsub600      = vertcat( minOMEGAsub600,   min(  minOMEGAsub600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)   .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanVIWVD           = vertcat( meanVIWVD,        max(  meanVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minVIWVD            = vertcat( minVIWVD,         min(  minVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxVIWVD            = vertcat( maxVIWVD,         max(  maxVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanDIV750          = vertcat( meanDIV750,       min(  meanDIV750_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)       .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minDIV750           = vertcat( minDIV750,        min(  minDIV750_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minDIVsub600        = vertcat( minDIVsub600,     min(  minDIVsub600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)     .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanWNDSPD600       = vertcat( meanWNDSPD600,    max(  meanWNDSPD600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)    .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanWNDDIR600       = vertcat( meanWNDDIR600,    mean(  meanWNDDIR600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)   .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y),'omitnan' )  ) ;
            end
            
            %  bla1 = maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(:,:,y)   ;
            %  bla2 =  maskPW_MPstats_ALLYRS(:,:,y)   ;
            %  bla3 = maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(:,:,y)  .*  maskPW_MPstats_ALLYRS(:,:,y)   ;


            %end up with the means of all of the mean/max MP objs
            %characteristics across all syn objects touching the current MCS:
            filt_MPVORTfullmcs_ALLYRS(n,y)       =  mean( mps_vorts , 'omitnan');       
            filt_MPAREAfullmcs_ALLYRS(n,y)       =  mean( mps_areas , 'omitnan');
            filt_MPSPEEDfullmcs_ALLYRS(n,y)      =  mean( mps_speeds , 'omitnan');
            filt_MPcollocdurfullmcs_ALLYRS(n,y)  =  mean( collocdur , 'omitnan');

            filt_MPmeanMUCAPEfullmcs_ALLYRS(n,y)         =  mean( meanMUCAPE , 'omitnan'); 
            filt_MPmaxMUCAPEfullmcs_ALLYRS(n,y)          =  mean( maxMUCAPE , 'omitnan'); 
            filt_MPmeanMUCINfullmcs_ALLYRS(n,y)          =  mean( meanMUCIN , 'omitnan'); 
            filt_MPminMUCINfullmcs_ALLYRS(n,y)           =  mean( minMUCIN , 'omitnan'); 
            filt_MPmeanMULFCfullmcs_ALLYRS(n,y)          =  mean( meanMULFC , 'omitnan'); 
            filt_MPmeanMUELfullmcs_ALLYRS(n,y)           =  mean( meanMUEL , 'omitnan'); 
            filt_MPmeanPWfullmcs_ALLYRS(n,y)             =  mean( meanPW , 'omitnan'); 
            filt_MPmaxPWfullmcs_ALLYRS(n,y)              =  mean( maxPW , 'omitnan'); 
            filt_MPminPWfullmcs_ALLYRS(n,y)              =  mean( minPW , 'omitnan'); 
            filt_MPmeanshearmag0to2fullmcs_ALLYRS(n,y)   =  mean( meanshearmag0to2 , 'omitnan'); 
            filt_MPmaxshearmag0to2fullmcs_ALLYRS(n,y)    =  mean( maxshearmag0to2 , 'omitnan'); 
            filt_MPmeanshearmag0to6fullmcs_ALLYRS(n,y)   =  mean( meanshearmag0to6 , 'omitnan'); 
            filt_MPmaxshearmag0to6fullmcs_ALLYRS(n,y)    =  mean( maxshearmag0to6 , 'omitnan'); 
            filt_MPmeanshearmag2to9fullmcs_ALLYRS(n,y)   =  mean( meanshearmag2to9 , 'omitnan'); 
            filt_MPmaxshearmag2to9fullmcs_ALLYRS(n,y)    =  mean( maxshearmag2to9 , 'omitnan'); 
            filt_MPmeanOMEGA600fullmcs_ALLYRS(n,y)       =  mean( meanOMEGA600 , 'omitnan'); 
            filt_MPminOMEGA600fullmcs_ALLYRS(n,y)        =  mean( minOMEGA600 , 'omitnan'); 
            filt_MPminOMEGAsub600fullmcs_ALLYRS(n,y)     =  mean( minOMEGAsub600 , 'omitnan'); 
            filt_MPmeanVIWVDfullmcs_ALLYRS(n,y)          =  mean( meanVIWVD , 'omitnan'); 
            filt_MPminVIWVDfullmcs_ALLYRS(n,y)           =  mean( minVIWVD , 'omitnan'); 
            filt_MPmaxVIWVDfullmcs_ALLYRS(n,y)           =  mean( maxVIWVD , 'omitnan'); 
            filt_MPmeanDIV750fullmcs_ALLYRS(n,y)         =  mean( meanDIV750 , 'omitnan'); 
            filt_MPminDIV750fullmcs_ALLYRS(n,y)          =  mean( minDIV750 , 'omitnan'); 
            filt_MPminDIVsub600fullmcs_ALLYRS(n,y)       =  mean( minDIVsub600 , 'omitnan'); 
            filt_MPmeanWNDSPD600fullmcs_ALLYRS(n,y)      =  mean( meanWNDSPD600 , 'omitnan'); 
            filt_MPmeanWNDDIR600fullmcs_ALLYRS(n,y)      =  mean( meanWNDDIR600 , 'omitnan'); 

        end
    end
end          

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  NOW PLOT for events with MPs & MCSs collocated. I believe vars in are in MCSstats
%%%  space ( before they are 1D(:) converted)

%%%% MCS lifetime metrics
MCS_maxarea             = maxareapf_MCSstats_ALLYRS(:) ;
MCS_areagrowthrate      = dAdt_MCSstats_ALLYRSb(:) ;
MCS_meanspeed           = MCSspeed_MCSstats_ALLYRS(:) ;
MCS_totalrainmass       = totalrainmass_MCSstats_ALLYRSb(:) ;
MCS_HvyRainAccum        = pf_accumrainheavy_MCSstats_ALLYRSb(:)  ;
MCS_EchoTop50dBZ        = pf_ETH50_MCSstats_ALLYRSb(:)  ;
MCS_EchoTop30dBZ        = pf_ETH30_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainRate     = convrainrate_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainArea     = convrainarea_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainMass     = convrainmass_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainRate  = stratrainrate_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainArea  = stratrainarea_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainMass  = stratrainmass_MCSstats_ALLYRSb(:)  ;

%%%% mean MP metric while collocated with MCS
MP_vorticity          =  filt_MPVORTfullmcs_ALLYRS(:)   ;
MP_speed              =  filt_MPSPEEDfullmcs_ALLYRS(:)  ;
MP_area               =  filt_MPAREAfullmcs_ALLYRS(:)   ;
%MP_preMCSduration     =  filt_MPPREDURatMCSI_ALLYRS(:)  ;
MP_MCS_collocperiod       =  filt_MPcollocdurfullmcs_ALLYRS(:)  ;
%%%% MP env metric during MCS-MP colloc
MP_maxMUCAPE          =  filt_MPmaxMUCAPEfullmcs_ALLYRS ;
MP_minMUCIN           =  filt_MPminMUCINfullmcs_ALLYRS;
MP_meanMULFC          =  filt_MPmeanMULFCfullmcs_ALLYRS;
MP_meanMUEL           =  filt_MPmeanMUELfullmcs_ALLYRS ; 
MP_meanPW             =  filt_MPmeanPWfullmcs_ALLYRS;
MP_meanshearmag0to2   =  filt_MPmeanshearmag0to2fullmcs_ALLYRS ;
MP_meanshearmag0to6   =  filt_MPmeanshearmag0to6fullmcs_ALLYRS;
MP_meanshearmag2to9   =  filt_MPmeanshearmag2to9fullmcs_ALLYRS; 
MP_minOMEGA600        =  filt_MPminOMEGA600fullmcs_ALLYRS;
MP_minOMEGAsub600     =  filt_MPminOMEGAsub600fullmcs_ALLYRS ; 
MP_minDIV750          =  filt_MPminDIV750fullmcs_ALLYRS;
MP_minDIVsub600       =  filt_MPminDIVsub600fullmcs_ALLYRS;
MP_meanWNDSPD600      =  filt_MPmeanWNDSPD600fullmcs_ALLYRS;
MP_meanWNDDIR600      =  filt_MPmeanWNDDIR600fullmcs_ALLYRS ;

ALL_vars = {'MCS_maxarea' ;
    'MCS_areagrowthrate'  ;
    'MCS_meanspeed' ;
    'MCS_totalrainmass' ;
    'MCS_HvyRainAccum'  ;
    'MCS_EchoTop50dBZ'  ;
    'MCS_EchoTop30dBZ'  ;
    'MCS_ConvectRainRate' ;
    'MCS_ConvectRainArea' ;
    'MCS_ConvectRainMass' ;
    'MCS_StratiformRainRate' ;
    'MCS_StratiformRainArea' ;
    'MCS_StratiformRainMass' ;
    'MP_vorticity';
    'MP_speed';
    'MP_area';
    'MP_MCS_collocperiod'
    'MP_maxMUCAPE';
    'MP_minMUCIN';
    'MP_meanMULFC';
    'MP_meanMUEL';
    'MP_meanPW';
    'MP_meanshearmag0to2';
    'MP_meanshearmag0to6';
    'MP_meanshearmag2to9';
    'MP_minOMEGAsub600';
    'MP_minDIVsub600';
    'MP_meanWNDSPD600';
    'MP_meanWNDDIR600'};

ALL_vars = flipdim(ALL_vars,1) ;

ALL_corrs = zeros(length(ALL_vars),length(ALL_vars));     ALL_corrs(:) = NaN;
ALL_Ps = zeros(length(ALL_vars),length(ALL_vars));        ALL_Ps(:) = NaN;
ALL_statsig = zeros(length(ALL_vars),length(ALL_vars));        ALL_statsig(:) = NaN;
SIGTHRESH = 0.05;
for n = 1:length(ALL_vars)
    for m = 1:length(ALL_vars)
        %  n = 1; m = 3
        AA = char(ALL_vars(n)) ; 
        AA = eval(AA);
        BB = char(ALL_vars(m)) ;  
        BB = eval(BB);
        kill = isnan(BB);
        BB(kill) = []; AA(kill) = [];
        kill = isnan(AA);
        BB(kill) = []; AA(kill) = [];
        [corab, pval] = corrcoef(AA(:),BB(:)); corab = corab(2); pval = pval(2);
        ALL_corrs(n,m) = corab ;
        ALL_Ps(n,m) = pval;
        if(pval < SIGTHRESH)
            ALL_statsig(n,m) = NaN;
        else
            ALL_corrs(n,m) = NaN;
            ALL_statsig(n,m) = 0; %0;    
        end
    end
end
ALL_corrs = single(ALL_corrs);
isupper = logical(triu(ones(size(ALL_corrs)),1));
ALL_corrs(isupper) = NaN;
ALL_corrs(ALL_corrs >= 0.99999999999999999999999) = NaN;

ALL_statsig = single(ALL_statsig);
isupper = logical(triu(ones(size(ALL_statsig)),1));
ALL_statsig(isupper) = NaN;
ALL_statsig(ALL_statsig >= 0.99999999999999999999999) = NaN;

varlab = {};
for l = 1:length(ALL_vars)
   asd = char(ALL_vars(l,:) )   ;
   asd(find(asd=='_'))=' '   ;
   varlab = vertcat(varlab,asd);
end

ALL_corrs = round(ALL_corrs,2);

dualpol_colmap
ff = figure('Position',[246,77,1187,900])
h = heatmap(ALL_corrs,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
h.NodeChildren(3).YDir='normal';
colormap(flipud(pepsi2))
caxis([-1 1])
h.XDisplayLabels = varlab;
h.YDisplayLabels = varlab;
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';
title('Correlogram - MCS lifetime stats, mean MP stats during MCS collocation (filters out LS, daytime thermo only, filters out PW < 24mm)')

saveas(h, horzcat(imout,'/Correlgram_MPcollocMCS_PWDAYfilt.png') );
outlab = horzcat(imout,'/Correlgram_MPcollocMCS_PWDAYfilt.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);


ff = figure('Position',[246,77,1187,900])
h = heatmap(ALL_statsig,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
h.NodeChildren(3).YDir='normal';
colormap(flipud(pepsi2))
caxis([-1 1])
h.XDisplayLabels = varlab;
h.YDisplayLabels = varlab;
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';
title('Correlogram - MCS lifetime stats, mean MP stats during MCS collocation (filters out LS, daytime thermo only, filters out PW < 24mm)')

saveas(h, horzcat(imout,'/Correlgram_MPcollocMCS_SIGMAP_PWDAYfilt.png') );
outlab = horzcat(imout,'/Correlgram_MPcollocMCS_SIGMAP_PWDAYfilt.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);











%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%
%%%                         Now repeat but with just PW filter applied
%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%recalculate the MPs' pre MCSI duration to apply filters in MPstats space. 
filtPW_MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filtPW_MPPREDURatMCSI_ALLYRS(:) = NaN;  
filtPWDAYTIME_MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;    filtPWDAYTIME_MPPREDURatMCSI_ALLYRS(:) = NaN;  
for y = 1 : mcs_years % which is same as num years of MP objects 
    for n = 1 : mcs_tracks
        %  y = 6; n = 82;
        mpobjs = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ;      % MP object(s) number (or lack thereof) for this MCSI event
        for u = 1:length(mpobjs)   %note, there could be more than one syn obj present at MCSI because of calling MCSI period as t = 1-2 of MCS
            if(  isempty( mpobjs(u) ) == 0  & isnan( mpobjs(u) ) == 0  &  mpobjs(u) > 0 )  
                %now log MPI and MCSI times for each MP-MCS
                mcsItime = basetime_MCSstats_ALLYRS(1:5, n, y) ;   % Mcs obj initiation time for this MCS - considering first few because of annoying sometime nans at first few MCS times(s)
 
                %apply filtering masks here:
                if(  isnan(maskPW_MPstats_ALLYRS(1, mpobjs(u)  , y))==0   )
                    mpItime = basetime_MPstats_ALLYRS(1, mpobjs(u)  , y) ;       %MP obj initiation time for this MCS
                    mpI_vs_mcsI_dt = vertcat( mpI_vs_mcsI_dt , (mcsItime(1) - mpItime)/3600  ) ;  % [HOURS]   %you could alter this loop to make this variable in the format of MCSstats arrays if you want to.
                    filtPW_MPPREDURatMCSI_ALLYRS(n,y) = (mcsItime(1) - mpItime)/3600 ;  % logging it in MCS (tracks, year) space
                end

                %apply filtering masks here:
                if(  isnan(maskPW_MPstats_ALLYRS(1,mpobjs(u),y))==0    &   isnan( maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(1,mpobjs(u),y) ) == 0 )
                    mpItime = basetime_MPstats_ALLYRS(1, mpobjs(u)  , y) ;       %MP obj initiation time for this MCS
                    mpI_vs_mcsI_dt = vertcat( mpI_vs_mcsI_dt , (mcsItime(1) - mpItime)/3600  ) ;  % [HOURS]   %you could alter this loop to make this variable in the format of MCSstats arrays if you want to.
                    filtPWDAYTIME_MPPREDURatMCSI_ALLYRS(n,y) = (mcsItime(1) - mpItime)/3600 ;  % logging it in MCS (tracks, year) space
                end

            end
        end
    end
end

%  datetime( basetime_MPstats_ALLYRS(1,mpobjs(u),y), 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') 
%  length( find( isnan(filtPWDAYTIME_MPPREDURatMCSI_ALLYRS)==0 ) )
%  length( find( isnan(filtPW_MPPREDURatMCSI_ALLYRS)==0 ) )
%  length( find( isnan(MPPREDURatMCSI_ALLYRS)==0 ) )

%%%% repeated from above to (re)fix for whatever reason it breaks:
totalrainmass_MCSstats_ALLYRSb = duration_MCSstats_ALLYRS;    totalrainmass_MCSstats_ALLYRSb(:) = NaN;  
rainmass  =  totalrain_MCSstats_ALLYRS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]
for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        %for t = 1:mtimes
            totalrainmass_MCSstats_ALLYRSb(n,y)  =  sum (   rainmass(:,n,y) , 'omitnan'   )  ;   % total_rain [km^3/h] * desnity of water [kg/km^3]
        %end
    end
end
totalrainmass_MCSstats_ALLYRSb(totalrainmass_MCSstats_ALLYRSb==0) = NaN;

%recalc speed (though not sure I'm crazy about matlabs motionx,y results?
MP_speeds_ALLYRS = (  MotionX_MPstats_ALLYRS.*MotionX_MPstats_ALLYRS +   MotionY_MPstats_ALLYRS.*MotionY_MPstats_ALLYRS ).^0.5   ;


%%%% For MCSs with a MP obj present at MCSI: 

filt_MPVORTatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;       	filt_MPVORTatMCSI_ALLYRS(:) = NaN ;         % magnitude of the vorticity at time of MCSI
%   MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;                                              % duration of vorticity track prior to time of MCSI   % already defined above
filt_MPAREAatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;      	filt_MPAREAatMCSI_ALLYRS(:) = NaN ;         % area of vorticity at time of MCSI
filt_MPCOLLOCMCS_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPCOLLOCMCS_ALLYRS(:) = NaN ;    % Number of time steps post-mcsi with a syn obj present 
filt_MPSPEEDatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;       filt_MPSPEEDatMCSI_ALLYRS(:) = NaN ;    % MP obj speed at time of MCSI

filt_MPmeanMUCAPEatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filt_MPmeanMUCAPEatMCSI_ALLYRS(:) = NaN ;
filt_MPmaxMUCAPEatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmaxMUCAPEatMCSI_ALLYRS(:) = NaN ;
filt_MPmeanMUCINatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanMUCINatMCSI_ALLYRS(:) = NaN ;
filt_MPminMUCINatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPminMUCINatMCSI_ALLYRS(:) = NaN ;
filt_MPmeanMULFCatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanMULFCatMCSI_ALLYRS(:) = NaN ;
filt_MPmeanMUELatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPmeanMUELatMCSI_ALLYRS(:) = NaN ;
filt_MPmeanPWatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;               filt_MPmeanPWatMCSI_ALLYRS(:) = NaN ;
filt_MPmaxPWatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;                filt_MPmaxPWatMCSI_ALLYRS(:) = NaN ;
filt_MPminPWatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;                filt_MPminPWatMCSI_ALLYRS(:) = NaN ;
filt_MPmeanshearmag0to2atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag0to2atMCSI_ALLYRS(:) = NaN ;
filt_MPmaxshearmag0to2atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag0to2atMCSI_ALLYRS(:) = NaN ;
filt_MPmeanshearmag0to6atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag0to6atMCSI_ALLYRS(:) = NaN ;
filt_MPmaxshearmag0to6atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag0to6atMCSI_ALLYRS(:) = NaN ;
filt_MPmeanshearmag2to9atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag2to9atMCSI_ALLYRS(:) = NaN ;
filt_MPmaxshearmag2to9atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag2to9atMCSI_ALLYRS(:) = NaN ;
filt_MPmeanOMEGA600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPmeanOMEGA600atMCSI_ALLYRS(:) = NaN ;
filt_MPminOMEGA600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;          filt_MPminOMEGA600atMCSI_ALLYRS(:) = NaN ;
filt_MPminOMEGAsub600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;       filt_MPminOMEGAsub600atMCSI_ALLYRS(:) = NaN ; 
filt_MPmeanVIWVDatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanVIWVDatMCSI_ALLYRS(:) = NaN ;
filt_MPminVIWVDatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPminVIWVDatMCSI_ALLYRS(:) = NaN ;
filt_MPmaxVIWVDatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPmaxVIWVDatMCSI_ALLYRS(:) = NaN ;
filt_MPmeanDIV750atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filt_MPmeanDIV750atMCSI_ALLYRS(:) = NaN ;
filt_MPminDIV750atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPminDIV750atMCSI_ALLYRS(:) = NaN ;
filt_MPminDIVsub600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPminDIVsub600atMCSI_ALLYRS(:) = NaN ;
filt_MPmeanWNDSPD600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPmeanWNDSPD600atMCSI_ALLYRS(:) = NaN ;
filt_MPmeanWNDDIR600atMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPmeanWNDDIR600atMCSI_ALLYRS(:) = NaN ;

%%% catalog these MP obj traits in MCS(tracks,years) space:
for y = 1:mcs_years
    for n = 1:mcs_tracks
        
        tmp = length(  find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  )  ;  %num of time in MCS with an MP
        MPCOLLOCMCS_ALLYRS(n,y) = tmp  ;  % NOTE: this includes all syn objs, not only the one(s) presnt during mcsi period
        
        % syn obj characteristics for syn present @ MCSI events:
        if(    isnan( MCSI_with_MP_ALLYRS(n,y) ) == 0    )
            
            %time of MCSI (defined well above)
            MCSItime = mcsibasetime_perMCS_ALLYRS(1:2,n,y) ;
            %the syn object present at MCSI
            mpobj = MCSI_with_MP_ALLYRS(n,y) ;
            
            if( isnan(mpobj)==0 )

                    %    basetime_MPstats_met_yymmddhhmmss_ALLYRS(:,mpobj,y)

                    %to account for mp obj present at second time in MCSI period but not first (since we are letting MCSI period be t = 1:2:
                    MPt1 = find( floor(basetime_MPstats_ALLYRS(:,mpobj,y)/100)  ==  floor(MCSItime(1)/100) )  ;
                    MPt2 = find( floor(basetime_MPstats_ALLYRS(:,mpobj,y)/100)  ==  floor(MCSItime(2)/100) )  ;
                    % time in syn obj's record when MCSI happens:
                    MPt = vertcat(MPt1,MPt2) ;  MPt = MPt(1);
                    
                    %populate the syn obj metrics of interest:
                    filt_MPVORTatMCSI_ALLYRS(n,y) = maxVOR600_MPstats_ALLYRS(MPt,mpobj,y)  .* MPdurMASK_forMPs(MPt,mpobj,y);
                    filt_MPAREAatMCSI_ALLYRS(n,y) = area_MPstats_ALLYRS(MPt,mpobj,y)  .* MPdurMASK_forMPs(MPt,mpobj,y);
                    % MPPREDURatMCSI_ALLYRS -  already cataloged above
                    %tmp = length(  find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  )  ;
                    %MPCOLLOCMCS_ALLYRS(n,y) = tmp  ;  % NOTE: this includes all syn objs, not only the one(s) presnt during mcsi period
                    filt_MPSPEEDatMCSI_ALLYRS(n,y) =  ( ( MotionX_MPstats_ALLYRS(MPt,mpobj,y) .* MotionX_MPstats_ALLYRS(MPt,mpobj,y)  +   MotionY_MPstats_ALLYRS(MPt,mpobj,y).*MotionY_MPstats_ALLYRS(MPt,mpobj,y) ).^0.5 ).* ( MPdurMASK_forMPs(MPt,mpobj,y) )  ;
                   
                    filt_MPmeanMUCAPEatMCSI_ALLYRS(n,y) =           meanMUCAPE_MPstats_ALLYRS(MPt,mpobj,y)       .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y)  ;   
                    filt_MPmaxMUCAPEatMCSI_ALLYRS(n,y) =            maxMUCAPE_MPstats_ALLYRS(MPt,mpobj,y)        .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y)  ;    
                    filt_MPmeanMUCINatMCSI_ALLYRS(n,y) =            meanMUCIN_MPstats_ALLYRS(MPt,mpobj,y)        .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y)  ;    
                    filt_MPminMUCINatMCSI_ALLYRS(n,y) =             minMUCIN_MPstats_ALLYRS(MPt,mpobj,y)         .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y)  ;    
                    filt_MPmeanMULFCatMCSI_ALLYRS(n,y) =            meanMULFC_MPstats_ALLYRS(MPt,mpobj,y)        .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y)  ;    
                    filt_MPmeanMUELatMCSI_ALLYRS(n,y) =             meanMUEL_MPstats_ALLYRS(MPt,mpobj,y)         .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y)  ;  
                    filt_MPmeanPWatMCSI_ALLYRS(n,y) =               meanPW_MPstats_ALLYRS(MPt,mpobj,y)           .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y); 
                    filt_MPmaxPWatMCSI_ALLYRS(n,y) =                maxPW_MPstats_ALLYRS(MPt,mpobj,y)            .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);  
                    filt_MPminPWatMCSI_ALLYRS(n,y) =                minPW_MPstats_ALLYRS(MPt,mpobj,y)            .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);  
                    filt_MPmeanshearmag0to2atMCSI_ALLYRS(n,y) =     meanshearmag0to2_MPstats_ALLYRS(MPt,mpobj,y) .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);  
                    filt_MPmaxshearmag0to2atMCSI_ALLYRS(n,y) =      maxshearmag0to2_MPstats_ALLYRS(MPt,mpobj,y)  .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmeanshearmag0to6atMCSI_ALLYRS(n,y) =     meanshearmag0to6_MPstats_ALLYRS(MPt,mpobj,y) .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmaxshearmag0to6atMCSI_ALLYRS(n,y) =      maxshearmag0to6_MPstats_ALLYRS(MPt,mpobj,y)  .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmeanshearmag2to9atMCSI_ALLYRS(n,y) =     meanshearmag2to9_MPstats_ALLYRS(MPt,mpobj,y) .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmaxshearmag2to9atMCSI_ALLYRS(n,y) =      maxshearmag2to9_MPstats_ALLYRS(MPt,mpobj,y)  .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);  
                    filt_MPmeanOMEGA600atMCSI_ALLYRS(n,y) =         meanOMEGA600_MPstats_ALLYRS(MPt,mpobj,y)     .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPminOMEGA600atMCSI_ALLYRS(n,y) =          minOMEGA600_MPstats_ALLYRS(MPt,mpobj,y)      .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPminOMEGAsub600atMCSI_ALLYRS(n,y) =       minOMEGAsub600_MPstats_ALLYRS(MPt,mpobj,y)   .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmeanVIWVDatMCSI_ALLYRS(n,y) =            meanVIWVD_MPstats_ALLYRS(MPt,mpobj,y)        .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPminVIWVDatMCSI_ALLYRS(n,y) =             minVIWVD_MPstats_ALLYRS(MPt,mpobj,y)         .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmaxVIWVDatMCSI_ALLYRS(n,y) =             maxVIWVD_MPstats_ALLYRS(MPt,mpobj,y)         .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);    
                    filt_MPmeanDIV750atMCSI_ALLYRS(n,y) =           meanDIV750_MPstats_ALLYRS(MPt,mpobj,y)       .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPminDIV750atMCSI_ALLYRS(n,y) =            minDIV750_MPstats_ALLYRS(MPt,mpobj,y)        .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPminDIVsub600atMCSI_ALLYRS(n,y) =         minDIVsub600_MPstats_ALLYRS(MPt,mpobj,y)     .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
                    filt_MPmeanWNDSPD600atMCSI_ALLYRS(n,y) =        meanWNDSPD600_MPstats_ALLYRS(MPt,mpobj,y)    .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);    
                    filt_MPmeanWNDDIR600atMCSI_ALLYRS(n,y) =        meanWNDDIR600_MPstats_ALLYRS(MPt,mpobj,y)    .*   MPdurMASK_forMPs(MPt,mpobj,y) .*  maskPW_MPstats_ALLYRS(MPt,mpobj,y);   
            end
            
        end 
    end
end
MPCOLLOCMCS_ALLYRS(MPCOLLOCMCS_ALLYRS==0) = NaN;









%%%%%%%%%
%%%  for events with MPs present at MCSI

%%%% MCS lifetime metrics
MCS_maxarea             =  maxareapf_MCSstats_ALLYRS .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_areagrowthrate      =  dAdt_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_meanspeed           =  MCSspeed_MCSstats_ALLYRS .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_totalrainmass       =  totalrainmass_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_HvyRainAccum        =  pf_accumrainheavy_MCSstats_ALLYRSb  .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_EchoTop50dBZ        =  pf_ETH50_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_EchoTop30dBZ        =  pf_ETH30_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_ConvectRainRate     =  convrainrate_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_ConvectRainArea     =  convrainarea_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_ConvectRainMass     =  convrainmass_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_StratiformRainRate  =  stratrainrate_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_StratiformRainArea  =  stratrainarea_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;
MCS_StratiformRainMass  =  stratrainmass_MCSstats_ALLYRSb .* permute(MPdurMASK_forMCSs(1,:,:),[2 3 1]) ;

%%%% MP metric at MCSI
MP_vorticity            =  filt_MPVORTatMCSI_ALLYRS;
MP_speed                =  filt_MPSPEEDatMCSI_ALLYRS;
MP_area                 =  filt_MPAREAatMCSI_ALLYRS;
MPpwfilt_preMCSduration =  filtPW_MPPREDURatMCSI_ALLYRS;
MPpwdaytimefilt_preMCSduration       =  filtPWDAYTIME_MPPREDURatMCSI_ALLYRS;
%%%% MP env metric at MCSI
MP_maxMUCAPE            =  filt_MPmaxMUCAPEatMCSI_ALLYRS;
MP_minMUCIN             =  filt_MPminMUCINatMCSI_ALLYRS;
MP_meanMULFC            =  filt_MPmeanMULFCatMCSI_ALLYRS;
MP_meanMUEL             =  filt_MPmeanMUELatMCSI_ALLYRS;
MP_meanPW               =  filt_MPmeanPWatMCSI_ALLYRS;
MP_meanshearmag0to2     =  filt_MPmeanshearmag0to2atMCSI_ALLYRS;
MP_meanshearmag0to6     =  filt_MPmeanshearmag0to6atMCSI_ALLYRS;
MP_meanshearmag2to9     =  filt_MPmeanshearmag2to9atMCSI_ALLYRS;
MP_minOMEGAsub600       =  filt_MPminOMEGAsub600atMCSI_ALLYRS;
MP_minDIVsub600         =  filt_MPminDIVsub600atMCSI_ALLYRS;
MP_meanWNDSPD600        =  filt_MPmeanWNDSPD600atMCSI_ALLYRS;

ALL_vars = {'MCS_maxarea' ;
    'MCS_areagrowthrate'  ;
    'MCS_meanspeed' ;
    'MCS_totalrainmass' ;
    'MCS_HvyRainAccum'  ;
    'MCS_EchoTop50dBZ'  ;
    'MCS_EchoTop30dBZ'  ;
    'MCS_ConvectRainRate' ;
    'MCS_ConvectRainArea' ;
    'MCS_ConvectRainMass' ;
    'MCS_StratiformRainRate' ;
    'MCS_StratiformRainArea' ;
    'MCS_StratiformRainMass' ;
    'MP_vorticity';
    'MP_speed';
    'MP_area';
    'MPpwfilt_preMCSduration';
    'MP_maxMUCAPE';
    'MP_minMUCIN';
    'MP_meanMULFC';
    'MP_meanMUEL';
    'MP_meanPW';
    'MP_meanshearmag0to2';
    'MP_meanshearmag0to6';
    'MP_meanshearmag2to9';
    'MP_minOMEGAsub600';
    'MP_minDIVsub600';
    'MP_meanWNDSPD600';
    'MP_meanWNDDIR600'};

ALL_vars = flipdim(ALL_vars,1) ;

ALL_corrs = zeros(length(ALL_vars),length(ALL_vars));     ALL_corrs(:) = NaN;
ALL_Ps = zeros(length(ALL_vars),length(ALL_vars));        ALL_Ps(:) = NaN;
ALL_statsig = zeros(length(ALL_vars),length(ALL_vars));        ALL_statsig(:) = NaN;
SIGTHRESH = 0.05;
for n = 1:length(ALL_vars)
    for m = 1:length(ALL_vars)
        %  n = 1; m = 3
        AA = char(ALL_vars(n)) ; 
        AA = eval(AA);
        BB = char(ALL_vars(m)) ;  
        BB = eval(BB);
        kill = isnan(BB);
        BB(kill) = []; AA(kill) = [];
        kill = isnan(AA);
        BB(kill) = []; AA(kill) = [];
        [corab, pval] = corrcoef(AA(:),BB(:)); corab = corab(2); pval = pval(2);
        ALL_corrs(n,m) = corab ;
        ALL_Ps(n,m) = pval;
        if(pval < SIGTHRESH)
            ALL_statsig(n,m) = NaN;
        else
            ALL_corrs(n,m) = NaN;
            ALL_statsig(n,m) = 0; %0;    
        end
    end
end
ALL_corrs = single(ALL_corrs);
isupper = logical(triu(ones(size(ALL_corrs)),1));
ALL_corrs(isupper) = NaN;
ALL_corrs(ALL_corrs >= 0.99999999999999999999999) = NaN;

ALL_statsig = single(ALL_statsig);
isupper = logical(triu(ones(size(ALL_statsig)),1));
ALL_statsig(isupper) = NaN;
ALL_statsig(ALL_statsig >= 0.99999999999999999999999) = NaN;

varlab = {};
for l = 1:length(ALL_vars)
   asd = char(ALL_vars(l,:) )   ;
   asd(find(asd=='_'))=' '   ;
   varlab = vertcat(varlab,asd);
end

ALL_corrs = round(ALL_corrs,2);

dualpol_colmap
ff = figure('Position',[246,77,1187,900])
h = heatmap(ALL_corrs,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
h.NodeChildren(3).YDir='normal';
colormap(flipud(pepsi2))
caxis([-1 1])
h.XDisplayLabels = varlab;
h.YDisplayLabels = varlab;
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';
title('Correlogram - MCS lifetime stats, MP stats at MCSI(-3hr) (filters out LS, filt out premcsi<3hr, filters out preMCSIdur<3hrs, filters out PW < 24mm)' ) 

saveas(h, horzcat(imout,'/Correlgram_MPatMCSI_PWfilt.png') );
outlab = horzcat(imout,'/Correlgram_MPatMCSI_PWfilt.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);

% ff = figure('Position',[246,77,1187,900])
% h = heatmap(ALL_statsig,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
% h.NodeChildren(3).YDir='normal';
% colormap(flipud(pepsi2))
% caxis([-1 1])
% h.XDisplayLabels = varlab;
% h.YDisplayLabels = varlab;
% ax = gca;
% axp = struct(ax);       %you will get a warning
% axp.Axes.XAxisLocation = 'top';
% title('Correlogram - MCS lifetime stats, mean MP stats at MCSI(-3hr) (filters out LS, filt out premcsi<3hr, filters out preMCSIdur<3hrs, filters out PW < 24mm)' ) 
% 
% saveas(h, horzcat(imout,'/Correlgram_MPatMCSI_SIGMAP_PWfilt.png') );
% outlab = horzcat(imout,'/Correlgram_MPatMCSI_SIGMAP_PWfilt.eps');
% EPSprint = horzcat('print -painters -depsc ',outlab);
% eval([EPSprint]);












%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%   Now calc the 2D histograms of MP obj properties throughout MCS
%%%   lifetime (while they are collocated) rather than just the MP obj 
%%%   properties @ time of MCSI - filtered versions

%%%% For MCSs with a SYN obj present at any time throughout its life: 

%notes (May 13 2024): The MPstats metrics (that are converted to [mcsnum,year] space below)
%                     are now hit with the PW & DAYTIME masks made above.
%                     The MCS metrics themselves are NOT filtered becasue
%                     that is more complicated than my ADHD brain can
%                     handle right now. however, when you're looking at the MP-MCS relationships, 
%                     the MP-filtered fields will take care of this. So
%                     MCS-MCS relationships dont have this filter, but I
%                     think that's ok because I am not really looking at
%                     these (and they may not need to be filtered anyway?)

filt_MPVORTfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPVORTfullmcs_ALLYRS(:) = NaN ;         % magnitude of the max vorticity while syn obj touching mcs
filt_MPAREAfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      	 filt_MPAREAfullmcs_ALLYRS(:) = NaN ;         % area of vorticity while syn obj touching mcs
filt_MPSPEEDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;       filt_MPSPEEDfullmcs_ALLYRS(:) = NaN ;        % Syn obj speed while syn obj touching mcs
filt_MPcollocdurfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;   filt_MPcollocdurfullmcs_ALLYRS(:) = NaN ;       % collocation period of MCS-MP (if multiple MCSs per MP, use the longest collocation per MP?)
% MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     % duration of vorticity track prior to time of MCSI   % already defined above
% MPCOLLOCMCS_ALLYRS = zeros(mcs_tracks,mcs_years) ;    % Number of time steps post-mcsi with a syn obj present - already defined above

filt_MPmeanMUCAPEfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filt_MPmeanMUCAPEfullmcs_ALLYRS(:) = NaN ;
filt_MPmaxMUCAPEfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmaxMUCAPEfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanMUCINfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanMUCINfullmcs_ALLYRS(:) = NaN ;
filt_MPminMUCINfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPminMUCINfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanMULFCfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanMULFCfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanMUELfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPmeanMUELfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;               filt_MPmeanPWfullmcs_ALLYRS(:) = NaN ;
filt_MPmaxPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;                filt_MPmaxPWfullmcs_ALLYRS(:) = NaN ;
filt_MPminPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;                filt_MPminPWfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanshearmag0to2fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag0to2fullmcs_ALLYRS(:) = NaN ;
filt_MPmaxshearmag0to2fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag0to2fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanshearmag0to6fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag0to6fullmcs_ALLYRS(:) = NaN ;
filt_MPmaxshearmag0to6fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag0to6fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanshearmag2to9fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag2to9fullmcs_ALLYRS(:) = NaN ;
filt_MPmaxshearmag2to9fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag2to9fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanOMEGA600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPmeanOMEGA600fullmcs_ALLYRS(:) = NaN ;
filt_MPminOMEGA600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;          filt_MPminOMEGA600fullmcs_ALLYRS(:) = NaN ;
filt_MPminOMEGAsub600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;       filt_MPminOMEGAsub600fullmcs_ALLYRS(:) = NaN ; 
filt_MPmeanVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanVIWVDfullmcs_ALLYRS(:) = NaN ;
filt_MPminVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPminVIWVDfullmcs_ALLYRS(:) = NaN ;
filt_MPmaxVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPmaxVIWVDfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanDIV750fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filt_MPmeanDIV750fullmcs_ALLYRS(:) = NaN ;
filt_MPminDIV750fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPminDIV750fullmcs_ALLYRS(:) = NaN ;
filt_MPminDIVsub600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPminDIVsub600fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanWNDSPD600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPmeanWNDSPD600fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanWNDDIR600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPmeanWNDDIR600fullmcs_ALLYRS(:) = NaN ;


%%% catalog these syn obj traits in MCS(tracks,years) space:
for y = 1:mcs_years
    for n = 1:mcs_tracks

        %   n = 79;  y = 2;  
        
        %t-indices in each MCS track where there is a syn present
        mpspresent = find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  ;
        
        if( isempty(mpspresent) == 0)

            %empty vars to hold mean/max metrics for each syn object that
            %you will later mean/max again to relate to MCSs:
            mps_vorts = [] ;
            mps_areas = [] ;
            mps_speeds = [] ;
            mps_colloc = [];
            meanMUCAPE = [] ;
            maxMUCAPE = [] ;
            meanMUCIN = [] ;
            minMUCIN = [] ;
            meanMULFC = [] ;
            meanMUEL = [] ;
            meanPW = [] ;
            maxPW = [] ;
            minPW = [] ;
            meanshearmag0to2 = [] ;
            maxshearmag0to2 = [] ;
            meanshearmag0to6 = [] ;
            maxshearmag0to6 = [] ;
            meanshearmag2to9 = [] ;
            maxshearmag2to9 = [] ;
            meanOMEGA600 = [] ;
            minOMEGA600 = [] ;
            minOMEGAsub600 = [] ;
            meanVIWVD = [] ;
            minVIWVD = [] ;
            maxVIWVD = [] ;
            meanDIV750 = [] ;
            minDIV750 = [] ;
            minDIVsub600 = [] ;
            meanWNDSPD600 = [] ;
            meanWNDDIR600 = [] ;
            collocdur = [];

            % diagnostic example:     y = 6; n = 80;
            % locate time and mp numbers corresponding to this MCS by referecing a masked/filtered PW/daytime MPstats list:
            found = find( filtPWDAYTIME_MCStracks_MPstats_ALLYRS(:,:,:,y) == n )  ;
            [tind_f,  mcsind_f,  mpind_f] = ind2sub(size(filtPWDAYTIME_MCStracks_MPstats_ALLYRS(:,:,:,y)),found) ;     clear found
            unimps = unique(mpind_f) ;
            colls = [];
            for mm = 1:length(unimps)
                colls = vertcat(colls,length(find(mpind_f==unimps(mm))));
            end
            %going to call the final MCS's MP collocation the mean of all of the MP collocations. Or does it make sense to do max? sum?  
            collocdur = vertcat(collocdur, mean(colls) );
            
            %all of the unique syn tracks in this MCS's full track:
            mpnums = unique(MPtracks_perMCS_ALLYRS(mpspresent,n,y)) ;
            
            %loop thru all of the syn objs overlapping the current MCS
            for s = 1:length(mpnums)
                
                %find MCS's time indices when current syn object is present, then
                %log the first & last time
                mp_mcst = find( MPtracks_perMCS_ALLYRS(:,n,y) == mpnums(s) )  ;
                mcst1 = basetime_MCSstats_ALLYRS(mp_mcst(1),n,y) ;
                mcst2 = basetime_MCSstats_ALLYRS(mp_mcst(end),n,y) ;
                
                %find the time indices in current syn obj's track corersponding to
                %the MCS overlap period:
                MPti1 = find( floor(mcst1/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;
                MPti2 = find( floor(mcst2/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;    

                % log the max/mean of the current syn obj's
                % characteristics during its overlap period with the MCS.
                % throw it into an array that contains the same for all
                % other syn obj's touching the current MCS:
                mps_vorts =  vertcat(mps_vorts, max( maxVOR600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;      %max vort of syn obj during its contact with MCS
                mps_areas =  vertcat(mps_areas, max( area_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )   ) ;          %max area of syn obj during its contact with MCS  
                mps_speeds = vertcat(mps_speeds, mean( MP_speeds_ALLYRS(MPti1:MPti2,mpnums(s),y) , 'omitnan')) ;  %mean speed of syn obj during its contact with MCS  
                
%                 %calced this seperately above already
%                 mps_colloc =  vercat(mps_colloc,    max(    MPMCS_collocDur_MPstats(:,mpnums(s),y) )          );
%                 blah = meanMUCAPE_MPstats_ALLYRS(:,mpnums(s),y) .* maskPW_MPstats_ALLYRS(:,mpobj,y) .*  maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(:,mpobj,y);
%                 meanMUCAPE          = vertcat( meanMUCAPE,       max(  blah(MPti1:MPti2)       , [] ,'omitnan' )  ) ;

                maxMUCAPE           = vertcat( maxMUCAPE,        max(  maxMUCAPE_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanMUCIN           = vertcat( meanMUCIN,        min(  meanMUCIN_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minMUCIN            = vertcat( minMUCIN,         min(  minMUCIN_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanMULFC           = vertcat( meanMULFC,        min(  meanMULFC_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanMUEL            = vertcat( meanMUEL,         max(  meanMUEL_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanPW              = vertcat( meanPW,           max(  meanPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)           .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxPW               = vertcat( maxPW,            max(  maxPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)            .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minPW               = vertcat( minPW,            min(  minPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)            .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanshearmag0to2    = vertcat( meanshearmag0to2, max(  meanshearmag0to2_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxshearmag0to2     = vertcat( maxshearmag0to2,  max(  maxshearmag0to2_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)  .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanshearmag0to6    = vertcat( meanshearmag0to6, max(  meanshearmag0to6_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxshearmag0to6     = vertcat( maxshearmag0to6,  max(  maxshearmag0to6_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)  .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanshearmag2to9    = vertcat( meanshearmag2to9, max(  meanshearmag2to9_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxshearmag2to9     = vertcat( maxshearmag2to9,  max(  maxshearmag2to9_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)  .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanOMEGA600        = vertcat( meanOMEGA600,     min(  meanOMEGA600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)     .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minOMEGA600         = vertcat( minOMEGA600,      min(  minOMEGA600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)      .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minOMEGAsub600      = vertcat( minOMEGAsub600,   min(  minOMEGAsub600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)   .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanVIWVD           = vertcat( meanVIWVD,        max(  meanVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minVIWVD            = vertcat( minVIWVD,         min(  minVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxVIWVD            = vertcat( maxVIWVD,         max(  maxVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanDIV750          = vertcat( meanDIV750,       min(  meanDIV750_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)       .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minDIV750           = vertcat( minDIV750,        min(  minDIV750_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minDIVsub600        = vertcat( minDIVsub600,     min(  minDIVsub600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)     .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanWNDSPD600       = vertcat( meanWNDSPD600,    max(  meanWNDSPD600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)    .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanWNDDIR600       = vertcat( meanWNDDIR600,    mean(  meanWNDDIR600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)   .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), 'omitnan' )  ) ;
            end
            
            %  bla1 = maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(:,:,y)   ;
            %  bla2 =  maskPW_MPstats_ALLYRS(:,:,y)   ;
            %  bla3 = maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(:,:,y)  .*  maskPW_MPstats_ALLYRS(:,:,y)   ;


            %end up with the means of all of the mean/max MP objs
            %characteristics across all syn objects touching the current MCS:
            filt_MPVORTfullmcs_ALLYRS(n,y)       =  mean( mps_vorts , 'omitnan');       
            filt_MPAREAfullmcs_ALLYRS(n,y)       =  mean( mps_areas , 'omitnan');
            filt_MPSPEEDfullmcs_ALLYRS(n,y)      =  mean( mps_speeds , 'omitnan');
            filt_MPcollocdurfullmcs_ALLYRS(n,y)  =  mean( collocdur , 'omitnan');

            filt_MPmeanMUCAPEfullmcs_ALLYRS(n,y)         =  mean( meanMUCAPE , 'omitnan'); 
            filt_MPmaxMUCAPEfullmcs_ALLYRS(n,y)          =  mean( maxMUCAPE , 'omitnan'); 
            filt_MPmeanMUCINfullmcs_ALLYRS(n,y)          =  mean( meanMUCIN , 'omitnan'); 
            filt_MPminMUCINfullmcs_ALLYRS(n,y)           =  mean( minMUCIN , 'omitnan'); 
            filt_MPmeanMULFCfullmcs_ALLYRS(n,y)          =  mean( meanMULFC , 'omitnan'); 
            filt_MPmeanMUELfullmcs_ALLYRS(n,y)           =  mean( meanMUEL , 'omitnan'); 
            filt_MPmeanPWfullmcs_ALLYRS(n,y)             =  mean( meanPW , 'omitnan'); 
            filt_MPmaxPWfullmcs_ALLYRS(n,y)              =  mean( maxPW , 'omitnan'); 
            filt_MPminPWfullmcs_ALLYRS(n,y)              =  mean( minPW , 'omitnan'); 
            filt_MPmeanshearmag0to2fullmcs_ALLYRS(n,y)   =  mean( meanshearmag0to2 , 'omitnan'); 
            filt_MPmaxshearmag0to2fullmcs_ALLYRS(n,y)    =  mean( maxshearmag0to2 , 'omitnan'); 
            filt_MPmeanshearmag0to6fullmcs_ALLYRS(n,y)   =  mean( meanshearmag0to6 , 'omitnan'); 
            filt_MPmaxshearmag0to6fullmcs_ALLYRS(n,y)    =  mean( maxshearmag0to6 , 'omitnan'); 
            filt_MPmeanshearmag2to9fullmcs_ALLYRS(n,y)   =  mean( meanshearmag2to9 , 'omitnan'); 
            filt_MPmaxshearmag2to9fullmcs_ALLYRS(n,y)    =  mean( maxshearmag2to9 , 'omitnan'); 
            filt_MPmeanOMEGA600fullmcs_ALLYRS(n,y)       =  mean( meanOMEGA600 , 'omitnan'); 
            filt_MPminOMEGA600fullmcs_ALLYRS(n,y)        =  mean( minOMEGA600 , 'omitnan'); 
            filt_MPminOMEGAsub600fullmcs_ALLYRS(n,y)     =  mean( minOMEGAsub600 , 'omitnan'); 
            filt_MPmeanVIWVDfullmcs_ALLYRS(n,y)          =  mean( meanVIWVD , 'omitnan'); 
            filt_MPminVIWVDfullmcs_ALLYRS(n,y)           =  mean( minVIWVD , 'omitnan'); 
            filt_MPmaxVIWVDfullmcs_ALLYRS(n,y)           =  mean( maxVIWVD , 'omitnan'); 
            filt_MPmeanDIV750fullmcs_ALLYRS(n,y)         =  mean( meanDIV750 , 'omitnan'); 
            filt_MPminDIV750fullmcs_ALLYRS(n,y)          =  mean( minDIV750 , 'omitnan'); 
            filt_MPminDIVsub600fullmcs_ALLYRS(n,y)       =  mean( minDIVsub600 , 'omitnan'); 
            filt_MPmeanWNDSPD600fullmcs_ALLYRS(n,y)      =  mean( meanWNDSPD600 , 'omitnan'); 
            filt_MPmeanWNDDIR600fullmcs_ALLYRS(n,y)      =  mean( meanWNDDIR600 , 'omitnan'); 

        end
    end
end          

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  NOW PLOT for events with MPs & MCSs collocated. I believe vars in are in MCSstats
%%%  space ( before they are 1D(:) converted)

%%%% MCS lifetime metrics
MCS_maxarea             = maxareapf_MCSstats_ALLYRS(:) ;
MCS_areagrowthrate      = dAdt_MCSstats_ALLYRSb(:) ;
MCS_meanspeed           = MCSspeed_MCSstats_ALLYRS(:) ;
MCS_totalrainmass       = totalrainmass_MCSstats_ALLYRSb(:) ;
MCS_HvyRainAccum        = pf_accumrainheavy_MCSstats_ALLYRSb(:)  ;
MCS_EchoTop50dBZ        = pf_ETH50_MCSstats_ALLYRSb(:)  ;
MCS_EchoTop30dBZ        = pf_ETH30_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainRate     = convrainrate_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainArea     = convrainarea_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainMass     = convrainmass_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainRate  = stratrainrate_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainArea  = stratrainarea_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainMass  = stratrainmass_MCSstats_ALLYRSb(:)  ;

%%%% mean MP metric while collocated with MCS
MP_vorticity          =  filt_MPVORTfullmcs_ALLYRS(:)   ;
MP_speed              =  filt_MPSPEEDfullmcs_ALLYRS(:)  ;
MP_area               =  filt_MPAREAfullmcs_ALLYRS(:)   ;
%MP_preMCSduration     =  filt_MPPREDURatMCSI_ALLYRS(:)  ;
MP_MCS_collocperiod       =  filt_MPcollocdurfullmcs_ALLYRS(:)  ;
%%%% MP env metric during MCS-MP colloc
MP_maxMUCAPE          =  filt_MPmaxMUCAPEfullmcs_ALLYRS ;
MP_minMUCIN           =  filt_MPminMUCINfullmcs_ALLYRS;
MP_meanMULFC          =  filt_MPmeanMULFCfullmcs_ALLYRS;
MP_meanMUEL           =  filt_MPmeanMUELfullmcs_ALLYRS ; 
MP_meanPW             =  filt_MPmeanPWfullmcs_ALLYRS;
MP_meanshearmag0to2   =  filt_MPmeanshearmag0to2fullmcs_ALLYRS ;
MP_meanshearmag0to6   =  filt_MPmeanshearmag0to6fullmcs_ALLYRS;
MP_meanshearmag2to9   =  filt_MPmeanshearmag2to9fullmcs_ALLYRS; 
MP_minOMEGA600        =  filt_MPminOMEGA600fullmcs_ALLYRS;
MP_minOMEGAsub600     =  filt_MPminOMEGAsub600fullmcs_ALLYRS ; 
MP_minDIV750          =  filt_MPminDIV750fullmcs_ALLYRS;
MP_minDIVsub600       =  filt_MPminDIVsub600fullmcs_ALLYRS;
MP_meanWNDSPD600      =  filt_MPmeanWNDSPD600fullmcs_ALLYRS;
MP_meanWNDDIR600      =  filt_MPmeanWNDDIR600fullmcs_ALLYRS ;

ALL_vars = {'MCS_maxarea' ;
    'MCS_areagrowthrate'  ;
    'MCS_meanspeed' ;
    'MCS_totalrainmass' ;
    'MCS_HvyRainAccum'  ;
    'MCS_EchoTop50dBZ'  ;
    'MCS_EchoTop30dBZ'  ;
    'MCS_ConvectRainRate' ;
    'MCS_ConvectRainArea' ;
    'MCS_ConvectRainMass' ;
    'MCS_StratiformRainRate' ;
    'MCS_StratiformRainArea' ;
    'MCS_StratiformRainMass' ;
    'MP_vorticity';
    'MP_speed';
    'MP_area';
    'MP_MCS_collocperiod'
    'MP_maxMUCAPE';
    'MP_minMUCIN';
    'MP_meanMULFC';
    'MP_meanMUEL';
    'MP_meanPW';
    'MP_meanshearmag0to2';
    'MP_meanshearmag0to6';
    'MP_meanshearmag2to9';
    'MP_minOMEGAsub600';
    'MP_minDIVsub600';
    'MP_meanWNDSPD600';
    'MP_meanWNDDIR600'};

ALL_vars = flipdim(ALL_vars,1) ;

ALL_corrs = zeros(length(ALL_vars),length(ALL_vars));     ALL_corrs(:) = NaN;
ALL_Ps = zeros(length(ALL_vars),length(ALL_vars));        ALL_Ps(:) = NaN;
ALL_statsig = zeros(length(ALL_vars),length(ALL_vars));        ALL_statsig(:) = NaN;
SIGTHRESH = 0.05;
for n = 1:length(ALL_vars)
    for m = 1:length(ALL_vars)
        %  n = 1; m = 3
        AA = char(ALL_vars(n)) ; 
        AA = eval(AA);
        BB = char(ALL_vars(m)) ;  
        BB = eval(BB);
        kill = isnan(BB);
        BB(kill) = []; AA(kill) = [];
        kill = isnan(AA);
        BB(kill) = []; AA(kill) = [];
        [corab, pval] = corrcoef(AA(:),BB(:)); corab = corab(2); pval = pval(2);
        ALL_corrs(n,m) = corab ;
        ALL_Ps(n,m) = pval;
        if(pval < SIGTHRESH)
            ALL_statsig(n,m) = NaN;
        else
            ALL_corrs(n,m) = NaN;
            ALL_statsig(n,m) = 0; %0;    
        end
    end
end
ALL_corrs = single(ALL_corrs);
isupper = logical(triu(ones(size(ALL_corrs)),1));
ALL_corrs(isupper) = NaN;
ALL_corrs(ALL_corrs >= 0.99999999999999999999999) = NaN;

ALL_statsig = single(ALL_statsig);
isupper = logical(triu(ones(size(ALL_statsig)),1));
ALL_statsig(isupper) = NaN;
ALL_statsig(ALL_statsig >= 0.99999999999999999999999) = NaN;

varlab = {};
for l = 1:length(ALL_vars)
   asd = char(ALL_vars(l,:) )   ;
   asd(find(asd=='_'))=' '   ;
   varlab = vertcat(varlab,asd);
end

ALL_corrs = round(ALL_corrs,2);

dualpol_colmap
ff = figure('Position',[246,77,1187,900])
h = heatmap(ALL_corrs,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
h.NodeChildren(3).YDir='normal';
colormap(flipud(pepsi2))
caxis([-1 1])
h.XDisplayLabels = varlab;
h.YDisplayLabels = varlab;
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';
title('Correlogram - MCS lifetime stats, mean MP stats during MCS collocation (filters out LS, filters out PW < 24mm)')

saveas(h, horzcat(imout,'/Correlgram_MPcollocMCS_PWfilt.png') );
outlab = horzcat(imout,'/Correlgram_MPcollocMCS_PWfilt.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);


% ff = figure('Position',[246,77,1187,900])
% h = heatmap(ALL_statsig,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
% h.NodeChildren(3).YDir='normal';
% colormap(flipud(pepsi2))
% caxis([-1 1])
% h.XDisplayLabels = varlab;
% h.YDisplayLabels = varlab;
% ax = gca;
% axp = struct(ax);       %you will get a warning
% axp.Axes.XAxisLocation = 'top';
% title('Correlogram - MCS lifetime stats, mean MP stats during MCS collocation (filters out LS, filters out PW < 24mm)')
% 
% saveas(h, horzcat(imout,'/Correlgram_MPcollocMCS_SIGMAP_PWfilt.png') );
% outlab = horzcat(imout,'/Correlgram_MPcollocMCS_SIGMAP_PWfilt.eps');
% EPSprint = horzcat('print -painters -depsc ',outlab);
% eval([EPSprint]);

















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%
%%%                         Now repeat but with PW filter applied, divide
%%%                         up by duration collocation period
%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%   Now calc the 2D histograms of MP obj properties throughout MCS
%%%   lifetime (while they are collocated) rather than just the MP obj 
%%%   properties @ time of MCSI - filtered versions

%%%% For MCSs with a MP obj present at any time throughout its life: 

%notes (May 13 2024): The MPstats metrics (that are converted to [mcsnum,year] space below)
%                     are now hit with the PW & DAYTIME masks made above.
%                     The MCS metrics themselves are NOT filtered becasue
%                     that is more complicated than my ADHD brain can
%                     handle right now. however, when you're looking at the MP-MCS relationships, 
%                     the MP-filtered fields will take care of this. So
%                     MCS-MCS relationships dont have this filter, but I
%                     think that's ok because I am not really looking at
%                     these (and they may not need to be filtered anyway?)

%%%%%%%%%%%% long collocation:


filt_MPVORTfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPVORTfullmcs_ALLYRS(:) = NaN ;         % magnitude of the max vorticity while syn obj touching mcs
filt_MPAREAfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      	 filt_MPAREAfullmcs_ALLYRS(:) = NaN ;         % area of vorticity while syn obj touching mcs
filt_MPSPEEDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;       filt_MPSPEEDfullmcs_ALLYRS(:) = NaN ;        % Syn obj speed while syn obj touching mcs
filt_MPcollocdurfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;   filt_MPcollocdurfullmcs_ALLYRS(:) = NaN ;       % collocation period of MCS-MP (if multiple MCSs per MP, use the longest collocation per MP?)
% MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     % duration of vorticity track prior to time of MCSI   % already defined above
% MPCOLLOCMCS_ALLYRS = zeros(mcs_tracks,mcs_years) ;    % Number of time steps post-mcsi with a syn obj present - already defined above

filt_MPmeanMUCAPEfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filt_MPmeanMUCAPEfullmcs_ALLYRS(:) = NaN ;
filt_MPmaxMUCAPEfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmaxMUCAPEfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanMUCINfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanMUCINfullmcs_ALLYRS(:) = NaN ;
filt_MPminMUCINfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPminMUCINfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanMULFCfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanMULFCfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanMUELfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPmeanMUELfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;               filt_MPmeanPWfullmcs_ALLYRS(:) = NaN ;
filt_MPmaxPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;                filt_MPmaxPWfullmcs_ALLYRS(:) = NaN ;
filt_MPminPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;                filt_MPminPWfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanshearmag0to2fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag0to2fullmcs_ALLYRS(:) = NaN ;
filt_MPmaxshearmag0to2fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag0to2fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanshearmag0to6fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag0to6fullmcs_ALLYRS(:) = NaN ;
filt_MPmaxshearmag0to6fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag0to6fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanshearmag2to9fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag2to9fullmcs_ALLYRS(:) = NaN ;
filt_MPmaxshearmag2to9fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag2to9fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanOMEGA600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPmeanOMEGA600fullmcs_ALLYRS(:) = NaN ;
filt_MPminOMEGA600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;          filt_MPminOMEGA600fullmcs_ALLYRS(:) = NaN ;
filt_MPminOMEGAsub600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;       filt_MPminOMEGAsub600fullmcs_ALLYRS(:) = NaN ; 
filt_MPmeanVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanVIWVDfullmcs_ALLYRS(:) = NaN ;
filt_MPminVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPminVIWVDfullmcs_ALLYRS(:) = NaN ;
filt_MPmaxVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPmaxVIWVDfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanDIV750fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filt_MPmeanDIV750fullmcs_ALLYRS(:) = NaN ;
filt_MPminDIV750fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPminDIV750fullmcs_ALLYRS(:) = NaN ;
filt_MPminDIVsub600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPminDIVsub600fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanWNDSPD600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPmeanWNDSPD600fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanWNDDIR600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPmeanWNDDIR600fullmcs_ALLYRS(:) = NaN ;


%%% catalog these syn obj traits in MCS(tracks,years) space:
for y = 1:mcs_years
    for n = 1:mcs_tracks

        %   n = 79;  y = 2;  
        
        %t-indices in each MCS track where there is a syn present
        mpspresent = find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  ;
        
        if( isempty(mpspresent) == 0)

            %empty vars to hold mean/max metrics for each syn object that
            %you will later mean/max again to relate to MCSs:
            mps_vorts = [] ;
            mps_areas = [] ;
            mps_speeds = [] ;
            mps_colloc = [];
            meanMUCAPE = [] ;
            maxMUCAPE = [] ;
            meanMUCIN = [] ;
            minMUCIN = [] ;
            meanMULFC = [] ;
            meanMUEL = [] ;
            meanPW = [] ;
            maxPW = [] ;
            minPW = [] ;
            meanshearmag0to2 = [] ;
            maxshearmag0to2 = [] ;
            meanshearmag0to6 = [] ;
            maxshearmag0to6 = [] ;
            meanshearmag2to9 = [] ;
            maxshearmag2to9 = [] ;
            meanOMEGA600 = [] ;
            minOMEGA600 = [] ;
            minOMEGAsub600 = [] ;
            meanVIWVD = [] ;
            minVIWVD = [] ;
            maxVIWVD = [] ;
            meanDIV750 = [] ;
            minDIV750 = [] ;
            minDIVsub600 = [] ;
            meanWNDSPD600 = [] ;
            meanWNDDIR600 = [] ;
            collocdur = [];

            % diagnostic example:     y = 6; n = 80;
            % locate time and mp numbers corresponding to this MCS by referecing a masked/filtered PW/daytime MPstats list:
            found = find( filtPWDAYTIME_MCStracks_MPstats_ALLYRS(:,:,:,y) == n )  ;
            [tind_f,  mcsind_f,  mpind_f] = ind2sub(size(filtPWDAYTIME_MCStracks_MPstats_ALLYRS(:,:,:,y)),found) ;     clear found
            unimps = unique(mpind_f) ;
            colls = [];
            for mm = 1:length(unimps)
                colls = vertcat(colls,length(find(mpind_f==unimps(mm))));
            end
            %going to call the final MCS's MP collocation the mean of all of the MP collocations. Or does it make sense to do max? sum?  
            maxcoll = mean(colls);

            %if( maxcoll > 6 )
            collocdur = vertcat(collocdur, maxcoll );


            %all of the unique syn tracks in this MCS's full track:
            mpnums = unique(MPtracks_perMCS_ALLYRS(mpspresent,n,y)) ;
            
            %loop thru all of the syn objs overlapping the current MCS
            for s = 1:length(mpnums)
                
                %find MCS's time indices when current syn object is present, then
                %log the first & last time
                mp_mcst = find( MPtracks_perMCS_ALLYRS(:,n,y) == mpnums(s) )  ;
                mcst1 = basetime_MCSstats_ALLYRS(mp_mcst(1),n,y) ;
                mcst2 = basetime_MCSstats_ALLYRS(mp_mcst(end),n,y) ;
                
                %find the time indices in current syn obj's track corersponding to
                %the MCS overlap period:
                MPti1 = find( floor(mcst1/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;
                MPti2 = find( floor(mcst2/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;    

                % log the max/mean of the current syn obj's
                % characteristics during its overlap period with the MCS.
                % throw it into an array that contains the same for all
                % other syn obj's touching the current MCS:
                mps_vorts =  vertcat(mps_vorts, max( maxVOR600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;      %max vort of syn obj during its contact with MCS
                mps_areas =  vertcat(mps_areas, max( area_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )   ) ;          %max area of syn obj during its contact with MCS  
                mps_speeds = vertcat(mps_speeds, mean( MP_speeds_ALLYRS(MPti1:MPti2,mpnums(s),y) , 'omitnan')) ;  %mean speed of syn obj during its contact with MCS  

                maxMUCAPE           = vertcat( maxMUCAPE,        max(  maxMUCAPE_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanMUCIN           = vertcat( meanMUCIN,        min(  meanMUCIN_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minMUCIN            = vertcat( minMUCIN,         min(  minMUCIN_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanMULFC           = vertcat( meanMULFC,        min(  meanMULFC_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanMUEL            = vertcat( meanMUEL,         max(  meanMUEL_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanPW              = vertcat( meanPW,           max(  meanPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)           .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxPW               = vertcat( maxPW,            max(  maxPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)            .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minPW               = vertcat( minPW,            min(  minPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)            .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanshearmag0to2    = vertcat( meanshearmag0to2, max(  meanshearmag0to2_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxshearmag0to2     = vertcat( maxshearmag0to2,  max(  maxshearmag0to2_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)  .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanshearmag0to6    = vertcat( meanshearmag0to6, max(  meanshearmag0to6_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxshearmag0to6     = vertcat( maxshearmag0to6,  max(  maxshearmag0to6_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)  .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanshearmag2to9    = vertcat( meanshearmag2to9, max(  meanshearmag2to9_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxshearmag2to9     = vertcat( maxshearmag2to9,  max(  maxshearmag2to9_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)  .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanOMEGA600        = vertcat( meanOMEGA600,     min(  meanOMEGA600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)     .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minOMEGA600         = vertcat( minOMEGA600,      min(  minOMEGA600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)      .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minOMEGAsub600      = vertcat( minOMEGAsub600,   min(  minOMEGAsub600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)   .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanVIWVD           = vertcat( meanVIWVD,        max(  meanVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minVIWVD            = vertcat( minVIWVD,         min(  minVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxVIWVD            = vertcat( maxVIWVD,         max(  maxVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanDIV750          = vertcat( meanDIV750,       min(  meanDIV750_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)       .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minDIV750           = vertcat( minDIV750,        min(  minDIV750_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minDIVsub600        = vertcat( minDIVsub600,     min(  minDIVsub600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)     .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanWNDSPD600       = vertcat( meanWNDSPD600,    max(  meanWNDSPD600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)    .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanWNDDIR600       = vertcat( meanWNDDIR600,    mean(  meanWNDDIR600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)   .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), 'omitnan' )  ) ;
            end
            
            %  bla1 = maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(:,:,y)   ;
            %  bla2 =  maskPW_MPstats_ALLYRS(:,:,y)   ;
            %  bla3 = maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(:,:,y)  .*  maskPW_MPstats_ALLYRS(:,:,y)   ;

            %end up with the means of all of the mean/max MP objs
            %characteristics across all syn objects touching the current MCS:
            filt_MPVORTfullmcs_ALLYRS(n,y)       =  mean( mps_vorts , 'omitnan');       
            filt_MPAREAfullmcs_ALLYRS(n,y)       =  mean( mps_areas , 'omitnan');
            filt_MPSPEEDfullmcs_ALLYRS(n,y)      =  mean( mps_speeds , 'omitnan');
            filt_MPcollocdurfullmcs_ALLYRS(n,y)  =  mean( collocdur , 'omitnan');

            filt_MPmeanMUCAPEfullmcs_ALLYRS(n,y)         =  mean( meanMUCAPE , 'omitnan'); 
            filt_MPmaxMUCAPEfullmcs_ALLYRS(n,y)          =  mean( maxMUCAPE , 'omitnan'); 
            filt_MPmeanMUCINfullmcs_ALLYRS(n,y)          =  mean( meanMUCIN , 'omitnan'); 
            filt_MPminMUCINfullmcs_ALLYRS(n,y)           =  mean( minMUCIN , 'omitnan'); 
            filt_MPmeanMULFCfullmcs_ALLYRS(n,y)          =  mean( meanMULFC , 'omitnan'); 
            filt_MPmeanMUELfullmcs_ALLYRS(n,y)           =  mean( meanMUEL , 'omitnan'); 
            filt_MPmeanPWfullmcs_ALLYRS(n,y)             =  mean( meanPW , 'omitnan'); 
            filt_MPmaxPWfullmcs_ALLYRS(n,y)              =  mean( maxPW , 'omitnan'); 
            filt_MPminPWfullmcs_ALLYRS(n,y)              =  mean( minPW , 'omitnan'); 
            filt_MPmeanshearmag0to2fullmcs_ALLYRS(n,y)   =  mean( meanshearmag0to2 , 'omitnan'); 
            filt_MPmaxshearmag0to2fullmcs_ALLYRS(n,y)    =  mean( maxshearmag0to2 , 'omitnan'); 
            filt_MPmeanshearmag0to6fullmcs_ALLYRS(n,y)   =  mean( meanshearmag0to6 , 'omitnan'); 
            filt_MPmaxshearmag0to6fullmcs_ALLYRS(n,y)    =  mean( maxshearmag0to6 , 'omitnan'); 
            filt_MPmeanshearmag2to9fullmcs_ALLYRS(n,y)   =  mean( meanshearmag2to9 , 'omitnan'); 
            filt_MPmaxshearmag2to9fullmcs_ALLYRS(n,y)    =  mean( maxshearmag2to9 , 'omitnan'); 
            filt_MPmeanOMEGA600fullmcs_ALLYRS(n,y)       =  mean( meanOMEGA600 , 'omitnan'); 
            filt_MPminOMEGA600fullmcs_ALLYRS(n,y)        =  mean( minOMEGA600 , 'omitnan'); 
            filt_MPminOMEGAsub600fullmcs_ALLYRS(n,y)     =  mean( minOMEGAsub600 , 'omitnan'); 
            filt_MPmeanVIWVDfullmcs_ALLYRS(n,y)          =  mean( meanVIWVD , 'omitnan'); 
            filt_MPminVIWVDfullmcs_ALLYRS(n,y)           =  mean( minVIWVD , 'omitnan'); 
            filt_MPmaxVIWVDfullmcs_ALLYRS(n,y)           =  mean( maxVIWVD , 'omitnan'); 
            filt_MPmeanDIV750fullmcs_ALLYRS(n,y)         =  mean( meanDIV750 , 'omitnan'); 
            filt_MPminDIV750fullmcs_ALLYRS(n,y)          =  mean( minDIV750 , 'omitnan'); 
            filt_MPminDIVsub600fullmcs_ALLYRS(n,y)       =  mean( minDIVsub600 , 'omitnan'); 
            filt_MPmeanWNDSPD600fullmcs_ALLYRS(n,y)      =  mean( meanWNDSPD600 , 'omitnan'); 
            filt_MPmeanWNDDIR600fullmcs_ALLYRS(n,y)      =  mean( meanWNDDIR600 , 'omitnan'); 

        end
    end
end          

%   figure;   hist(filt_MPcollocdurfullmcs_ALLYRS(:),[0:1:22]);    mean(filt_MPcollocdurfullmcs_ALLYRS(:),'omitnan')

%%% kill the MP fields with collocation duration < X
kill = find( filt_MPcollocdurfullmcs_ALLYRS < 6 )  ;
    filt_MPVORTfullmcs_ALLYRS(kill) = NaN;
    filt_MPAREAfullmcs_ALLYRS(kill) = NaN;
    filt_MPSPEEDfullmcs_ALLYRS(kill) = NaN;
    filt_MPcollocdurfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanMUCAPEfullmcs_ALLYRS(kill) = NaN;
    filt_MPmaxMUCAPEfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanMUCINfullmcs_ALLYRS(kill) = NaN;
    filt_MPminMUCINfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanMULFCfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanMUELfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanPWfullmcs_ALLYRS(kill) = NaN;
    filt_MPmaxPWfullmcs_ALLYRS(kill) = NaN;
    filt_MPminPWfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanshearmag0to2fullmcs_ALLYRS(kill) = NaN;
    filt_MPmaxshearmag0to2fullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanshearmag0to6fullmcs_ALLYRS(kill) = NaN;
    filt_MPmaxshearmag0to6fullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanshearmag2to9fullmcs_ALLYRS(kill) = NaN;
    filt_MPmaxshearmag2to9fullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanOMEGA600fullmcs_ALLYRS(kill) = NaN;
    filt_MPminOMEGA600fullmcs_ALLYRS(kill) = NaN;
    filt_MPminOMEGAsub600fullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanVIWVDfullmcs_ALLYRS(kill) = NaN;
    filt_MPminVIWVDfullmcs_ALLYRS(kill) = NaN;
    filt_MPmaxVIWVDfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanDIV750fullmcs_ALLYRS(kill) = NaN;
    filt_MPminDIV750fullmcs_ALLYRS(kill) = NaN;
    filt_MPminDIVsub600fullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanWNDSPD600fullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanWNDDIR600fullmcs_ALLYRS(kill) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  NOW PLOT for events with MPs & MCSs collocated. I believe vars in are in MCSstats
%%%  space ( before they are 1D(:) converted)

%%%% MCS lifetime metrics
MCS_maxarea             = maxareapf_MCSstats_ALLYRS(:) ;
MCS_areagrowthrate      = dAdt_MCSstats_ALLYRSb(:) ;
MCS_meanspeed           = MCSspeed_MCSstats_ALLYRS(:) ;
MCS_totalrainmass       = totalrainmass_MCSstats_ALLYRSb(:) ;
MCS_HvyRainAccum        = pf_accumrainheavy_MCSstats_ALLYRSb(:)  ;
MCS_EchoTop50dBZ        = pf_ETH50_MCSstats_ALLYRSb(:)  ;
MCS_EchoTop30dBZ        = pf_ETH30_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainRate     = convrainrate_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainArea     = convrainarea_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainMass     = convrainmass_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainRate  = stratrainrate_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainArea  = stratrainarea_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainMass  = stratrainmass_MCSstats_ALLYRSb(:)  ;

%%%% mean MP metric while collocated with MCS
MP_vorticity          =  filt_MPVORTfullmcs_ALLYRS(:)   ;
MP_speed              =  filt_MPSPEEDfullmcs_ALLYRS(:)  ;
MP_area               =  filt_MPAREAfullmcs_ALLYRS(:)   ;
%MP_preMCSduration     =  filt_MPPREDURatMCSI_ALLYRS(:)  ;
MP_MCS_collocperiod       =  filt_MPcollocdurfullmcs_ALLYRS(:)  ;
%%%% MP env metric during MCS-MP colloc
MP_maxMUCAPE          =  filt_MPmaxMUCAPEfullmcs_ALLYRS ;
MP_minMUCIN           =  filt_MPminMUCINfullmcs_ALLYRS;
MP_meanMULFC          =  filt_MPmeanMULFCfullmcs_ALLYRS;
MP_meanMUEL           =  filt_MPmeanMUELfullmcs_ALLYRS ; 
MP_meanPW             =  filt_MPmeanPWfullmcs_ALLYRS;
MP_meanshearmag0to2   =  filt_MPmeanshearmag0to2fullmcs_ALLYRS ;
MP_meanshearmag0to6   =  filt_MPmeanshearmag0to6fullmcs_ALLYRS;
MP_meanshearmag2to9   =  filt_MPmeanshearmag2to9fullmcs_ALLYRS; 
MP_minOMEGA600        =  filt_MPminOMEGA600fullmcs_ALLYRS;
MP_minOMEGAsub600     =  filt_MPminOMEGAsub600fullmcs_ALLYRS ; 
MP_minDIV750          =  filt_MPminDIV750fullmcs_ALLYRS;
MP_minDIVsub600       =  filt_MPminDIVsub600fullmcs_ALLYRS;
MP_meanWNDSPD600      =  filt_MPmeanWNDSPD600fullmcs_ALLYRS;
MP_meanWNDDIR600      =  filt_MPmeanWNDDIR600fullmcs_ALLYRS ;

ALL_vars = {'MCS_maxarea' ;
    'MCS_areagrowthrate'  ;
    'MCS_meanspeed' ;
    'MCS_totalrainmass' ;
    'MCS_HvyRainAccum'  ;
    'MCS_EchoTop50dBZ'  ;
    'MCS_EchoTop30dBZ'  ;
    'MCS_ConvectRainRate' ;
    'MCS_ConvectRainArea' ;
    'MCS_ConvectRainMass' ;
    'MCS_StratiformRainRate' ;
    'MCS_StratiformRainArea' ;
    'MCS_StratiformRainMass' ;
    'MP_vorticity';
    'MP_speed';
    'MP_area';
    'MP_MCS_collocperiod'
    'MP_maxMUCAPE';
    'MP_minMUCIN';
    'MP_meanMULFC';
    'MP_meanMUEL';
    'MP_meanPW';
    'MP_meanshearmag0to2';
    'MP_meanshearmag0to6';
    'MP_meanshearmag2to9';
    'MP_minOMEGAsub600';
    'MP_minDIVsub600';
    'MP_meanWNDSPD600'};

ALL_vars = flipdim(ALL_vars,1) ;

ALL_corrs = zeros(length(ALL_vars),length(ALL_vars));     ALL_corrs(:) = NaN;
ALL_Ps = zeros(length(ALL_vars),length(ALL_vars));        ALL_Ps(:) = NaN;
ALL_statsig = zeros(length(ALL_vars),length(ALL_vars));        ALL_statsig(:) = NaN;
SIGTHRESH = 0.05;
for n = 1:length(ALL_vars)
    for m = 1:length(ALL_vars)
        %  n = 1; m = 3
        AA = char(ALL_vars(n)) ; 
        AA = eval(AA);
        BB = char(ALL_vars(m)) ;  
        BB = eval(BB);
        kill = isnan(BB);
        BB(kill) = []; AA(kill) = [];
        kill = isnan(AA);
        BB(kill) = []; AA(kill) = [];
        [corab, pval] = corrcoef(AA(:),BB(:)); corab = corab(2); pval = pval(2);
        ALL_corrs(n,m) = corab ;
        ALL_Ps(n,m) = pval;
        if(pval < SIGTHRESH)
            ALL_statsig(n,m) = NaN;
        else
            ALL_statsig(n,m) = 0;    
        end
    end
end
ALL_corrs = single(ALL_corrs);
isupper = logical(triu(ones(size(ALL_corrs)),1));
ALL_corrs(isupper) = NaN;
ALL_corrs(ALL_corrs >= 0.99999999999999999999999) = NaN;

ALL_statsig = single(ALL_statsig);
isupper = logical(triu(ones(size(ALL_statsig)),1));
ALL_statsig(isupper) = NaN;
ALL_statsig(ALL_statsig >= 0.99999999999999999999999) = NaN;

varlab = {};
for l = 1:length(ALL_vars)
   asd = char(ALL_vars(l,:) )   ;
   asd(find(asd=='_'))=' '   ;
   varlab = vertcat(varlab,asd);
end

dualpol_colmap
ff = figure('Position',[246,77,1187,900])
h = heatmap(ALL_corrs,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
h.NodeChildren(3).YDir='normal';
colormap(flipud(pepsi2))
caxis([-1 1])
h.XDisplayLabels = varlab;
h.YDisplayLabels = varlab;
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';
title('Correlogram - MCS lifetime stats, mean MP stats during MCS collocation (filters out LS, filters out PW < 24mm, longcolloc)')

saveas(h, horzcat(imout,'/Correlgram_MPcollocMCS_PWfilt_longcolloc.png') );
outlab = horzcat(imout,'/Correlgram_MPcollocMCS_PWfilt_longcolloc.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);


ff = figure('Position',[246,77,1187,900])
h = heatmap(ALL_statsig,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
h.NodeChildren(3).YDir='normal';
colormap(flipud(pepsi2))
caxis([-1 1])
h.XDisplayLabels = varlab;
h.YDisplayLabels = varlab;
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';
title('Correlogram - MCS lifetime stats, mean MP stats during MCS collocation (filters out LS, filters out PW < 24mm, longcolloc)')

saveas(h, horzcat(imout,'/Correlgram_MPcollocMCS_SIGMAP_PWfilt_longcolloc.png') );
outlab = horzcat(imout,'/Correlgram_MPcollocMCS_SIGMAP_PWfilt_longcolloc.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%% short collocation:


filt_MPVORTfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPVORTfullmcs_ALLYRS(:) = NaN ;         % magnitude of the max vorticity while syn obj touching mcs
filt_MPAREAfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      	 filt_MPAREAfullmcs_ALLYRS(:) = NaN ;         % area of vorticity while syn obj touching mcs
filt_MPSPEEDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;       filt_MPSPEEDfullmcs_ALLYRS(:) = NaN ;        % Syn obj speed while syn obj touching mcs
filt_MPcollocdurfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;   filt_MPcollocdurfullmcs_ALLYRS(:) = NaN ;       % collocation period of MCS-MP (if multiple MCSs per MP, use the longest collocation per MP?)
% MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     % duration of vorticity track prior to time of MCSI   % already defined above
% MPCOLLOCMCS_ALLYRS = zeros(mcs_tracks,mcs_years) ;    % Number of time steps post-mcsi with a syn obj present - already defined above

filt_MPmeanMUCAPEfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filt_MPmeanMUCAPEfullmcs_ALLYRS(:) = NaN ;
filt_MPmaxMUCAPEfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmaxMUCAPEfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanMUCINfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanMUCINfullmcs_ALLYRS(:) = NaN ;
filt_MPminMUCINfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPminMUCINfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanMULFCfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanMULFCfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanMUELfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPmeanMUELfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;               filt_MPmeanPWfullmcs_ALLYRS(:) = NaN ;
filt_MPmaxPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;                filt_MPmaxPWfullmcs_ALLYRS(:) = NaN ;
filt_MPminPWfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;                filt_MPminPWfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanshearmag0to2fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag0to2fullmcs_ALLYRS(:) = NaN ;
filt_MPmaxshearmag0to2fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag0to2fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanshearmag0to6fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag0to6fullmcs_ALLYRS(:) = NaN ;
filt_MPmaxshearmag0to6fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag0to6fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanshearmag2to9fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     filt_MPmeanshearmag2to9fullmcs_ALLYRS(:) = NaN ;
filt_MPmaxshearmag2to9fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      filt_MPmaxshearmag2to9fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanOMEGA600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPmeanOMEGA600fullmcs_ALLYRS(:) = NaN ;
filt_MPminOMEGA600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;          filt_MPminOMEGA600fullmcs_ALLYRS(:) = NaN ;
filt_MPminOMEGAsub600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;       filt_MPminOMEGAsub600fullmcs_ALLYRS(:) = NaN ; 
filt_MPmeanVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPmeanVIWVDfullmcs_ALLYRS(:) = NaN ;
filt_MPminVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPminVIWVDfullmcs_ALLYRS(:) = NaN ;
filt_MPmaxVIWVDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;             filt_MPmaxVIWVDfullmcs_ALLYRS(:) = NaN ;
filt_MPmeanDIV750fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;           filt_MPmeanDIV750fullmcs_ALLYRS(:) = NaN ;
filt_MPminDIV750fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;            filt_MPminDIV750fullmcs_ALLYRS(:) = NaN ;
filt_MPminDIVsub600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;         filt_MPminDIVsub600fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanWNDSPD600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPmeanWNDSPD600fullmcs_ALLYRS(:) = NaN ;
filt_MPmeanWNDDIR600fullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;        filt_MPmeanWNDDIR600fullmcs_ALLYRS(:) = NaN ;


%%% catalog these syn obj traits in MCS(tracks,years) space:
for y = 1:mcs_years
    for n = 1:mcs_tracks

        %   n = 79;  y = 2;  
        
        %t-indices in each MCS track where there is a syn present
        mpspresent = find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  ;
        
        if( isempty(mpspresent) == 0)

            %empty vars to hold mean/max metrics for each syn object that
            %you will later mean/max again to relate to MCSs:
            mps_vorts = [] ;
            mps_areas = [] ;
            mps_speeds = [] ;
            mps_colloc = [];
            meanMUCAPE = [] ;
            maxMUCAPE = [] ;
            meanMUCIN = [] ;
            minMUCIN = [] ;
            meanMULFC = [] ;
            meanMUEL = [] ;
            meanPW = [] ;
            maxPW = [] ;
            minPW = [] ;
            meanshearmag0to2 = [] ;
            maxshearmag0to2 = [] ;
            meanshearmag0to6 = [] ;
            maxshearmag0to6 = [] ;
            meanshearmag2to9 = [] ;
            maxshearmag2to9 = [] ;
            meanOMEGA600 = [] ;
            minOMEGA600 = [] ;
            minOMEGAsub600 = [] ;
            meanVIWVD = [] ;
            minVIWVD = [] ;
            maxVIWVD = [] ;
            meanDIV750 = [] ;
            minDIV750 = [] ;
            minDIVsub600 = [] ;
            meanWNDSPD600 = [] ;
            meanWNDDIR600 = [] ;
            collocdur = [];

            % diagnostic example:     y = 6; n = 80;
            % locate time and mp numbers corresponding to this MCS by referecing a masked/filtered PW/daytime MPstats list:
            found = find( filtPWDAYTIME_MCStracks_MPstats_ALLYRS(:,:,:,y) == n )  ;
            [tind_f,  mcsind_f,  mpind_f] = ind2sub(size(filtPWDAYTIME_MCStracks_MPstats_ALLYRS(:,:,:,y)),found) ;     clear found
            unimps = unique(mpind_f) ;
            colls = [];
            for mm = 1:length(unimps)
                colls = vertcat(colls,length(find(mpind_f==unimps(mm))));
            end
            %going to call the final MCS's MP collocation the mean of all of the MP collocations. Or does it make sense to do max? sum?  
            maxcoll = max(colls);
            collocdur = vertcat(collocdur, maxcoll );


            %all of the unique syn tracks in this MCS's full track:
            mpnums = unique(MPtracks_perMCS_ALLYRS(mpspresent,n,y)) ;
            
            %loop thru all of the syn objs overlapping the current MCS
            for s = 1:length(mpnums)
                
                %find MCS's time indices when current syn object is present, then
                %log the first & last time
                mp_mcst = find( MPtracks_perMCS_ALLYRS(:,n,y) == mpnums(s) )  ;
                mcst1 = basetime_MCSstats_ALLYRS(mp_mcst(1),n,y) ;
                mcst2 = basetime_MCSstats_ALLYRS(mp_mcst(end),n,y) ;
                
                %find the time indices in current syn obj's track corersponding to
                %the MCS overlap period:
                MPti1 = find( floor(mcst1/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;
                MPti2 = find( floor(mcst2/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;    

                % log the max/mean of the current syn obj's
                % characteristics during its overlap period with the MCS.
                % throw it into an array that contains the same for all
                % other syn obj's touching the current MCS:
                mps_vorts =  vertcat(mps_vorts, max( maxVOR600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;      %max vort of syn obj during its contact with MCS
                mps_areas =  vertcat(mps_areas, max( area_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )   ) ;          %max area of syn obj during its contact with MCS  
                mps_speeds = vertcat(mps_speeds, mean( MP_speeds_ALLYRS(MPti1:MPti2,mpnums(s),y) , 'omitnan')) ;  %mean speed of syn obj during its contact with MCS  

                maxMUCAPE           = vertcat( maxMUCAPE,        max(  maxMUCAPE_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanMUCIN           = vertcat( meanMUCIN,        min(  meanMUCIN_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minMUCIN            = vertcat( minMUCIN,         min(  minMUCIN_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanMULFC           = vertcat( meanMULFC,        min(  meanMULFC_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanMUEL            = vertcat( meanMUEL,         max(  meanMUEL_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanPW              = vertcat( meanPW,           max(  meanPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)           .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxPW               = vertcat( maxPW,            max(  maxPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)            .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minPW               = vertcat( minPW,            min(  minPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)            .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanshearmag0to2    = vertcat( meanshearmag0to2, max(  meanshearmag0to2_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxshearmag0to2     = vertcat( maxshearmag0to2,  max(  maxshearmag0to2_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)  .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanshearmag0to6    = vertcat( meanshearmag0to6, max(  meanshearmag0to6_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxshearmag0to6     = vertcat( maxshearmag0to6,  max(  maxshearmag0to6_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)  .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanshearmag2to9    = vertcat( meanshearmag2to9, max(  meanshearmag2to9_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxshearmag2to9     = vertcat( maxshearmag2to9,  max(  maxshearmag2to9_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)  .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanOMEGA600        = vertcat( meanOMEGA600,     min(  meanOMEGA600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)     .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minOMEGA600         = vertcat( minOMEGA600,      min(  minOMEGA600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)      .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minOMEGAsub600      = vertcat( minOMEGAsub600,   min(  minOMEGAsub600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)   .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanVIWVD           = vertcat( meanVIWVD,        max(  meanVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minVIWVD            = vertcat( minVIWVD,         min(  minVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                maxVIWVD            = vertcat( maxVIWVD,         max(  maxVIWVD_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)         .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanDIV750          = vertcat( meanDIV750,       min(  meanDIV750_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)       .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minDIV750           = vertcat( minDIV750,        min(  minDIV750_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)        .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                minDIVsub600        = vertcat( minDIVsub600,     min(  minDIVsub600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)     .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanWNDSPD600       = vertcat( meanWNDSPD600,    max(  meanWNDSPD600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)    .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), [] ,'omitnan' )  ) ;
                meanWNDDIR600       = vertcat( meanWNDDIR600,    mean(  meanWNDDIR600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y)   .* maskPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y), 'omitnan' )  ) ;
            end
            
            %  bla1 = maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(:,:,y)   ;
            %  bla2 =  maskPW_MPstats_ALLYRS(:,:,y)   ;
            %  bla3 = maskKEEPAFTERNOONEVENING_MPstats_ALLYRS(:,:,y)  .*  maskPW_MPstats_ALLYRS(:,:,y)   ;

            %end up with the means of all of the mean/max MP objs
            %characteristics across all syn objects touching the current MCS:
            filt_MPVORTfullmcs_ALLYRS(n,y)       =  mean( mps_vorts , 'omitnan');       
            filt_MPAREAfullmcs_ALLYRS(n,y)       =  mean( mps_areas , 'omitnan');
            filt_MPSPEEDfullmcs_ALLYRS(n,y)      =  mean( mps_speeds , 'omitnan');
            filt_MPcollocdurfullmcs_ALLYRS(n,y)  =  mean( collocdur , 'omitnan');

            filt_MPmeanMUCAPEfullmcs_ALLYRS(n,y)         =  mean( meanMUCAPE , 'omitnan'); 
            filt_MPmaxMUCAPEfullmcs_ALLYRS(n,y)          =  mean( maxMUCAPE , 'omitnan'); 
            filt_MPmeanMUCINfullmcs_ALLYRS(n,y)          =  mean( meanMUCIN , 'omitnan'); 
            filt_MPminMUCINfullmcs_ALLYRS(n,y)           =  mean( minMUCIN , 'omitnan'); 
            filt_MPmeanMULFCfullmcs_ALLYRS(n,y)          =  mean( meanMULFC , 'omitnan'); 
            filt_MPmeanMUELfullmcs_ALLYRS(n,y)           =  mean( meanMUEL , 'omitnan'); 
            filt_MPmeanPWfullmcs_ALLYRS(n,y)             =  mean( meanPW , 'omitnan'); 
            filt_MPmaxPWfullmcs_ALLYRS(n,y)              =  mean( maxPW , 'omitnan'); 
            filt_MPminPWfullmcs_ALLYRS(n,y)              =  mean( minPW , 'omitnan'); 
            filt_MPmeanshearmag0to2fullmcs_ALLYRS(n,y)   =  mean( meanshearmag0to2 , 'omitnan'); 
            filt_MPmaxshearmag0to2fullmcs_ALLYRS(n,y)    =  mean( maxshearmag0to2 , 'omitnan'); 
            filt_MPmeanshearmag0to6fullmcs_ALLYRS(n,y)   =  mean( meanshearmag0to6 , 'omitnan'); 
            filt_MPmaxshearmag0to6fullmcs_ALLYRS(n,y)    =  mean( maxshearmag0to6 , 'omitnan'); 
            filt_MPmeanshearmag2to9fullmcs_ALLYRS(n,y)   =  mean( meanshearmag2to9 , 'omitnan'); 
            filt_MPmaxshearmag2to9fullmcs_ALLYRS(n,y)    =  mean( maxshearmag2to9 , 'omitnan'); 
            filt_MPmeanOMEGA600fullmcs_ALLYRS(n,y)       =  mean( meanOMEGA600 , 'omitnan'); 
            filt_MPminOMEGA600fullmcs_ALLYRS(n,y)        =  mean( minOMEGA600 , 'omitnan'); 
            filt_MPminOMEGAsub600fullmcs_ALLYRS(n,y)     =  mean( minOMEGAsub600 , 'omitnan'); 
            filt_MPmeanVIWVDfullmcs_ALLYRS(n,y)          =  mean( meanVIWVD , 'omitnan'); 
            filt_MPminVIWVDfullmcs_ALLYRS(n,y)           =  mean( minVIWVD , 'omitnan'); 
            filt_MPmaxVIWVDfullmcs_ALLYRS(n,y)           =  mean( maxVIWVD , 'omitnan'); 
            filt_MPmeanDIV750fullmcs_ALLYRS(n,y)         =  mean( meanDIV750 , 'omitnan'); 
            filt_MPminDIV750fullmcs_ALLYRS(n,y)          =  mean( minDIV750 , 'omitnan'); 
            filt_MPminDIVsub600fullmcs_ALLYRS(n,y)       =  mean( minDIVsub600 , 'omitnan'); 
            filt_MPmeanWNDSPD600fullmcs_ALLYRS(n,y)      =  mean( meanWNDSPD600 , 'omitnan'); 
            filt_MPmeanWNDDIR600fullmcs_ALLYRS(n,y)      =  mean( meanWNDDIR600 , 'omitnan'); 

        end
    end
end          

%%% kill the MP fields with collocation duration < X
kill = find( filt_MPcollocdurfullmcs_ALLYRS > 5 )  ;
    filt_MPVORTfullmcs_ALLYRS(kill) = NaN;
    filt_MPAREAfullmcs_ALLYRS(kill) = NaN;
    filt_MPSPEEDfullmcs_ALLYRS(kill) = NaN;
    filt_MPcollocdurfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanMUCAPEfullmcs_ALLYRS(kill) = NaN;
    filt_MPmaxMUCAPEfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanMUCINfullmcs_ALLYRS(kill) = NaN;
    filt_MPminMUCINfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanMULFCfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanMUELfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanPWfullmcs_ALLYRS(kill) = NaN;
    filt_MPmaxPWfullmcs_ALLYRS(kill) = NaN;
    filt_MPminPWfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanshearmag0to2fullmcs_ALLYRS(kill) = NaN;
    filt_MPmaxshearmag0to2fullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanshearmag0to6fullmcs_ALLYRS(kill) = NaN;
    filt_MPmaxshearmag0to6fullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanshearmag2to9fullmcs_ALLYRS(kill) = NaN;
    filt_MPmaxshearmag2to9fullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanOMEGA600fullmcs_ALLYRS(kill) = NaN;
    filt_MPminOMEGA600fullmcs_ALLYRS(kill) = NaN;
    filt_MPminOMEGAsub600fullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanVIWVDfullmcs_ALLYRS(kill) = NaN;
    filt_MPminVIWVDfullmcs_ALLYRS(kill) = NaN;
    filt_MPmaxVIWVDfullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanDIV750fullmcs_ALLYRS(kill) = NaN;
    filt_MPminDIV750fullmcs_ALLYRS(kill) = NaN;
    filt_MPminDIVsub600fullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanWNDSPD600fullmcs_ALLYRS(kill) = NaN;
    filt_MPmeanWNDDIR600fullmcs_ALLYRS(kill) = NaN;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  NOW PLOT for events with MPs & MCSs collocated. I believe vars in are in MCSstats
%%%  space ( before they are 1D(:) converted)

%%%% MCS lifetime metrics
MCS_maxarea             = maxareapf_MCSstats_ALLYRS(:) ;
MCS_areagrowthrate      = dAdt_MCSstats_ALLYRSb(:) ;
MCS_meanspeed           = MCSspeed_MCSstats_ALLYRS(:) ;
MCS_totalrainmass       = totalrainmass_MCSstats_ALLYRSb(:) ;
MCS_HvyRainAccum        = pf_accumrainheavy_MCSstats_ALLYRSb(:)  ;
MCS_EchoTop50dBZ        = pf_ETH50_MCSstats_ALLYRSb(:)  ;
MCS_EchoTop30dBZ        = pf_ETH30_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainRate     = convrainrate_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainArea     = convrainarea_MCSstats_ALLYRSb(:)  ;
MCS_ConvectRainMass     = convrainmass_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainRate  = stratrainrate_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainArea  = stratrainarea_MCSstats_ALLYRSb(:)  ;
MCS_StratiformRainMass  = stratrainmass_MCSstats_ALLYRSb(:)  ;

%%%% mean MP metric while collocated with MCS
MP_vorticity          =  filt_MPVORTfullmcs_ALLYRS(:)   ;
MP_speed              =  filt_MPSPEEDfullmcs_ALLYRS(:)  ;
MP_area               =  filt_MPAREAfullmcs_ALLYRS(:)   ;
%MP_preMCSduration     =  filt_MPPREDURatMCSI_ALLYRS(:)  ;
MP_MCS_collocperiod       =  filt_MPcollocdurfullmcs_ALLYRS(:)  ;
%%%% MP env metric during MCS-MP colloc
MP_maxMUCAPE          =  filt_MPmaxMUCAPEfullmcs_ALLYRS ;
MP_minMUCIN           =  filt_MPminMUCINfullmcs_ALLYRS;
MP_meanMULFC          =  filt_MPmeanMULFCfullmcs_ALLYRS;
MP_meanMUEL           =  filt_MPmeanMUELfullmcs_ALLYRS ; 
MP_meanPW             =  filt_MPmeanPWfullmcs_ALLYRS;
MP_meanshearmag0to2   =  filt_MPmeanshearmag0to2fullmcs_ALLYRS ;
MP_meanshearmag0to6   =  filt_MPmeanshearmag0to6fullmcs_ALLYRS;
MP_meanshearmag2to9   =  filt_MPmeanshearmag2to9fullmcs_ALLYRS; 
MP_minOMEGA600        =  filt_MPminOMEGA600fullmcs_ALLYRS;
MP_minOMEGAsub600     =  filt_MPminOMEGAsub600fullmcs_ALLYRS ; 
MP_minDIV750          =  filt_MPminDIV750fullmcs_ALLYRS;
MP_minDIVsub600       =  filt_MPminDIVsub600fullmcs_ALLYRS;
MP_meanWNDSPD600      =  filt_MPmeanWNDSPD600fullmcs_ALLYRS;
MP_meanWNDDIR600      =  filt_MPmeanWNDDIR600fullmcs_ALLYRS ;

ALL_vars = {'MCS_maxarea' ;
    'MCS_areagrowthrate'  ;
    'MCS_meanspeed' ;
    'MCS_totalrainmass' ;
    'MCS_HvyRainAccum'  ;
    'MCS_EchoTop50dBZ'  ;
    'MCS_EchoTop30dBZ'  ;
    'MCS_ConvectRainRate' ;
    'MCS_ConvectRainArea' ;
    'MCS_ConvectRainMass' ;
    'MCS_StratiformRainRate' ;
    'MCS_StratiformRainArea' ;
    'MCS_StratiformRainMass' ;
    'MP_vorticity';
    'MP_speed';
    'MP_area';
    'MP_MCS_collocperiod'
    'MP_maxMUCAPE';
    'MP_minMUCIN';
    'MP_meanMULFC';
    'MP_meanMUEL';
    'MP_meanPW';
    'MP_meanshearmag0to2';
    'MP_meanshearmag0to6';
    'MP_meanshearmag2to9';
    'MP_minOMEGAsub600';
    'MP_minDIVsub600';
    'MP_meanWNDSPD600'};

ALL_vars = flipdim(ALL_vars,1) ;

ALL_corrs = zeros(length(ALL_vars),length(ALL_vars));     ALL_corrs(:) = NaN;
ALL_Ps = zeros(length(ALL_vars),length(ALL_vars));        ALL_Ps(:) = NaN;
ALL_statsig = zeros(length(ALL_vars),length(ALL_vars));        ALL_statsig(:) = NaN;
SIGTHRESH = 0.05;
for n = 1:length(ALL_vars)
    for m = 1:length(ALL_vars)
        %  n = 1; m = 3
        AA = char(ALL_vars(n)) ; 
        AA = eval(AA);
        BB = char(ALL_vars(m)) ;  
        BB = eval(BB);
        kill = isnan(BB);
        BB(kill) = []; AA(kill) = [];
        kill = isnan(AA);
        BB(kill) = []; AA(kill) = [];
        [corab, pval] = corrcoef(AA(:),BB(:)); corab = corab(2); pval = pval(2);
        ALL_corrs(n,m) = corab ;
        ALL_Ps(n,m) = pval;
        if(pval < SIGTHRESH)
            ALL_statsig(n,m) = NaN;
        else
            ALL_statsig(n,m) = 0;    
        end
    end
end
ALL_corrs = single(ALL_corrs);
isupper = logical(triu(ones(size(ALL_corrs)),1));
ALL_corrs(isupper) = NaN;
ALL_corrs(ALL_corrs >= 0.99999999999999999999999) = NaN;

ALL_statsig = single(ALL_statsig);
isupper = logical(triu(ones(size(ALL_statsig)),1));
ALL_statsig(isupper) = NaN;
ALL_statsig(ALL_statsig >= 0.99999999999999999999999) = NaN;

varlab = {};
for l = 1:length(ALL_vars)
   asd = char(ALL_vars(l,:) )   ;
   asd(find(asd=='_'))=' '   ;
   varlab = vertcat(varlab,asd);
end

dualpol_colmap
ff = figure('Position',[246,77,1187,900])
h = heatmap(ALL_corrs,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
h.NodeChildren(3).YDir='normal';
colormap(flipud(pepsi2))
caxis([-1 1])
h.XDisplayLabels = varlab;
h.YDisplayLabels = varlab;
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';
title('Correlogram - MCS lifetime stats, mean MP stats during MCS collocation (filters out LS, filters out PW < 24mm, shortcolloc)')

saveas(h, horzcat(imout,'/Correlgram_MPcollocMCS_PWfilt_shortcolloc.png') );
outlab = horzcat(imout,'/Correlgram_MPcollocMCS_PWfilt_shortcolloc.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);


ff = figure('Position',[246,77,1187,900])
h = heatmap(ALL_statsig,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
h.NodeChildren(3).YDir='normal';
colormap(flipud(pepsi2))
caxis([-1 1])
h.XDisplayLabels = varlab;
h.YDisplayLabels = varlab;
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';
title('Correlogram - MCS lifetime stats, mean MP stats during MCS collocation (filters out LS, filters out PW < 24mm, shortcolloc)')

saveas(h, horzcat(imout,'/Correlgram_MPcollocMCS_SIGMAP_PWfilt_shortcolloc.png') );
outlab = horzcat(imout,'/Correlgram_MPcollocMCS_SIGMAP_PWfilt_shortcolloc.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);



%}












%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%
%%%%%%%%    correlogram of MP traits for all times of MPs that touch an MCS
%%%%%%%%    at anytime
%%%%%%%%    
%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%
%%%   Now calc the 2D histograms of MP obj properties throughout MCS
%%%   lifetime (while they are collocated) rather than just the MP obj 
%%%   properties @ time of MCSI - filtered versions

%%%% For MCSs with a SYN obj present at any time throughout its life: 

%notes (May 13 2024): The MPstats metrics (that are converted to [mcsnum,year] space below)
%                     are now hit with the PW & DAYTIME masks made above.
%                     The MCS metrics themselves are NOT filtered becasue
%                     that is more complicated than my ADHD brain can
%                     handle right now. however, when you're looking at the MP-MCS relationships, 
%                     the MP-filtered fields will take care of this. So
%                     MCS-MCS relationships dont have this filter, but I
%                     think that's ok because I am not really looking at
%                     these (and they may not need to be filtered anyway?)


%convert MP_with_MCSs to an MPstats mask
mask_MPtouchingMCS_MPstats = area_MPstats_ALLYRS;    mask_MPtouchingMCS_MPstats(:)= NaN;
[qw qe] = size(MP_with_MCSs_ALLYRS)  ;
for y = 1:yr
    for m = 1:qw
        mp = MP_with_MCSs_ALLYRS(m,y);
        if(isnan(mp)==0)
            mask_MPtouchingMCS_MPstats(:,mp,y) = 1;
        end
    end
end
mblah = mask_MPtouchingMCS_MPstats(:,:,1);




filt_duration_MPstats_ALLYRS  = duration_MPstats_ALLYRS  .*  permute(maskPW_MPstats_ALLYRS(1,:,:),[2 3 1]) .* permute(mask_MPtouchingMCS_MPstats(1,:,:),[2 3 1]) ; 
filt_area_MPstats_ALLYRS      = area_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_maxVOR600_MPstats_ALLYRS = maxVOR600_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ;  

MPspeed_MPstats_ALLYRS = (MotionX_MPstats_ALLYRS .* MotionX_MPstats_ALLYRS + MotionY_MPstats_ALLYRS .* MotionY_MPstats_ALLYRS).^0.5;
filt_MPspeed_MPstats_ALLYRS = MPspeed_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ;   

%MPenvs
filt_meanMUCAPE_MPstats_ALLYRS =  meanMUCAPE_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_maxMUCAPE_MPstats_ALLYRS =   maxMUCAPE_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_meanMUCIN_MPstats_ALLYRS =   meanMUCIN_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_minMUCIN_MPstats_ALLYRS =    minMUCIN_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_meanMULFC_MPstats_ALLYRS =   meanMULFC_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_meanMUEL_MPstats_ALLYRS =    meanMUEL_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_meanPW_MPstats_ALLYRS =      meanPW_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_maxPW_MPstats_ALLYRS =       maxPW_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_minPW_MPstats_ALLYRS =       minPW_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_meanshearmag0to2_MPstats_ALLYRS =   meanshearmag0to2_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_maxshearmag0to2_MPstats_ALLYRS =    maxshearmag0to2_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_meanshearmag0to6_MPstats_ALLYRS =   meanshearmag0to6_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_maxshearmag0to6_MPstats_ALLYRS =    maxshearmag0to6_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_meanshearmag2to9_MPstats_ALLYRS =   meanshearmag2to9_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_maxshearmag2to9_MPstats_ALLYRS =    maxshearmag2to9_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_meanOMEGA600_MPstats_ALLYRS =       meanOMEGA600_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_minOMEGA600_MPstats_ALLYRS =        minOMEGA600_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_minOMEGAsub600_MPstats_ALLYRS =     minOMEGAsub600_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_meanVIWVD_MPstats_ALLYRS =          meanVIWVD_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_minVIWVD_MPstats_ALLYRS =           minVIWVD_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_maxVIWVD_MPstats_ALLYRS =           maxVIWVD_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_meanDIV750_MPstats_ALLYRS =         meanDIV750_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_minDIV750_MPstats_ALLYRS =          minDIV750_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_minDIVsub600_MPstats_ALLYRS =       minDIVsub600_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_meanWNDSPD600_MPstats_ALLYRS =      meanWNDSPD600_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 
filt_meanWNDDIR600_MPstats_ALLYRS =      meanWNDDIR600_MPstats_ALLYRS  .*  maskPW_MPstats_ALLYRS .* mask_MPtouchingMCS_MPstats ; 

%take more min/max/mean for one value per MP
%filt_duration_MPstats_ALLYRS    =            
filt_area_MPstats_ALLYRS        =  permute( max( filt_area_MPstats_ALLYRS,[], 1,'omitnan' ) ,  [2 3 1] )        ;
filt_maxVOR600_MPstats_ALLYRS   =  permute( max( filt_maxVOR600_MPstats_ALLYRS,[], 1,'omitnan' ) ,  [2 3 1] )        ;
filt_MPspeed_MPstats_ALLYRS     =  permute(mean( filt_MPspeed_MPstats_ALLYRS, 1,'omitnan') ,  [2 3 1] )        ;
filt_meanMUCAPE_MPstats_ALLYRS  =  permute( max( filt_meanMUCAPE_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;
filt_maxMUCAPE_MPstats_ALLYRS   =  permute( max( filt_maxMUCAPE_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;
filt_meanMUCIN_MPstats_ALLYRS   =  permute( min( filt_meanMUCIN_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;
filt_minMUCIN_MPstats_ALLYRS    =  permute( min( filt_minMUCIN_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;
filt_meanMULFC_MPstats_ALLYRS   =  permute( mean( filt_meanMULFC_MPstats_ALLYRS, 1,'omitnan' ),  [2 3 1] )        ;
filt_meanMUEL_MPstats_ALLYRS    =  permute( mean( filt_meanMUEL_MPstats_ALLYRS, 1,'omitnan' ),  [2 3 1] )        ; 
filt_meanPW_MPstats_ALLYRS           = permute( mean( filt_meanPW_MPstats_ALLYRS, 1,'omitnan' ),  [2 3 1] )        ; 
filt_maxPW_MPstats_ALLYRS            = permute( max( filt_maxPW_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;
filt_minPW_MPstats_ALLYRS            = permute( min( filt_minPW_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;
filt_meanshearmag0to2_MPstats_ALLYRS = permute( mean( filt_meanshearmag0to2_MPstats_ALLYRS, 1,'omitnan' ),  [2 3 1] )        ; 
filt_maxshearmag0to2_MPstats_ALLYRS  = permute( max( filt_maxshearmag0to2_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;
filt_meanshearmag0to6_MPstats_ALLYRS = permute( mean( filt_meanshearmag0to6_MPstats_ALLYRS, 1,'omitnan' ),  [2 3 1] )        ;
filt_maxshearmag0to6_MPstats_ALLYRS  = permute( max( filt_maxshearmag0to6_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;
filt_meanshearmag2to9_MPstats_ALLYRS = permute( mean( filt_meanshearmag2to9_MPstats_ALLYRS, 1,'omitnan' ),  [2 3 1] )        ; 
filt_maxshearmag2to9_MPstats_ALLYRS  = permute( max( filt_maxshearmag2to9_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;
filt_meanOMEGA600_MPstats_ALLYRS     = permute( mean( filt_meanOMEGA600_MPstats_ALLYRS, 1,'omitnan' ),  [2 3 1] )        ;   
filt_minOMEGA600_MPstats_ALLYRS      = permute( min( filt_minOMEGA600_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;   
filt_minOMEGAsub600_MPstats_ALLYRS   = permute( min( filt_minOMEGAsub600_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ; 
filt_meanVIWVD_MPstats_ALLYRS        = permute( mean( filt_meanVIWVD_MPstats_ALLYRS, 1,'omitnan' ),  [2 3 1] )        ;  
filt_minVIWVD_MPstats_ALLYRS         = permute( min( filt_minVIWVD_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;    
filt_maxVIWVD_MPstats_ALLYRS         = permute( max( filt_maxVIWVD_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;     
filt_meanDIV750_MPstats_ALLYRS       = permute( mean( filt_meanDIV750_MPstats_ALLYRS, 1,'omitnan' ),  [2 3 1] )        ;     
filt_minDIV750_MPstats_ALLYRS        = permute( min( filt_minDIV750_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;     
filt_minDIVsub600_MPstats_ALLYRS     = permute( min( filt_minDIVsub600_MPstats_ALLYRS,[], 1,'omitnan' ),  [2 3 1] )        ;    
filt_meanWNDSPD600_MPstats_ALLYRS    = permute( mean( filt_meanWNDSPD600_MPstats_ALLYRS, 1,'omitnan' ),  [2 3 1] )        ;   
filt_meanWNDDIR600_MPstats_ALLYRS    = permute( mean( filt_meanWNDDIR600_MPstats_ALLYRS, 1,'omitnan' ),  [2 3 1] )        ;      


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%  NOW PLOT for events with MPs & MCSs collocated. I believe vars in are in MCSstats
%%%  space ( before they are 1D(:) converted)


%%%% mean MP metric while collocated with MCS
MP_duration           =  filt_duration_MPstats_ALLYRS(:) ; 
MP_vorticity          =  filt_maxVOR600_MPstats_ALLYRS(:)   ;
MP_speed              =  filt_MPspeed_MPstats_ALLYRS(:)  ;
MP_area               =  filt_area_MPstats_ALLYRS(:)   ;
%MP_preMCSduration     =  filt_MPPREDURatMCSI_ALLYRS(:)  ;
%MP_MCS_collocperiod       =  filt_MPcollocdurfullmcs_ALLYRS(:)  ;

%%%% MP env metric during MCS-MP colloc
MP_maxMUCAPE          =  filt_maxMUCAPE_MPstats_ALLYRS ;
MP_minMUCIN           =  filt_minMUCIN_MPstats_ALLYRS  ;
MP_meanMULFC          =  filt_meanMULFC_MPstats_ALLYRS ;
MP_meanMUEL           =  filt_meanMUEL_MPstats_ALLYRS  ; 
MP_meanPW             =  filt_meanPW_MPstats_ALLYRS    ;
MP_meanshearmag0to2   =  filt_meanshearmag0to2_MPstats_ALLYRS ;
MP_meanshearmag0to6   =  filt_meanshearmag0to6_MPstats_ALLYRS ;
MP_meanshearmag2to9   =  filt_meanshearmag2to9_MPstats_ALLYRS ; 
MP_minOMEGAsub600     =  filt_minOMEGAsub600_MPstats_ALLYRS   ;
MP_minDIVsub600       =  filt_minDIVsub600_MPstats_ALLYRS     ;
MP_meanWNDSPD600      =  filt_meanWNDSPD600_MPstats_ALLYRS    ;

ALL_vars = {'MP_vorticity';
    'MP_speed';
    'MP_area';
    'MP_duration'
    'MP_maxMUCAPE';
    'MP_minMUCIN';
    'MP_meanMULFC';
    'MP_meanMUEL';
    'MP_meanPW';
    'MP_meanshearmag0to2';
    'MP_meanshearmag0to6';
    'MP_meanshearmag2to9';
    'MP_minOMEGAsub600';
    'MP_minDIVsub600';
    'MP_meanWNDSPD600'};

ALL_vars = flipdim(ALL_vars,1) ;

ALL_corrs = zeros(length(ALL_vars),length(ALL_vars));     ALL_corrs(:) = NaN;
ALL_Ps = zeros(length(ALL_vars),length(ALL_vars));        ALL_Ps(:) = NaN;
ALL_statsig = zeros(length(ALL_vars),length(ALL_vars));        ALL_statsig(:) = NaN;
SIGTHRESH = 0.05;
for n = 1:length(ALL_vars)
    for m = 1:length(ALL_vars)
        %  n = 1; m = 3
        AA = char(ALL_vars(n)) ; 
        AA = eval(AA);
        BB = char(ALL_vars(m)) ;  
        BB = eval(BB);
        kill = isnan(BB);
        BB(kill) = []; AA(kill) = [];
        kill = isnan(AA);
        BB(kill) = []; AA(kill) = [];
        [corab, pval] = corrcoef(AA(:),BB(:)); corab = corab(2); pval = pval(2);
        ALL_corrs(n,m) = corab ;
        ALL_Ps(n,m) = pval;
        if(pval < SIGTHRESH)
            ALL_statsig(n,m) = NaN;
        else
            ALL_corrs(n,m) = NaN;
            ALL_statsig(n,m) = 0; %0;    
        end
    end
end
ALL_corrs = single(ALL_corrs);
isupper = logical(triu(ones(size(ALL_corrs)),1));
ALL_corrs(isupper) = NaN;
ALL_corrs(ALL_corrs >= 0.99999999999999999999999) = NaN;

ALL_statsig = single(ALL_statsig);
isupper = logical(triu(ones(size(ALL_statsig)),1));
ALL_statsig(isupper) = NaN;
ALL_statsig(ALL_statsig >= 0.99999999999999999999999) = NaN;

varlab = {};
for l = 1:length(ALL_vars)
   asd = char(ALL_vars(l,:) )   ;
   asd(find(asd=='_'))=' '   ;
   varlab = vertcat(varlab,asd);
end

ALL_corrs = round(ALL_corrs,2);

dualpol_colmap
ff = figure('Position',[175,78,661,515])
h = heatmap(ALL_corrs,'MissingDataColor',[1 1 1]);  %[0.4 0.8 0.4]);
h.NodeChildren(3).YDir='normal';
colormap(flipud(pepsi2))
caxis([-1 1])
h.XDisplayLabels = varlab;
h.YDisplayLabels = varlab;
ax = gca;
axp = struct(ax);       %you will get a warning
axp.Axes.XAxisLocation = 'top';
title(['Correlogram -  MP stats during MP lifetime (only for MPs touching MCS at anytime, PW>24mm)',keptmonslab])

%saveas(h, horzcat(imout,'/Correlgram_MPfulllife_MPtraits.png') );
outlab = horzcat(imout,'/Correlgram_MPfulllife_MPtraits','_',keptmonslab,'.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);








% done, dont proceed past this point





%{



































%is this where the old stuff begins?


















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%         
%%%             2D histograms relating MCS and MP obj characteristics       
%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


MP_speeds_ALLYRS = (  MotionX_MPstats_ALLYRS.*MotionX_MPstats_ALLYRS +   MotionY_MPstats_ALLYRS.*MotionY_MPstats_ALLYRS ).^0.5   ;



%%%% For MCSs with a MP obj present at MCSI: 

MPVORTatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;       	MPVORTatMCSI_ALLYRS(:) = NaN ;         % magnitude of the vorticity at time of MCSI
%   MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;                                              % duration of vorticity track prior to time of MCSI   % already defined above
MPAREAatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;      	MPAREAatMCSI_ALLYRS(:) = NaN ;         % area of vorticity at time of MCSI
MPCOLLOCMCS_ALLYRS = zeros(mcs_tracks,mcs_years) ;         MPCOLLOCMCS_ALLYRS(:) = NaN ;    % Number of time steps post-mcsi with a syn obj present 
MPSPEEDatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;       MPSPEEDatMCSI_ALLYRS(:) = NaN ;    % MP obj speed at time of MCSI

%%% catalog these syn obj traits in MCS(tracks,years) space:
for y = 1:mcs_years
    for n = 1:mcs_tracks
        
        %  y = 1; n = 74;     y = 15; n = 317;
        %  blah = mcsibasetime_perMCS_ALLYRS(1:2,n,y) ;
        %  blah_yymmddhhmmss = datetime(blah, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;
        
        tmp = length(  find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  )  ;  %num of time in MCS with an MP
        MPCOLLOCMCS_ALLYRS(n,y) = tmp  ;  % NOTE: this includes all syn objs, not only the one(s) presnt during mcsi period
        
        % syn obj characteristics for syn present @ MCSI events:
        if(    isnan( MCSI_with_MP_ALLYRS(n,y) ) == 0    )
            
            %time of MCSI (defined well above)
            MCSItime = mcsibasetime_perMCS_ALLYRS(1:2,n,y) ;
            %the syn object present at MCSI
            mpobj = MCSI_with_MP_ALLYRS(n,y) ;
            
            if( isnan(mpobj)==0 )

                    %    basetime_MPstats_met_yymmddhhmmss_ALLYRS(:,mpobj,y)

                    %to account for mp obj present at second time in MCSI period but not first (since we are letting MCSI period be t = 1:2:
                    MPt1 = find( floor(basetime_MPstats_ALLYRS(:,mpobj,y)/100)  ==  floor(MCSItime(1)/100) )  ;
                    MPt2 = find( floor(basetime_MPstats_ALLYRS(:,mpobj,y)/100)  ==  floor(MCSItime(2)/100) )  ;
                    % time in syn obj's record when MCSI happens:
                    MPt = vertcat(MPt1,MPt2) ;  MPt = MPt(1);
                    
                    %populate the syn obj metrics of interest:
                    MPVORTatMCSI_ALLYRS(n,y) = maxVOR600_MPstats_ALLYRS(MPt,mpobj,y)  ;
                    MPAREAatMCSI_ALLYRS(n,y) = area_MPstats_ALLYRS(MPt,mpobj,y)  ;
                    % MPPREDURatMCSI_ALLYRS -  already cataloged above
                    %tmp = length(  find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  )  ;
                    %MPCOLLOCMCS_ALLYRS(n,y) = tmp  ;  % NOTE: this includes all syn objs, not only the one(s) presnt during mcsi period
                    MPSPEEDatMCSI_ALLYRS(n,y) =  (  MotionX_MPstats_ALLYRS(MPt,mpobj,y) .* MotionX_MPstats_ALLYRS(MPt,mpobj,y) +   MotionY_MPstats_ALLYRS(MPt,mpobj,y).*MotionY_MPstats_ALLYRS(MPt,mpobj,y) ).^0.5   ;
                    
            end
            
        end 
    end
end
MPCOLLOCMCS_ALLYRS(MPCOLLOCMCS_ALLYRS==0) = NaN;

length( find(MPCOLLOCMCS_ALLYRS > 0) )


ctop = 15;

dualpol_colmap

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%       MP obj characteristics @ MCSI      vs ...   MCS lifetime mean speed
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


ff = figure  
ff.Position = [163,283,1717,350];

sgtitle('MP characteristics @ MCSI vs MCS lifetime characteristics')

subplot(1,4,1)

AA = MPVORTatMCSI_ALLYRS(:);        % x-axis
BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis
AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 

plot(polyshape([0 0 5 5],[0 100 100 0]))
hold on
grid on
binwidths = [3*10^-6,2];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(flipud(creamsicle2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP |Vorticity|  [1/s]')
ylabel(' Mean MCS speed throughout MCS lifetime [m/s]')
xticks([3*10^-5:binwidths(1)*2:10^-4])
yticks([0:binwidths(2)*2:50])
axis([3*10^-5 10^-4 0 50])



subplot(1,4,2)

AA = MPSPEEDatMCSI_ALLYRS(:);        % x-axis
BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 100000 100000],[0 100000 100000 0]))
hold on
grid on
binwidths = [2,2];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(flipud(creamsicle2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP feature speed [m/s]')
ylabel(' Mean MCS speed [m/s]')
xticks([0:binwidths(1)*2:50])
yticks([0:binwidths(2)*2:50])
axis([0 50 0 50])



subplot(1,4,3)

AA = MPAREAatMCSI_ALLYRS(:);        % x-axis
BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [50000,2];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(flipud(creamsicle2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,'; cor coeff = ', num2str(ccr) ] )
xlabel(' MP feature area  [km^2]')
ylabel(' Mean MCS speed [m/s]')
xticks([0:binwidths(1)*2:10*10^5])
yticks([0:binwidths(2)*2:50])
axis([0 10*10^5 0 50])



subplot(1,4,4)

AA = MPPREDURatMCSI_ALLYRS(:);        % x-axis
BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [6,2];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(flipud(creamsicle2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn prior to MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,'; cor coeff = ', num2str(ccr) ] )
xlabel(' MP features'' duration prior to MCSI [hrs]')
ylabel(' Mean MCS speed throughout MCS lifetime [m/s]')
xticks([0:binwidths(1)*2:110])
yticks([0:binwidths(2)*2:50])
axis([0 110 0 50])


% subplot(1,5,5)
% 
% AA = MPCOLLOCMCS_ALLYRS(:);        % x-axis
% BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis
% 
% AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
% plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
% hold on
% grid on
% binwidths = [6,2];
% histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% % histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(flipud(creamsicle2))
% caxis([0 ctop])
% colorbar
% view(0,90)
% ccr = corrcoef(AA,BB); ccr = ccr(2);
% subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
% xlabel(' Collective time Synoptic & MCS objects are located (throughout MCS lifetime) [hrs]')
% ylabel(' Mean MCS speed throughout MCS lifetime')
% xticks([0:binwidths(1)*2:110])
% yticks([0:binwidths(2)*2:50])
% axis([0 110 0 50])

title([' MCSs lifetime mean speed '])


%saveas(ff,horzcat(imout,'/hist2d_MCSspeed.png'));
outlab = horzcat(imout,'/hist2d_MPatMCSI_MCSspeed.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%       MP obj characteristics @ MCSI      vs ...   MCS max area
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ctop = 15;
dualpol_colmap

ff = figure  
ff.Position = [163,283,1717,350];

sgtitle('MP characteristics @ MCSI vs MCS lifetime characteristics')

subplot(1,4,1)

AA = MPVORTatMCSI_ALLYRS(:);        % x-axis
BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis
AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 

plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [6*10^-6, 10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((purpley2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,'; cor coeff = ', num2str(ccr) ] )
xlabel(' MP |Vorticity|  [1/s]')
ylabel(' Max MCS total PF area [km^2]')
xticks([3*10^-5 : binwidths(1)*4 : 10^-3])
yticks([0:binwidths(2)*2:250000])
axis([3*10^-5 1.5*10^-4 0 250000])



subplot(1,4,2)

AA = MPSPEEDatMCSI_ALLYRS(:);        % x-axis
BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [2, 10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((purpley2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,'; cor coeff = ', num2str(ccr) ] )
xlabel(' MP speed [m/s]')
ylabel(' Max MCS total PF area [km^2]')
xticks([0:binwidths(1)*2:50])
yticks([0:binwidths(2)*2:250000])
axis([0 50 0 250000])



subplot(1,4,3)

AA = MPAREAatMCSI_ALLYRS(:);        % x-axis
BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [50000, 10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((purpley2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,'; cor coeff = ', num2str(ccr) ] )
xlabel(' MP area [km^2]')
ylabel(' Max MCS total PF area [km^2]')
xticks([0:binwidths(1)*2:10*10^5])
yticks([0:binwidths(2)*2:250000])
axis([0 10*10^5 0 250000])



subplot(1,4,4)

AA = MPPREDURatMCSI_ALLYRS(:);        % x-axis
BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [6, 10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((purpley2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn prior to MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,'; cor coeff = ', num2str(ccr) ] )
xlabel(' MP duration prior to MCSI [hrs]')
ylabel(' Max MCS total PF area [km^2]')
xticks([0:binwidths(1)*2:110])
yticks([0:binwidths(2)*2:250000])
axis([0 110 0 250000])




% subplot(1,5,5)
% 
% AA = MPCOLLOCMCS_ALLYRS(:);        % x-axis
% BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis
% 
% AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
% plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
% hold on
% grid on
% binwidths = [6, 10000];
% histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% % histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(flipud(creamsicle2))
% caxis([0 ctop])
% colorbar
% view(0,90)
% ccr = corrcoef(AA,BB); ccr = ccr(2);
% subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
% xlabel(' Collective time Synoptic & MCS objects are located (throughout MCS lifetime) [hrs]')
% ylabel(' Max MCS total PF area throughout MCS lifetime [km^2]')
% xticks([0:binwidths(1)*2:110])
% yticks([0:binwidths(2)*2:250000])
% axis([0 110 0 250000])

title([' MCSs lifetime max precip area '])

%saveas(ff,horzcat(imout,'/hist2d_MCSmaxpreciparea.png'));
outlab = horzcat(imout,'/hist2d_MPatMCSI_MCSmaxpreciparea.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);










%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%       MP obj characteristics @ MCSI      vs ...   MCS total rain mass
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ctop = 35;
dualpol_colmap

ff = figure  
ff.Position = [163,283,1717,350];


subplot(1,4,1)

AA = MPVORTatMCSI_ALLYRS(:);        % x-axis
BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis
AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 

plot(polyshape([0 0 1000000000000000000 1000000000000000000],[0 1000000000000000000 1000000000000000000 0]))
hold on
grid on
binwidths = [6*10^-6, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((peppermint2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP feature |Vorticity| [1/s]')
ylabel(' Max MCS total PF rain mass [kg]')
yticks([0:binwidths(2)*2:10^14])
xticks([3*10^-5 : binwidths(1)*4 : 10^-3])
axis([3*10^-5 1.5*10^-4 0 5*10^13])



subplot(1,4,2)

AA = MPSPEEDatMCSI_ALLYRS(:);        % x-axis
BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000000000000000 1000000000000000000],[0 1000000000000000000 1000000000000000000 0]))
hold on
grid on
binwidths = [2, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((peppermint2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP feature speed [m/s]')
ylabel(' Max MCS total PF rain mass [kg]')
xticks([0:binwidths(1)*2:50])
yticks([0:binwidths(2)*2:10^14])
axis([0 50 0 5*10^13])



subplot(1,4,3)

AA = MPAREAatMCSI_ALLYRS(:);        % x-axis
BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000000000000000 1000000000000000000],[0 1000000000000000000 1000000000000000000 0]))
hold on
grid on
binwidths = [50000, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((peppermint2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP feature area [km^2]')
ylabel(' Max MCS total PF rain mass [kg]')
xticks([0:binwidths(1)*2:10*10^5])
yticks([0:binwidths(2)*2:10^14])
axis([0 10*10^5 0 5*10^13])



subplot(1,4,4)

AA = MPPREDURatMCSI_ALLYRS(:);        % x-axis
BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 10000000000000000 10000000000000000],[0 10000000000000000 10000000000000000 0]))
hold on
grid on
binwidths = [6, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((peppermint2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn prior to MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP features'' duration prior to MCSI [hrs]')
ylabel(' Max MCS total PF rain mass [kg]')
xticks([0:binwidths(1)*2:110])
yticks([0:binwidths(2)*2:10^14])
axis([0 110 0 5*10^13])




% subplot(1,5,5)
% 
% AA = MPCOLLOCMCS_ALLYRS(:);        % x-axis
% BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis
% 
% AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
% plot(polyshape([0 0 1000000000000000000 1000000000000000000],[0 1000000000000000000 1000000000000000000 0]))
% hold on
% grid on
% binwidths = [6, 0.25*10^13];
% histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% % histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(flipud(creamsicle2))
% caxis([0 ctop])
% colorbar
% view(0,90)
% ccr = corrcoef(AA,BB); ccr = ccr(2);
% subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
% xlabel(' Collective time Synoptic & MCS objects are located (throughout MCS lifetime) [hrs]')
% ylabel(' Max MCS total PF rain mass throughout MCS lifetime [kg]')
% xticks([0:binwidths(1)*2:110])
% yticks([0:binwidths(2)*2:10^14])
% axis([0 110 0 5*10^13])

title([' MCS lifetime accumulated precip mass '])


%saveas(ff,horzcat(imout,'/hist2d_MCStotprecipmass.png'));
outlab = horzcat(imout,'/hist2d_MCStotprecipmass.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);












%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 
%%%   Now do the 2D histograms of MP obj properties throughout MCS
%%%   lifetime (while they are collocated) rather than just the MP obj 
%%%   properties @ time of MCSI
%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%% For MCSs with a SYN obj present at any time throughout its life: 

MPVORTfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;       MPVORTfullmcs_ALLYRS(:) = NaN ;         % magnitude of the max vorticity while syn obj touching mcs
MPAREAfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      	MPAREAfullmcs_ALLYRS(:) = NaN ;         % area of vorticity while syn obj touching mcs
MPSPEEDfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;      MPSPEEDfullmcs_ALLYRS(:) = NaN ;        % Syn obj speed while syn obj touching mcs

% MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;     % duration of vorticity track prior to time of MCSI   % already defined above
% MPCOLLOCMCS_ALLYRS = zeros(mcs_tracks,mcs_years) ;    % Number of time steps post-mcsi with a syn obj present - already defined above


%%% catalog these syn obj traits in MCS(tracks,years) space:
for y = 1:mcs_years
    for n = 1:mcs_tracks
        
        %   n = 79;  y = 2;   blah = MPtracks_perMCS_ALLYRS;
        
        %t-indices in each MCS track where there is a syn present
        mpspresent = find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  ;
        
        if( isempty(mpspresent) == 0)

            %empty vars to hold mean/max metrics for each syn object that
            %you will later mean/max again to relate to MCSs:
            mps_vorts = [] ;
            mps_areas = [] ;
            mps_speeds = [] ;
            
            %all of the unique syn tracks in this MCS's full track:
            mpnums = unique(MPtracks_perMCS_ALLYRS(mpspresent,n,y)) ;
            
            %loop thru all of the syn objs overlapping the current MCS
            for s = 1:length(mpnums)
                
                %find MCS's time indices when current syn object is present, then
                %log the first & last time
                mp_mcst = find( MPtracks_perMCS_ALLYRS(:,n,y) == mpnums(s) )  ;
                mcst1 = basetime_MCSstats_ALLYRS(mp_mcst(1),n,y) ;
                mcst2 = basetime_MCSstats_ALLYRS(mp_mcst(end),n,y) ;
                
                %find the time indices in current syn obj's track corersponding to
                %the MCS overlap period:
                MPti1 = find( floor(mcst1/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;
                MPti2 = find( floor(mcst2/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;    

                % log the max/mean of the current syn obj's
                % characteristics during its overlap period with the MCS.
                % throw it into an array that contains the same for all
                % other syn obj's touching the current MCS:
                mps_vorts = vertcat(mps_vorts, max( maxVOR600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )  ) ;      %max vort of syn obj during its contact with MCS
                mps_areas = vertcat(mps_areas, max( area_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) )   ) ;          %max area of syn obj during its contact with MCS  
                mps_speeds = vertcat(mps_speeds, mean( MP_speeds_ALLYRS(MPti1:MPti2,mpnums(s),y) , 'omitnan')) ;  %mean speed of syn obj during its contact with MCS  
                
            end
            
            %end up with the means of all of the mean/max synoptic objs
            %characteristics across all syn objects touching the current MCS:
            
            MPVORTfullmcs_ALLYRS(n,y)       =  mean( mps_vorts , 'omitnan');       
            MPAREAfullmcs_ALLYRS(n,y)       =  mean( mps_areas , 'omitnan');
            MPSPEEDfullmcs_ALLYRS(n,y)      =  mean( mps_speeds , 'omitnan');
            
        end
    end
end          








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% duration of collocated MCS & Syn object:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ctop = 100;
dualpol_colmap

ff = figure  
ff.Position = [163,283,1435,350];


subplot(1,3,1)

AA = MPCOLLOCMCS_ALLYRS(:);        % x-axis
BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis

%AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
%AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(MCSspeed_MCSstats_ALLYRS(:))) = NaN;  BB(isnan(MPCOLLOCMCS_ALLYRS(:))) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [6,2];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(greeny2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn durring collocation; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' Collocation duration [hrs]')
ylabel(' Mean MCS speed ')
xticks([0:binwidths(1)*2:110])
yticks([0:binwidths(2)*2:50])
axis([0 110 0 50])



subplot(1,3,2)

AA = MPCOLLOCMCS_ALLYRS(:);        % x-axis
BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis

%AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(maxareapf_MCSstats_ALLYRS(:))) = NaN;  BB(isnan(MPCOLLOCMCS_ALLYRS(:))) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [6, 10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(greeny2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn durring collocation; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' Collocation duration [hrs]')
ylabel(' MCS max PF area [km^2]')
xticks([0:binwidths(1)*2:110])
yticks([0:binwidths(2)*2:250000])
axis([0 110 0 250000])



subplot(1, 3, 3)

AA = MPCOLLOCMCS_ALLYRS(:);        % x-axis
BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis

%AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = [];   BB(isnan(BB)) = [];
AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(totalrainmass_MCSstats_ALLYRS(:))) = NaN;  BB(isnan(MPCOLLOCMCS_ALLYRS(:))) = NaN;    AA(isnan(AA)) = [];   BB(isnan(BB)) = []; 
plot(polyshape([0 0 10000000000000000 10000000000000000],[0 10000000000000000 10000000000000000 0]))
hold on
grid on
binwidths = [6, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(greeny2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Syn durring collocation; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' Collocation duration [hrs]')
ylabel(' Max MCS total PF rain mass [kg]')
xticks([0:binwidths(1)*2:110])
yticks([0:binwidths(2)*2:10^14])
axis([0 110 0 5*10^13])


title([' MP-MCS collocation period  vs.  MCS lifetime characteristics '])


%saveas(ff,horzcat(imout,'/hist2d_collocation.png'));
outlab = horzcat(imout,'/hist2d_collocation.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);












%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% Collocated Syn's max vorticity  & MCS:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ctop = 60;
dualpol_colmap

ff = figure  
ff.Position = [166.9156895252448,76.10000000000002,1495.0743029389615,415.6500000000002];


subplot(1,3,1)

AA = MPVORTfullmcs_ALLYRS(:);        % x-axis
BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [6*10^-6,2]; 
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% figure; histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% figure; histogram2(AA(:),BB(:),'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(bluey2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(BB)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP max vorticity [1/s]')
ylabel(' Mean MCS speed throughout MCS lifetime')
xticks([3*10^-5 : binwidths(1)*2 : 10^-3])
yticks([0:binwidths(2)*2:50])
axis([3*10^-5 1.5*10^-4 0 50])




subplot(1,3,2)

AA = MPVORTfullmcs_ALLYRS(:);        % x-axis
BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [6*10^-6, 10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(bluey2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP max vorticity [1/s]')
ylabel(' Max MCS total PF area throughout MCS lifetime [km^2]')
xticks([3*10^-5 : binwidths(1)*2 : 10^-3])
yticks([0:binwidths(2)*2:250000])
axis([3*10^-5 1.5*10^-4 0 250000])



subplot(1,3,3)

AA = MPVORTfullmcs_ALLYRS(:);        % x-axis
BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000000000000000 1000000000000000000],[0 1000000000000000000 1000000000000000000 0]))
hold on
grid on
binwidths = [6*10^-6, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(bluey2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP max vorticity [1/s]')
ylabel(' Max MCS total PF rain mass throughout MCS lifetime [kg]')
xticks([3*10^-5 : binwidths(1)*2 : 10^-3])
yticks([0:binwidths(2)*2:10^14])
axis([3*10^-5 1.5*10^-4 0 5*10^13])


title([' MP vorticity while collocated with MCS   vs.  MCSs lifetime characteristics '])


%saveas(ff,horzcat(imout,'/hist2d_MPVORT.png'));
outlab = horzcat(imout,'/hist2d_MPVORT.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);








%  MPSPEEDfullmcs_ALLYRS 




% axis([0 10*10^5 0 5*10^13])
 


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% Collocated MP's max area & MCS:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ctop = 120;
dualpol_colmap

ff = figure  
ff.Position = [166.9156895252448,76.10000000000002,1495.0743029389615,415.6500000000002];


subplot(1,3,1)

AA = MPAREAfullmcs_ALLYRS(:);        % x-axis
BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [50000,2]; 
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% figure; histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% figure; histogram2(AA(:),BB(:),'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(peppermint2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP area [km^2]')
ylabel(' Mean MCS speed throughout MCS lifetime')
xticks([0:binwidths(1)*2:10*10^5])
yticks([0:binwidths(2)*2:50])
axis([0 10*10^5 0 50])




subplot(1,3,2)

AA = MPAREAfullmcs_ALLYRS(:);        % x-axis
BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [50000, 10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(peppermint2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP area [km^2]')
ylabel(' Max MCS total PF area throughout MCS lifetime [km^2]')
xticks([0:binwidths(1)*2:10*10^5])
yticks([0:binwidths(2)*2:250000])
axis([0 10*10^5 0 250000])



subplot(1,3,3)

AA = MPAREAfullmcs_ALLYRS(:);        % x-axis
BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000000000000000 1000000000000000000],[0 1000000000000000000 1000000000000000000 0]))
hold on
grid on
binwidths = [50000, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(peppermint2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP area [km^2]')
ylabel(' Max MCS total PF rain mass throughout MCS lifetime [kg]')
xticks([0:binwidths(1)*2:10*10^5])
yticks([0:binwidths(2)*2:10^14])
axis([0 10*10^5 0 5*10^13])


title([' MP area while collocated with MCS   vs.  MCS lifetime characteristics '])

%saveas(ff,horzcat(imout,'/hist2d_MPAREA.png'));
outlab = horzcat(imout,'/hist2d_MPAREA.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% Collocated MP's mean speed & MCS:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ctop = 60;
dualpol_colmap

ff = figure  
ff.Position = [166.9156895252448,76.10000000000002,1495.0743029389615,415.6500000000002];


subplot(1,3,1)

AA = MPSPEEDfullmcs_ALLYRS(:);        % x-axis
BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [2,2]; 
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% figure; histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% figure; histogram2(AA(:),BB(:),'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(flipud(creamsicle2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP feature mean speed [m/s]')
ylabel(' Mean MCS speed throughout MCS lifetime')
xticks([0:binwidths(2)*2:50])
yticks([0:binwidths(2)*2:50])
axis([0 50 0 50])




subplot(1,3,2)

AA = MPSPEEDfullmcs_ALLYRS (:);        % x-axis
BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000 1000000],[0 1000000 1000000 0]))
hold on
grid on
binwidths = [2, 10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(flipud(creamsicle2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP mean speed [m/s]')
ylabel(' Max MCS total PF area throughout MCS lifetime [km^2]')
xticks([0:binwidths(1)*2:50])
yticks([0:binwidths(2)*2:250000])
axis([0 50 0 250000])



subplot(1,3,3)

AA = MPSPEEDfullmcs_ALLYRS (:);        % x-axis
BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([0 0 1000000000000000000 1000000000000000000],[0 1000000000000000000 1000000000000000000 0]))
hold on
grid on
binwidths = [2, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(flipud(creamsicle2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,';  cor coeff = ', num2str(ccr) ] )
xlabel(' MP feature mean speed [m/s]')
ylabel(' Max MCS total PF rain mass throughout MCS lifetime [kg]')
xticks([0:binwidths(1)*2:50])
yticks([0:binwidths(2)*2:10^14])
axis([0 50 0 5*10^13])


title([' MP mean motion while collocated with MCS   vs.  MCS lifetime characteristics '])


%saveas(ff,horzcat(imout,'/hist2d_MPSPEED.png'));
outlab = horzcat(imout,'/hist2d_MPSPEED.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);

%%%%



























%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                
%%%%             Looking at environmental ERA5 vars (e.g., PW, W, cape, ...)
%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%  ERA5 env metrics at MCSI
maxW600_MCSstats_AtMCSI   = maxW600_MCSstats_ALLYRS(1,:,:) ;         maxW600_MCSstats_AtMCSI = permute(maxW600_MCSstats_AtMCSI, [2 3 1]) ;
meanPW_MCSstats_AtMCSI    = meanPW_MCSstats_ALLYRS(1,:,:) ;          meanPW_MCSstats_AtMCSI = permute(meanPW_MCSstats_AtMCSI, [2 3 1]) ;
maxMUCAPE_MCSstats_AtMCSI = maxMUCAPE_MCSstats_ALLYRS(1,:,:) ;       maxMUCAPE_MCSstats_AtMCSI = permute(maxMUCAPE_MCSstats_AtMCSI, [2 3 1]) ;
maxVIWVC_MCSstats_AtMCSI  = maxVIWVConv_MCSstats_ALLYRS(1,:,:) ;     maxVIWVC_MCSstats_AtMCSI = permute(maxVIWVC_MCSstats_AtMCSI, [2 3 1]) ;


% divide up into MCSs with(out) syn objecst at MCSI:
mask_mpatMCSI = zeros(mcs_tracks,mcs_years);  mask_mpatMCSI(:) = NaN;          %1 if synoptic object at MCSI, NaN if not
mask_nompatMCSI = zeros(mcs_tracks,mcs_years);  mask_nompatMCSI(:) = NaN;      %1 if no synoptic object at MCSI, NaN if there is one
%MCSI with syn:
for y = 1:mcs_years
    for m = 1:mcs_tracks
        if( MPatMCSI_perMCS_ALLYRS(1,m,y) > 0   |   MPatMCSI_perMCS_ALLYRS(2,m,y) > 0  )
            mask_mpatMCSI(m,y) = 1;  
        else
            mask_nompatMCSI(m,y) = 1;
        end
    end
end

maxW600_MCSstats_mpatMCSI   = maxW600_MCSstats_AtMCSI .* mask_mpatMCSI;
maxW600_MCSstats_nompatMCSI = maxW600_MCSstats_AtMCSI .* mask_nompatMCSI;

meanPW_MCSstats_mpatMCSI   = meanPW_MCSstats_AtMCSI .* mask_mpatMCSI;
meanPW_MCSstats_nompatMCSI = meanPW_MCSstats_AtMCSI .* mask_nompatMCSI;

maxMUCAPE_MCSstats_mpatMCSI   = maxMUCAPE_MCSstats_AtMCSI .* mask_mpatMCSI;
maxMUCAPE_MCSstats_nompatMCSI = maxMUCAPE_MCSstats_AtMCSI .* mask_nompatMCSI;

maxVIWVC_MCSstats_mpatMCSI    = maxVIWVC_MCSstats_AtMCSI .* mask_mpatMCSI;
maxVIWVC_MCSstats_nompatMCSI  = maxVIWVC_MCSstats_AtMCSI .* mask_nompatMCSI;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% histogram of raw MP W for MCSs with & without MP objs at birth:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


ff = figure('position',[84,497,1032,451]);
edges=[-10:0.1:5];
hold on
% hist(maxW600_MCSstats_nompatMCSI(:),edges);
% h = findobj(gca,'Type','patch');
% h.FaceColor = [0 0.5 0.5];
% h.EdgeColor = [0 0 0];
% hold on
% hist(maxW600_MCSstats_mpatMCSI(:),edges);
% h2 = findobj(gca,'Type','patch');
% h2(1).FaceColor = [1 0.5 0];
% h2(1).EdgeColor = [0 0 0];
% h2(1).FaceAlpha = 0.8;
[h1,b] = hist(maxW600_MCSstats_nompatMCSI,edges) ;  blah1 =  h1/(sum(h1));
bar(b,blah1,1,'FaceColor',[0 0.5 0.5],'EdgeColor','k')
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(maxW600_MCSstats_mpatMCSI(:),edges) ;  blah2 =  h1/(sum(h1));
bar(b,blah2,1,'FaceColor',[1 0.5 0],'EdgeColor','k')
alpha 0.7
hold on
plot(median(maxW600_MCSstats_nompatMCSI(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(maxW600_MCSstats_nompatMCSI(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(maxW600_MCSstats_mpatMCSI(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(maxW600_MCSstats_mpatMCSI(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
title(' Max ERA5 updraft (min omega) surrounding MCS','FontSize',15)
ax = gca;
ax.FontSize = 15
alvl = 0.05;
[sh,p] = kstest2(maxW600_MCSstats_nompatMCSI(:),maxW600_MCSstats_mpatMCSI(:),'Alpha',alvl)
% text(-4,225,['K-S test at ', num2str(alvl),' significance lvl:'])
% if(sh == 0)
%     text(-3.85,210,['Sig diff distributions? NO.  P-val:',num2str(p)])
% elseif(sh == 1)
%     text(-3.85,210,['Sig diff distributions? YES.  P-val:',num2str(p)]) 
% end
[p2,sh2] = ranksum(maxW600_MCSstats_nompatMCSI(:),maxW600_MCSstats_mpatMCSI(:),'Alpha',alvl)
% text(-4,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
% if(sh2 == 0)
%     text(-3.85,135,['Sig diff distributions? NO.  P-val:',num2str(p2)])
% elseif(sh2 == 1)
%     text(-3.85,135,['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
% end
xticks( [-5.0:0.5:5] )
%xticks( [-5.05:0.4:4.9] )
xlabel(['vertcal motion [Pa/s]'],'FontSize',15)
ylabel(['Num of MCSs (normalized by sample size)'],'FontSize',15)
axis([-5 1 0 0.12 ])


%saveas(ff,horzcat(imout,'/MCSIwithwithoutsyn_maxW600.png'));
outlab = horzcat(imout,'/MCSIwithwithoutsyn_maxW600.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%%%%%%%% jnmtohere



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now plot histograms of MP origins tied to MCSI of hi-, med-, lo- W surrounding MCSs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hisupd  = [-20.00000000, -1.750000000001] ;
medsupd = [-1.75, -0.5200000001] ;
losupd  = [-0.52, 0] ;

% grab MCS duration and MP obj for all events with MP present at MCSI:

MCSwithMPsupd_list = [];
MCSwithoutMPsupd_list = [];

%lat/lons of origin site of MP obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a syn obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  |  MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPsupd_list = vertcat( MCSwithMPsupd_list, maxW600_MCSstats_AtMCSI(n,y) );
            
            %find the syn obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(  maxW600_MCSstats_AtMCSI(n,y))==0  &  maxW600_MCSstats_AtMCSI(n,y) < hisupd(end)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan( maxW600_MCSstats_AtMCSI(n,y))==0  &  maxW600_MCSstats_AtMCSI(n,y) < medsupd(end)  &  maxW600_MCSstats_AtMCSI(n,y) > medsupd(1)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan( maxW600_MCSstats_AtMCSI(n,y) )==0  &  maxW600_MCSstats_AtMCSI(n,y) > losupd(1)  &  maxW600_MCSstats_AtMCSI(n,y) < 0.0 )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end
            
            
            %if no syn obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPsupd_list = vertcat(MCSwithoutMPsupd_list, maxW600_MCSstats_AtMCSI(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)








ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI with background max updraft < : ', num2str(hisupd(end)),' Pa/s.  N = ', num2str(length(mplat_hiMCS)) ])


%saveas(ff,horzcat(imout,'/hist2d_strongbackgroundwmax.png'));
outlab = horzcat(imout,'/hist2d_strongbackgroundwmax.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);







%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with background max updraft : ', num2str(medsupd(end)),' to ',num2str(medsupd(1)) ' Pa/s.  N = ', num2str(length(mplat_medMCS)) ])


%saveas(ff,horzcat(imout,'/hist2d_medbackgroundwmax.png'));
outlab = horzcat(imout,'/hist2d_medbackgroundwmax.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);






%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with background max updraft : ',num2str(losupd(end)) ' - 0.0 m/s.  N = ', num2str(length(mplat_loMCS)) ])

%saveas(ff,horzcat(imout,'/hist2d_weakbackgroundwmax.png'));
outlab = horzcat(imout,'/hist2d_weakbackgroundwmax.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS-360)
mean(mplon_hiMCS-360) 
median(mplon_loMCS-360)
median(mplon_hiMCS-360) 

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS)
mean(mplat_hiMCS) 
median(mplat_loMCS)
median(mplat_hiMCS) 

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)












% [h1,b] = hist(MCSwithoutMPDuration_list,edges) ;  blah1 =  h1/(sum(h1));
% bar(b,blah1,1,'FaceColor',[0 0.5 0.5])
% alpha 0.7
% hold on
% %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
% [h1,b] = hist(MCSwithMPDuration_list,edges) ;  blah2 =  h1/(sum(h1));
% bar(b,blah2,1,'FaceColor',[1 0.5 0])
% alpha 0.7
% hold on
% plot(median(MCSwithoutMPDuration_list,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
% plot(mean(MCSwithoutMPDuration_list,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
% plot(median(MCSwithMPDuration_list,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
% plot(mean(MCSwithMPDuration_list,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
% alvl = 0.05;
% [sh,p] = kstest2(MCSwithoutMPDuration_list,MCSwithMPDuration_list,'Alpha',alvl)
% [p2,sh2] = ranksum(MCSwithoutMPDuration_list,MCSwithMPDuration_list,'Alpha',alvl)
% ax = gca;
% ax.FontSize = 15
% legend('MCSI without MD','MCSI with MD','FontSize',15)
% title(' Duration of MCSs','FontSize',15)
% axis([1 72 0 max(blah1)+0.025 ])
% xticks([0:6:96])
% xlabel('Hours','FontSize',15)
% ylabel('# MCS events (normalized by sample size)','FontSize',15)










%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% histogram of raw synoptic PW for MCSs with & without synoptic objs at birth:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ff = figure('position',[84,497,1032,451]);
edges=[0:1:80];
hold on
% hist(meanPW_MCSstats_nompatMCSI(:),edges);
% h = findobj(gca,'Type','patch');
% h.FaceColor = [0 0.5 0.5];
% h.EdgeColor = [0 0 0];
% hold on
% hist(meanPW_MCSstats_mpatMCSI(:),edges);
% h2 = findobj(gca,'Type','patch');
% h2(1).FaceColor = [1 0.5 0];
% h2(1).EdgeColor = [0 0 0];
% h2(1).FaceAlpha = 0.8;
[h1,b] = hist(meanPW_MCSstats_nompatMCSI,edges) ;  blah1 =  h1/(sum(h1));
bar(b,blah1,1,'FaceColor',[0 0.5 0.5])
alpha 0.7
hold on
%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(meanPW_MCSstats_mpatMCSI(:),edges) ;  blah2 =  h1/(sum(h1));
bar(b,blah2,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(meanPW_MCSstats_nompatMCSI(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(meanPW_MCSstats_nompatMCSI(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(meanPW_MCSstats_mpatMCSI(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(meanPW_MCSstats_mpatMCSI(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MCSI without synoptic obj','MCSI with synoptic obj','FontSize',15)
title(' Mean precip water surrounding MCS','FontSize',15)

alvl = 0.05;
[sh,p] = kstest2(meanPW_MCSstats_nompatMCSI(:),meanPW_MCSstats_mpatMCSI(:),'Alpha',alvl)
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
% if(sh == 0)
%     text(10,87,['Sig diff distributions? NO.  P-val:',num2str(p)])
% elseif(sh == 1)
%     text(10,87,['Sig diff distributions? YES.  P-val:',num2str(p)]) 
% end
[p2,sh2] = ranksum(meanPW_MCSstats_nompatMCSI(:),meanPW_MCSstats_mpatMCSI(:),'Alpha',alvl)
% text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
% if(sh2 == 0)
%     text(10,67,['Sig diff distributions? NO.  P-val:',num2str(p2)])
% elseif(sh2 == 1)
%     text(10,67,['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
% end
ax = gca;
ax.FontSize = 15
xticks( [0.5:4:80.5] )
xlabel('PW [kg/m^2]','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)
axis([0 80 0 0.05 ])


%saveas(ff,horzcat(imout,'/PW_MCSIwithwithoutMP.png'));
outlab = horzcat(imout,'/PW_MCSIwithwithoutMP.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% now plot histograms of MP origins tied to MCSI of hi-, med-, lo- PW surrounding MCSs
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

hispw  = [41.0000001, 1000] ;
medspw = [31.500001, 41.0] ;
lospw  = [0, 31.5] ;

% grab MCS duration and MP obj for all events with MP present at MCSI:

MCSwithMPspw_list = [];
MCSwithoutMPspw_list = [];

%lat/lons of origin site of MP obj present at bith of lon-, med-, short- duration MCSs
mplat_hiMCS = [];
mplat_medMCS = [];
mplat_loMCS = [];
mplon_hiMCS = [];
mplon_medMCS = [];
mplon_loMCS = [];


for y = 1 : mcs_years        % which is same as num years of syn objects
    for n = 1 : mcs_tracks
        
        %if there's a MP obj at mcsi
        if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  |  MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
            
            MCSwithMPspw_list = vertcat( MCSwithMPspw_list, meanPW_MCSstats_AtMCSI(n,y) );
            
            %find the MP obj number & then it's origin lat/lon and cat it (for different mcs durations):
            
            if(  isnan(  meanPW_MCSstats_AtMCSI(n,y))==0  &  meanPW_MCSstats_AtMCSI(n,y) > hispw(1)    )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan( meanPW_MCSstats_AtMCSI(n,y)) ==0  &  meanPW_MCSstats_AtMCSI(n,y) > medspw(1)  &  meanPW_MCSstats_AtMCSI(n,y) < medspw(end)      )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
                
                
            elseif(  isnan( meanPW_MCSstats_AtMCSI(n,y) )==0  &  meanPW_MCSstats_AtMCSI(n,y) > lospw(1) )
                
                mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
                for s = 1:length(mpnum)
                    mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
                    mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
                end
            end

            %if no MP obj present at MCSI
        elseif( MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
            
            MCSwithoutMPspw_list = vertcat(MCSwithoutMPspw_list, meanPW_MCSstats_AtMCSI(n,y) );
            
        end
    end
end

length(mplat_hiMCS)
length(mplat_medMCS)
length(mplat_loMCS)






ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

%subplot(3,1,1)

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_hiMCS-360,mplat_hiMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI with background mean PW > : ', num2str(hispw(1)),' kg/m^2.  N = ', num2str(length(mplat_hiMCS)) ])

%saveas(ff,horzcat(imout,'/2dhist_synorig_geolargePW.png'));
outlab = horzcat(imout,'/2dhist_synorig_geolargePW.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);






%subplot(3,1,2)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_medMCS-360,mplat_medMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with background mean PW : ', num2str(medspw(1)),' to ',num2str(medspw(end)) ' kg/m^2.  N = ', num2str(length(mplat_medMCS)) ])


%saveas(ff,horzcat(imout,'/2dhist_MPorig_geomedPW.png'));
outlab = horzcat(imout,'/2dhist_MPorig_geomedPW.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);








%subplot(3,1,3)
ff = figure  
ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];

ax1 = axes; 
ax2 = axes; 
ax3 = axes; 
linkaxes([ax1,ax2,ax3],'xy'); 

plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
hold on

histogram2(ax2,mplon_loMCS-360,mplat_loMCS,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(ax2,flipud(creamsicle2))   
caxis(ax2,[1 15])
view(ax2,0,90)
cb = colorbar(ax2)
agr=get(cb); %gets properties of colorbar
aa = agr.Position; %gets the positon and size of the color bar
set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
hold on

load coastlines
plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
hold on

load topo topo 
highelev = topo ;
highelev(topo < 1500) = 0;
contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] ,'LineWidth',1.25,'LineColor',[0.2 0.6 0.2]);  

set(ax2,'Color','None')       %p
set(ax2, 'visible', 'off');   %p

set(ax3,'Color','None')       %p
set(ax3, 'visible', 'off');   %p

axis([-160 -50 15 60])
title([' Origin locations of MPs eventually present during MCSI of MCSs with background mean PW < : ',num2str(lospw(end)) ' kg/m^2.  N = ', num2str(length(mplat_loMCS)) ])

%saveas(ff,horzcat(imout,'/2dhist_MPorig_geosmallPW.png'));
outlab = horzcat(imout,'/2dhist_MPorig_geosmallPW.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);



%stat diff tests, is lare-area-MCS syn obj origin different than for small-area-mcs?:

mean(mplon_loMCS)-360
mean(mplon_hiMCS) -360
median(mplon_loMCS)-360
median(mplon_hiMCS) -360

alvl = 0.05;
[sh,p] = kstest2(mplon_hiMCS,mplon_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplon_hiMCS,mplon_loMCS,'Alpha',alvl)

mean(mplat_loMCS)
mean(mplat_hiMCS)
median(mplat_loMCS)
median(mplat_hiMCS)

[sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
[p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)

















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%       MP W  @ MCSI      vs ...   MCS lifetime characteristics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


ctop = 200;
dualpol_colmap

ff = figure  
ff.Position = [166.9156895252448,76.10000000000002,1495.0743029389615,415.6500000000002];

subplot(1,3,1)

AA = maxW600_MCSstats_AtMCSI(:);        % x-axis
BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis
AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 

plot(polyshape([-10000 -10000 1000000000000000000 1000000000000000000],[-10000 1000000000000000000 1000000000000000000 -10000]))
hold on
grid on
binwidths = [0.25, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((peppermint2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
title('MP @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
xlabel(' MP max vertical velocity [Pa/s]')
ylabel(' Max MCS total PF rain mass [kg]')
yticks([0:binwidths(2)*2:10^14])
xticks([-6 : binwidths(1)*2 : 1])
axis([-6 1 0 5*10^13])



subplot(1,3,2)

AA = maxW600_MCSstats_AtMCSI(:);        % x-axis
BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([-10000 -10000 1000000000  1000000000000],[-10000 100000000000 1000000000000 -10000]))
hold on
grid on
binwidths = [0.25,10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
%histogram2(AA(:),BB(:),'NumBins',[30,30],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((peppermint2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
title('MP @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
xlabel(' MP max vertical velocity [Pa/s]')
ylabel(' Max MCS total PF rain area [km^2]')
yticks([0:binwidths(2)*2:10^6])
xticks([-6 : binwidths(1)*2 : 1])
axis([-6 1 0 250000])



subplot(1,3,3)

AA = maxW600_MCSstats_AtMCSI(:);        % x-axis
BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([-10000 -10000 1000000000  1000000000000],[-10000 100000000000 1000000000000 -10000]))
hold on
grid on
binwidths = [0.25, 2];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((peppermint2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
title('MP @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
xlabel(' MP max vertical velocity [Pa/s]')
ylabel(' Max MCS total PF rain mass [kg]')
yticks([0:binwidths(2)*2:50])
xticks([-6 : binwidths(1)*2 : 1])
axis([-6 1 0 50])









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%       MP PW  @ MCSI      vs ...   MCS lifetime characteristics
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% meanPW_MCSstats_AtMCSI 



ctop = 40;
dualpol_colmap

ff = figure  
ff.Position = [166.9156895252448,76.10000000000002,1495.0743029389615,415.6500000000002];

subplot(1,3,1)

AA = meanPW_MCSstats_AtMCSI(:) ;        % x-axis
BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis
AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 

plot(polyshape([-10000 -10000 1000000000000000000 1000000000000000000],[-10000 1000000000000000000 1000000000000000000 -10000]))
hold on
grid on
binwidths = [2, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((purpley2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Background PW @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,'; cor coreff = ', num2str(ccr) ] )
xlabel(' Background PW [kg/m^2]')
ylabel(' Max MCS total PF rain mass [kg]')
yticks([0:binwidths(2)*2:10^14])
xticks([0 : binwidths(1)*2 : 70])
axis([0 70 0 5*10^13])





subplot(1,3,2)

AA = meanPW_MCSstats_AtMCSI(:);        % x-axis
BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([-10000 -10000 1000000000  1000000000000],[-10000 100000000000 1000000000000 -10000]))
hold on
grid on
binwidths = [2, 10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
%histogram2(AA(:),BB(:),'NumBins',[30,30],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((purpley2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
%title('Background PW @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,'; cor coreff = ', num2str(ccr) ] )
xlabel(' Background PW [kg/m^2]')
ylabel(' Max MCS total PF rain area [km^2]')
yticks([0:binwidths(2)*2:10^6])
xticks([0 : binwidths(1)*2 : 70])
axis([0 70  0 250000])




subplot(1,3,3)

AA = meanPW_MCSstats_AtMCSI(:);        % x-axis
BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([-10000 -10000 1000000000  1000000000000],[-10000 100000000000 1000000000000 -10000]))
hold on
grid on
binwidths = [2, 2];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap((purpley2))
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
title('Background PW @ MCSI; MCS during lifetime') 
subtitle( ['N = ', num2str(length(AA)) ,'; cor coreff = ', num2str(ccr) ] )
xlabel(' Background PW [kg/m^2]')
ylabel(' Mean MCS speed [m/s]')
yticks([0:binwidths(2)*2:50])
xticks([0 : binwidths(1)*2 : 70])
axis([0 70 0 50])


%saveas(ff,horzcat(imout,'/2dhist_PWmcsi_vs_MCSlifetime.png'));
outlab = horzcat(imout,'/2dhist_PWmcsi_vs_MCSlifetime.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);


















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% 
%%%   Now do the 2D histograms of ERA5 environment vars throughout MCS
%%%   lifetime (while they are collocated) rather than just the MP obj 
%%%   properties @ time of MCSI
%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



%%%% For MCSs with a MP obj present at any time throughout its life: 

MPmaxWfullmcs_ALLYRS      = zeros(mcs_tracks,mcs_years) ;     MPmaxWfullmcs_ALLYRS(:) = NaN ;           % max W   "within" MP obj while MP obj touching mcs
MPmeanPWfullmcs_ALLYRS    = zeros(mcs_tracks,mcs_years) ;     MPmeanPWfullmcs_ALLYRS(:) = NaN ;         % mean PW "within" MP obj while MP obj touching mcs
MPmaxE5CAPEfullmcs_ALLYRS = zeros(mcs_tracks,mcs_years) ;     MPmaxE5CAPEfullmcs_ALLYRS(:) = NaN ;           % max era5 cape (MU) "within" MP obj while MP obj touching mcs
MPmaxVIWVCfullmcs_ALLYRS  = zeros(mcs_tracks,mcs_years) ;     MPmaxVIWVCfullmcs_ALLYRS(:) = NaN ;         % max vert integrated water vapor convergence (min of div, so negative = conv) "within" MP obj while MP obj touching mcs


%%% catalog these MP obj traits in MCS(tracks,years) space:
for y = 1:mcs_years
    for n = 1:mcs_tracks
        %   n = 66;  y = 1;

        %t-indices in each MCS track where
        mpspresent = find(MPtracks_perMCS_ALLYRS(:,n,y) > 0)  ;
        
        if( isempty(mpspresent) == 0 )

            %empty vars to hold mean/max metrics for each syn object that
            %you will later mean/max again to relate to MCSs:
            mps_maxW = [] ;
            mps_meanPW = [] ;
            mps_maxE5CAPE = [];
            mps_maxVIWVC = [];
            
            %all of the unique MP tracks in this MCS:
            mpnums = unique(MPtracks_perMCS_ALLYRS(mpspresent,n,y)) ;
            
            for s = 1:length(mpnums)
                
                mp_mcst = find( MPtracks_perMCS_ALLYRS(:,n,y) == mpnums(s) )  ;
                mcst1 = basetime_MCSstats_ALLYRS(mp_mcst(1),n,y) ;
                mcst2 = basetime_MCSstats_ALLYRS(mp_mcst(end),n,y) ;
                
                MPti1 = find( floor(mcst1/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;
                MPti2 = find( floor(mcst2/100) ==  floor(basetime_MPstats_ALLYRS(:,mpnums(s),y)/100) ) ;    

                mps_maxW        = vertcat(mps_maxW,      max( maxW600_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) , [], 'omitnan')  ) ;      %max vert motion (really min-Omega) of syn obj during its contact with MCS
                mps_meanPW      = vertcat(mps_meanPW,    mean( meanPW_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) , 'omitnan')  ) ;  %mean speed of syn obj during its contact with MCS  
                mps_maxE5CAPE   = vertcat(mps_maxE5CAPE, max( maxMUCAPE_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) , [], 'omitnan')  ) ;      %max e5(MU)cape of syn obj during its contact with MCS
                mps_maxVIWVC    = vertcat(mps_maxVIWVC, max( maxVIWVConv_MPstats_ALLYRS(MPti1:MPti2,mpnums(s),y) , [], 'omitnan')  ) ;       %max e5 viwvc of syn obj during its contact with MCS 

            end
            
            %end up with the means of all of the mean/max MP objs characteristics:
            
            MPmaxWfullmcs_ALLYRS(n,y)         =  mean( mps_maxW , 'omitnan');       
            MPmeanPWfullmcs_ALLYRS(n,y)       =  mean( mps_meanPW , 'omitnan');  
            MPmaxE5CAPEfullmcs_ALLYRS(n,y)    =  mean( mps_maxE5CAPE , 'omitnan');       
            MPmaxVIWVCfullmcs_ALLYRS(n,y)     =  mean( mps_maxVIWVC , 'omitnan');  

        end
    end
end          






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% Collocated MP's max W (i.e., min omega) & MCS (ie, during mcs lifetime):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ctop = 120;
dualpol_colmap

ff = figure  
ff.Position = [166.9156895252448,81,1114.084310474755,470];


% subplot(1,3,1)
% 
% AA = MPmaxWfullmcs_ALLYRS(:);        % x-axis
% BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis
% 
% AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
% plot(polyshape([-10000 -10000 1000000 1000000],[-10000 1000000 1000000 -10000]))
% hold on
% grid on
% binwidths = [0.1,2]; 
% histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% % figure; histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% % figure; histogram2(AA(:),BB(:),'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(browny2)
% caxis([0 ctop])
% colorbar
% view(0,90)
% ccr = corrcoef(AA,BB); ccr = ccr(2);
% subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
% xlabel(' ERA5 max vertical motion [Pa/s]')
% ylabel(' Mean MCS speed throughout MCS lifetime')
% xticks([-2.0:binwidths(1)*2:0.])
% yticks([0:binwidths(2)*2:50])
% axis([-2 0.2 0 50])




subplot(1,2,1)

AA = MPmaxWfullmcs_ALLYRS(:);        % x-axis
BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([-10000 -10000 1000000 1000000],[-10000 1000000 1000000 -10000]))
hold on
grid on
binwidths = [0.1, 10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(browny2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,'; cor coeff = ', num2str(ccr) ] )
xlabel(' ERA5 max vertical motion [Pa/s]')
ylabel(' Max MCS total PF area throughout MCS lifetime [km^2]')
xticks([-2.0:binwidths(1)*2:1])
yticks([0:binwidths(2)*2:250000])
axis([-2 1 0 250000])



subplot(1,2,2)

AA = MPmaxWfullmcs_ALLYRS(:);        % x-axis
BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([-10000 -10000 10000000000000000 10000000000000000],[-10000 1000000000000000000 100000000000000000000 -10000]))
hold on
grid on
binwidths = [0.1, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(browny2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,'; cor coeff = ', num2str(ccr) ] )
xlabel(' ERA5 max vertical motion [Pa/s]')
ylabel(' Max MCS total PF rain mass throughout MCS lifetime [kg]')
xticks([-2.0:binwidths(1)*2:1])
yticks([0:binwidths(2)*2:10^14])
axis([-2 1 0 5*10^13])


title([' MP updraft max updraft (min omega) while MP collocated with MCS   vs.  MCS lifetime characteristics '])



%saveas(ff,horzcat(imout,'/2dhist_WMAXsurroundingMCSwithMPs_vs_MCSlifetime.png'));
outlab = horzcat(imout,'/2dhist_WMAXsurroundingMCSwithMPs_vs_MCSlifetime.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);











%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% mean PW surrounding MPs that are (and only while) collocated with MCS & MCS lifetime characteristics (ie, during mcs lifetime):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ctop = 50;
dualpol_colmap

ff = figure  
ff.Position = [166.9156895252448,81,1114.084310474755,470];


% subplot(1,3,1)
% 
% AA = MPmeanPWfullmcs_ALLYRS(:);        % x-axis
% BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis
% 
% AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
% plot(polyshape([-10000 -10000 1000000 1000000],[-10000 1000000 1000000 -10000]))
% hold on
% grid on
% binwidths = [2,2]; 
% histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% % figure; histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% % figure; histogram2(AA(:),BB(:),'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(bluey2)
% caxis([0 ctop])
% colorbar
% view(0,90)
% ccr = corrcoef(AA,BB); ccr = ccr(2);
% subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
% xlabel(' ERA5 mean PW surrounding MD [kg/m^2]')
% ylabel(' Mean MCS speed throughout MCS lifetime')
% xticks([1:binwidths(1)*2:65])
% yticks([0:binwidths(2)*2:50])
% axis([0 65 0 50])




subplot(1,2,1)

AA = MPmeanPWfullmcs_ALLYRS(:);        % x-axis
BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([-10000 -10000 1000000 1000000],[-10000 1000000 1000000 -10000]))
hold on
grid on
binwidths = [2, 10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(bluey2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
xlabel(' ERA5 mean PW surrounding MP [kg/m^2]')
ylabel(' Max MCS total PF area throughout MCS lifetime [km^2]')
xticks([1:binwidths(1)*2:65])
yticks([0:binwidths(2)*2:250000])
axis([0 65 0 250000])



subplot(1,2,2)

AA = MPmeanPWfullmcs_ALLYRS(:);        % x-axis
BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([-10000 -10000 10000000000000000 10000000000000000],[-10000 1000000000000000000 100000000000000000000 -10000]))
hold on
grid on
binwidths = [2, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(bluey2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
ylabel(' Max MCS total PF rain mass throughout MCS lifetime [kg]')
xlabel(' ERA5 mean PW surrounding MP [kg/m^2]')
xticks([1:binwidths(1)*2:65])
yticks([0:binwidths(2)*2:10^14])
axis([0 65 0 5*10^13])


title(['  mean PW surrounding MPs while collocated with MCS   vs.  MCS lifetime characteristics '])

%saveas(ff,horzcat(imout,'/2dhist_PWwithinSynDuringMCScollocation_vs_MCSlifetime.png'));
outlab = horzcat(imout,'/2dhist_PWwithinSynDuringMCScollocation_vs_MCSlifetime.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);















%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%% mean PW surrounding MCS without synoptic objects & MCS lifetime characteristics (ie, during mcs lifetime):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%





%generate list of MCS numbers with MP objs present at MCSI:

MCS_without_mp_thrumcslife = [];
PWforMCS_without_mp_thrumcslife = zeros(mcs_tracks,mcs_years);    PWforMCS_without_mp_thrumcslife(:) = NaN;
totrainmass_forMCS_without_mp_thrumcslife = zeros(mcs_tracks,mcs_years);  totrainmass_forMCS_without_mp_thrumcslife(:) = NaN;
maxareapf_forMCS_without_mp_thrumcslife = zeros(mcs_tracks,mcs_years);    maxareapf_forMCS_without_mp_thrumcslife(:) = NaN;
maxW600_forMCS_without_mp_thrumcslife = zeros(mcs_tracks,mcs_years);    maxW600_forMCS_without_mp_thrumcslife(:) = NaN;

% MCS_withoutsyn_lon_thrumcslife = [];
% MCS_withoutsyn_lat_thrumcslife = [];

for y = 1:mcs_years
    for n = 1:mcs_tracks
        
        %   n = 87;  y = 1;  n = 1;
        
        clear synlist syns
        %find where there are MP objects touching MCS at any time. If
        %there are, dont log the mcs or mcs metric.
        synlist = MPtracks_perMCS_ALLYRS(:,n,y) ;
        syns = find( synlist > 0 ) ;
        % if there are no MP objs touching the mcs at any point in its life: 
        if(  isempty(syns) &  isempty(find(synlist == -1))==0  ) % tabulate all of the MCSs with mp object present at birth
        
            MCS_without_mp_thrumcslife = vertcat( MCS_without_mp_thrumcslife , n);
            PWforMCS_without_mp_thrumcslife(n,y) =  mean(  meanPW_MCSstats_ALLYRS( :, n ,y),'omitnan'  ) ;
            totrainmass_forMCS_without_mp_thrumcslife(n,y) =  totalrainmass_MCSstats_ALLYRS( n ,y)  ; 
            maxareapf_forMCS_without_mp_thrumcslife(n,y) = maxareapf_MCSstats_ALLYRS( n ,y)  ; 
            maxW600_forMCS_without_mp_thrumcslife(n,y) = max(  maxW600_MCSstats_ALLYRS(:, n ,y),[],'omitnan'  )  ; 
%             MCS_withsyn_lon = vertcat( MCSI_withMP_lon, meanlon_MCSstats_ALLYRS(1,n,y) ) ;
%             MCS_withsyn_lat = vertcat( MCSI_withMP_lat, meanlat_MCSstats_ALLYRS(1,n,y) ) ;
            
        end
            
    end
end

length(MCS_without_mp_thrumcslife)   % number of MCS events that have no contact at all with syn obj throughout the whole mcs lifetime








ctop = 20;
dualpol_colmap

ff = figure  
ff.Position = [166.9156895252448,81,1114.084310474755,470];


% subplot(1,3,1)
% 
% AA = MPmeanPWfullmcs_ALLYRS(:);        % x-axis
% BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis
% 
% AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
% plot(polyshape([-10000 -10000 1000000 1000000],[-10000 1000000 1000000 -10000]))
% hold on
% grid on
% binwidths = [2,2]; 
% histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% % figure; histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% % figure; histogram2(AA(:),BB(:),'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(bluey2)
% caxis([0 ctop])
% colorbar
% view(0,90)
% ccr = corrcoef(AA,BB); ccr = ccr(2);
% subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
% xlabel(' ERA5 mean PW surrounding MD [kg/m^2]')
% ylabel(' Mean MCS speed throughout MCS lifetime')
% xticks([1:binwidths(1)*2:65])
% yticks([0:binwidths(2)*2:50])
% axis([0 65 0 50])




subplot(1,2,1)

AA = PWforMCS_without_mp_thrumcslife(:);        % x-axis
BB = maxareapf_forMCS_without_mp_thrumcslife(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([-10000 -10000 1000000 1000000],[-10000 1000000 1000000 -10000]))
hold on
grid on
binwidths = [2, 10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(bluey2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
xlabel(' ERA5 mean PW surrounding MP [kg/m^2]')
ylabel(' Max MCS total PF area throughout MCS lifetime [km^2]')
xticks([1:binwidths(1)*2:65])
yticks([0:binwidths(2)*2:250000])
axis([0 65 0 250000])




subplot(1,2,2)

AA = PWforMCS_without_mp_thrumcslife(:);        % x-axis
BB = totrainmass_forMCS_without_mp_thrumcslife(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([-10000 -10000 10000000000000000 10000000000000000],[-10000 1000000000000000000 100000000000000000000 -10000]))
hold on
grid on
binwidths = [2, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(bluey2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
ylabel(' Max MCS total PF rain mass throughout MCS lifetime [kg]')
xlabel(' ERA5 mean PW surrounding MP [kg/m^2]')
xticks([1:binwidths(1)*2:65])
yticks([0:binwidths(2)*2:10^14])
axis([0 65 0 5*10^13])


title(['  mean PW surrounding MPs with no MP present during all points of MCS liftime   vs.  MCS lifetime characteristics '])

%saveas(ff,horzcat(imout,'/2dhist_PWsurroundingMCSwithNOmps_vs_MCSlifetime.png'));
outlab = horzcat(imout,'/2dhist_PWsurroundingMCSwithNOmps_vs_MCSlifetime.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);





%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% updraft for mcs without MP objs:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ctop = 20;
dualpol_colmap

ff = figure  
ff.Position = [166.9156895252448,81,1114.084310474755,470];


% subplot(1,3,1)
% 
% AA = MPmaxWfullmcs_ALLYRS(:);        % x-axis
% BB = MCSspeed_MCSstats_ALLYRS(:);    % y-axis
% 
% AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
% plot(polyshape([-10000 -10000 1000000 1000000],[-10000 1000000 1000000 -10000]))
% hold on
% grid on
% binwidths = [0.1,2]; 
% histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% % figure; histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% % figure; histogram2(AA(:),BB(:),'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(browny2)
% caxis([0 ctop])
% colorbar
% view(0,90)
% ccr = corrcoef(AA,BB); ccr = ccr(2);
% subtitle( ['N = ', num2str(length(AA)) ,' ccr = ', num2str(ccr) ] )
% xlabel(' ERA5 max vertical motion [Pa/s]')
% ylabel(' Mean MCS speed throughout MCS lifetime')
% xticks([-2.0:binwidths(1)*2:0.])
% yticks([0:binwidths(2)*2:50])
% axis([-2 0.2 0 50])




subplot(1,2,1)

AA = maxW600_forMCS_without_mp_thrumcslife(:);        % x-axis
BB = maxareapf_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([-10000 -10000 1000000 1000000],[-10000 1000000 1000000 -10000]))
hold on
grid on
binwidths = [0.1, 10000];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(browny2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,'; cor coeff = ', num2str(ccr) ] )
xlabel(' ERA5 max vertical motion [Pa/s]')
ylabel(' Max MCS total PF area throughout MCS lifetime [km^2]')
xticks([-2.0:binwidths(1)*2:1])
yticks([0:binwidths(2)*2:250000])
axis([-2 1 0 250000])



subplot(1,2,2)

AA = maxW600_forMCS_without_mp_thrumcslife(:);        % x-axis
BB = totalrainmass_MCSstats_ALLYRS(:);    % y-axis

AA(AA==0) = NaN; BB(BB==0) = NaN;   AA(isnan(BB)) = NaN;  BB(isnan(AA)) = NaN;    AA(isnan(AA)) = []; BB(isnan(BB)) = []; 
plot(polyshape([-10000 -10000 10000000000000000 10000000000000000],[-10000 1000000000000000000 100000000000000000000 -10000]))
hold on
grid on
binwidths = [0.1, 0.25*10^13];
histogram2(AA(:),BB(:),'BinWidth',binwidths,'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% histogram2(AA(:),BB(:),'NumBins',[30,2],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
colormap(browny2)
caxis([0 ctop])
colorbar
view(0,90)
ccr = corrcoef(AA,BB); ccr = ccr(2);
subtitle( ['N = ', num2str(length(AA)) ,'; cor coeff = ', num2str(ccr) ] )
xlabel(' ERA5 max vertical motion [Pa/s]')
ylabel(' Max MCS total PF rain mass throughout MCS lifetime [kg]')
xticks([-2.0:binwidths(1)*2:1])
yticks([0:binwidths(2)*2:10^14])
axis([-2 1 0 5*10^13])

title([' Max updraft (min omega) surrounding MCS without MPs present during MCS lifetime  vs.  MCS lifetime characteristics '])


%saveas(ff,horzcat(imout,'/2dhist_WMAXsurroundingMCSwithNOmps_vs_MCSlifetime.png'));
outlab = horzcat(imout,'/2dhist_WMAXsurroundingMCSwithNOmps_vs_MCSlifetime.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);















%%%%%%%% %%%% %%%% %%%% %%%% %%%% %%%%%%%% %%%% %%%%   
%
%   break down MCS stats per area of MPs present at MCSI
%
%%%%%%%% %%%% %%%% %%%% %%%% %%%% %%%% %%%% %%%% %%%% 

%look thru MPatMSI_perMCS_ALLYRS and sort MCSs by MP area
mask_MCSI_with_smallMPat = zeros(mcs_tracks,mcs_years);   mask_MCSI_with_smallMPat(:) = NaN;  %mcs num with a "small" MP
mask_MCSI_with_medMPat   = zeros(mcs_tracks,mcs_years);   mask_MCSI_with_medMPat(:) = NaN; %mcs num with a "medium" MP
mask_MCSI_with_largeMPat = zeros(mcs_tracks,mcs_years);   mask_MCSI_with_largeMPat(:) = NaN; %mcs num with a "high" MP

mpareaspan = permute(max(area_MPstats_ALLYRS(:,:,:),[],1),[2 3 1]);   mpareaspan = mpareaspan(:);   mpareaspan(isnan(mpareaspan))=[];

for y = 1:mcs_years
    for n = 1:mcs_tracks  %MCS number

        %  n = 76;  y = 1;
        mp = find( MPatMCSI_perMCS_ALLYRS(:,n,y) > 0 )  ; %MPs "causing" MCSI
        mp = MPatMCSI_perMCS_ALLYRS(mp,n,y);

        if( isempty(mp)==0 ) % there is an MP with this MCSI event

            mp = max(mp); mp = mp(1); %boil down to one MP number

            if( max(area_MPstats_ALLYRS(:,mp,y),[],1)  <=  prctile( mpareaspan,(1/3)*100)  )
                mask_MCSI_with_smallMPat(n,y) = 1;
            elseif( max(area_MPstats_ALLYRS(:,mp,y),[],1) > prctile( mpareaspan,(1/3)*100)  &  max(area_MPstats_ALLYRS(:,mp,y),[],1) <= prctile( mpareaspan,(2/3)*100) )
                mask_MCSI_with_medMPat(n,y) = 1;
            elseif( max(area_MPstats_ALLYRS(:,mp,y),[],1) > prctile( mpareaspan,(2/3)*100) )
                mask_MCSI_with_largeMPat(n,y) = 1;          
            end

        end % if there is an MP for this MCSI

    end %num mcss
end %years


length(find(mask_MCSI_with_smallMPat==1))
length(find(mask_MCSI_with_medMPat==1))
length(find(mask_MCSI_with_largeMPat==1))

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % % now plot up MCS stats divided up into smal/med/large MPs



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% MCS duration:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


MCSduration_smallMPatmcsi = duration_MCSstats_ALLYRS .*  mask_MCSI_with_smallMPat;      MCSduration_smallMPatmcsi = MCSduration_smallMPatmcsi(:);
MCSduration_medMPatmcsi = duration_MCSstats_ALLYRS .*  mask_MCSI_with_medMPat;          MCSduration_medMPatmcsi = MCSduration_medMPatmcsi(:);
MCSduration_largeMPatmcsi = duration_MCSstats_ALLYRS .*  mask_MCSI_with_largeMPat;      MCSduration_largeMPatmcsi = MCSduration_largeMPatmcsi(:);


length(find(MCSduration_smallMPatmcsi > 0))
length(find(MCSduration_medMPatmcsi > 0))
length(find(MCSduration_largeMPatmcsi > 0))




%%%   Now do a fun one with:
%       i)   MCSs with LSs (MCS_withLS_Duration);
%       ii)  MCSs without LSs but with MPs (MCSwithMPDuration_list);
%       iii) MCSs without LSs or MPs (MCSwithoutMPDuration_list);


%histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
ff = figure('position',[84,497,1032,451]);

title(' Duration of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
edges=[0:1:96];
hold on
[h1,b] = hist(MCSduration_smallMPatmcsi,edges) ;  blah1 =  h1/(sum(h1));
b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5])
alpha 0.7
hold on

%hist(MCSwithMPDuration_list,edges,'Normalization','probability');
[h1,b] = hist(MCSduration_medMPatmcsi,edges) ;  blah2 =  h1/(sum(h1));
b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on

[h1,b] = hist(MCSduration_largeMPatmcsi,edges) ;  blah2 =  h1/(sum(h1));
b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1])
alpha 0.7
hold on

clear legend
ax = gca;
ax.FontSize = 15
leg = legend([b1 b2 b3],'location','best');
leg.String = {'MCS with small MP','MCS with med MP','MCS with large MP'};%'FontSize',15)
leg.FontSize = 15;
leg.AutoUpdate = 'off';

plot(median(MCSduration_smallMPatmcsi,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MCSduration_smallMPatmcsi,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MCSduration_medMPatmcsi,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
plot(mean(MCSduration_medMPatmcsi,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
plot(median(MCSduration_largeMPatmcsi,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
plot(mean(MCSduration_largeMPatmcsi,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])

axis([1 72 0 0.1]) %max(blah1) ])
xticks([0:6:96])
xlabel('Hours','FontSize',15)
ylabel('# MCS events (normalized by sample size)','FontSize',15)

%%%%%%%% image out:

saveas(ff,horzcat(imout,'/MCSIhist_duration_MPsize_filtLS',num2str(filteroutLS),'.png'));

outlab = horzcat(imout,'/MCSIhist_MPsize_duration.eps');
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);


alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSduration_smallMPatmcsi(:),MCSduration_largeMPatmcsi(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSduration_smallMPatmcsi(:),MCSduration_largeMPatmcsi(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end







%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% MCS total rain mass:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fact = 10^13 ;

    % condense [1:5] PF area stats 1-combined MCS pf area:

    rainmass  =  totalrain_MCSstats_ALLYRS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]
    sumrain =  permute( sum (   rainmass,1, 'omitnan'  ), [2 3 1]) ;  sumrain(sumrain==0) = NaN;

    MCSrainmass_smallMPatmcsi   = sumrain .*  mask_MCSI_with_smallMPat;   MCSrainmass_smallMPatmcsi = MCSrainmass_smallMPatmcsi(:);
    MCSrainmass_medMPatmcsi     = sumrain .*  mask_MCSI_with_medMPat;     MCSrainmass_medMPatmcsi = MCSrainmass_medMPatmcsi(:);
    MCSrainmass_largeMPatmcsi   = sumrain .*  mask_MCSI_with_largeMPat;   MCSrainmass_largeMPatmcsi = MCSrainmass_largeMPatmcsi(:);

    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' Total rain mass of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:.05:4];
    hold on
    [h1,b] = hist(MCSrainmass_smallMPatmcsi/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSrainmass_medMPatmcsi/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSrainmass_largeMPatmcsi/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with small MP','MCS with medium MP','MCS with large MP'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSrainmass_smallMPatmcsi/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSrainmass_smallMPatmcsi/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSrainmass_medMPatmcsi/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSrainmass_medMPatmcsi/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSrainmass_largeMPatmcsi/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSrainmass_largeMPatmcsi/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])

    xticks( [.025:0.2:edges(end)] )
    xlabel('MCS lifetime total rain mass [x10^1^3 kg]','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 edges(end)-1 0 0.15 ])

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_totrainmass_MPsize_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_MPsize_totrainmass.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);



    length(find(MCSrainmass_smallMPatmcsi>0))
    length(find(isnan(MCSrainmass_medMPatmcsi)==0))
    length(find(isnan(MCSrainmass_largeMPatmcsi)==0))








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%% MCS max summed pf area:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    fact = 10^13 ;

    % condense [1:5] PF area stats 1-combined MCS pf area:

    rainmass  =  totalrain_MCSstats_ALLYRS * pixel_radius_km * pixel_radius_km  * 1000 * 997.0 ;  % total_rain [km^3/h] * desnity of water [kg/km^3]
    sumrain =  permute( sum (   rainmass,1, 'omitnan'  ), [2 3 1]) ;  sumrain(sumrain==0) = NaN;

    MCSrainmass_smallMPatmcsi   = sumrain .*  mask_MCSI_with_smallMPat;   MCSrainmass_smallMPatmcsi = MCSrainmass_smallMPatmcsi(:);
    MCSrainmass_medMPatmcsi     = sumrain .*  mask_MCSI_with_medMPat;     MCSrainmass_medMPatmcsi = MCSrainmass_medMPatmcsi(:);
    MCSrainmass_largeMPatmcsi   = sumrain .*  mask_MCSI_with_largeMPat;   MCSrainmass_largeMPatmcsi = MCSrainmass_largeMPatmcsi(:);

    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' Total rain mass of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[0:.05:4];
    hold on
    [h1,b] = hist(MCSrainmass_smallMPatmcsi/fact,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5]);
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSrainmass_medMPatmcsi/fact,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0]);
    alpha 0.7
    hold on

    [h1,b] = hist(MCSrainmass_largeMPatmcsi/fact,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1]);
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with small MP','MCS with medium MP','MCS with large MP'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSrainmass_smallMPatmcsi/fact,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSrainmass_smallMPatmcsi/fact,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSrainmass_medMPatmcsi/fact,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSrainmass_medMPatmcsi/fact,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSrainmass_largeMPatmcsi/fact,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSrainmass_largeMPatmcsi/fact,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])

    xticks( [.025:0.2:edges(end)] )
    xlabel('MCS lifetime total rain mass [x10^1^3 kg]','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)
    axis([0 edges(end)-1 0 0.15 ])

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_totrainmass_MPsize_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_MPsize_totrainmass.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);



%     length(find(MCSrainmass_smallMPatmcsi>0))
%     length(find(isnan(MCSrainmass_medMPatmcsi)==0))
%     length(find(isnan(MCSrainmass_largeMPatmcsi)==0))



alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSrainmass_smallMPatmcsi(:),MCSrainmass_largeMPatmcsi(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSrainmass_smallMPatmcsi(:),MCSrainmass_largeMPatmcsi(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end








    %%%%%%%%%%%%%%%%%%%
    %%%  MCS max summed pf area
    %%%%%%%%

    MCSmaxpfarea_smallMPatmcsi   = maxareapf_MCSstats_ALLYRS .*  mask_MCSI_with_smallMPat;   MCSmaxpfarea_smallMPatmcsi = MCSmaxpfarea_smallMPatmcsi(:);
    MCSmaxpfarea_medMPatmcsi     = maxareapf_MCSstats_ALLYRS .*  mask_MCSI_with_medMPat;     MCSmaxpfarea_medMPatmcsi   = MCSmaxpfarea_medMPatmcsi(:);
    MCSmaxpfarea_largeMPatmcsi   = maxareapf_MCSstats_ALLYRS .*  mask_MCSI_with_largeMPat;   MCSmaxpfarea_largeMPatmcsi = MCSmaxpfarea_largeMPatmcsi(:);


    %histogram of MCS durations with & without MP objs at birth normalized by total count of each group:
    ff = figure('position',[84,497,1032,451]);

    title(' Max precip area of MCSs. filtLS=',num2str(filteroutLS),'FontSize',15)
    edges=[-5000:5000:400000-5000];
    hold on
    [h1,b] = hist(MCSmaxpfarea_smallMPatmcsi,edges) ;  blah1 =  h1/(sum(h1));
    b1 = bar(b,blah1,1,'FaceColor',[0 0.5 0.5])
    alpha 0.7
    hold on

    %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
    [h1,b] = hist(MCSmaxpfarea_medMPatmcsi,edges) ;  blah2 =  h1/(sum(h1));
    b2 = bar(b,blah2,1,'FaceColor',[1 0.5 0])
    alpha 0.7
    hold on

    [h1,b] = hist(MCSmaxpfarea_largeMPatmcsi,edges) ;  blah2 =  h1/(sum(h1));
    b3 = bar(b,blah2,1,'FaceColor',[0.4 0.7 1])
    alpha 0.7
    hold on

    clear legend
    ax = gca;
    ax.FontSize = 15
    leg = legend([b1 b2 b3],'location','best');
    leg.String = {'MCS with small MP','MCS with med MP','MCS with large MP'};%'FontSize',15)
    leg.FontSize = 15;
    leg.AutoUpdate = 'off';

    plot(median(MCSmaxpfarea_smallMPatmcsi,'omitnan'),0,'dk','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(mean(MCSmaxpfarea_smallMPatmcsi,'omitnan'),0,'ok','MarkerSize',15,'MarkerFaceColor',[0 0.5 0.5])
    plot(median(MCSmaxpfarea_medMPatmcsi,'omitnan'),0,'dk','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(mean(MCSmaxpfarea_medMPatmcsi,'omitnan'),0,'ok','MarkerSize',13,'MarkerFaceColor',[1 0.5 0])
    plot(median(MCSmaxpfarea_largeMPatmcsi,'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])
    plot(mean(MCSmaxpfarea_largeMPatmcsi,'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0.4 0.7 1])

    axis([1 2.5*10^5 0 0.11 ])
    xticks([0:10000:edges(end)-1000])
    xlabel('km^2','FontSize',15)
    ylabel('# MCS events (normalized by sample size)','FontSize',15)

    %%%%%%%% image out:

    saveas(ff,horzcat(imout,'/MCSIhist_maxareapf_MPsize_filtLS',num2str(filteroutLS),'.png'));

    outlab = horzcat(imout,'/MCSIhist_MPsize_maxareapf.eps');
    EPSprint = horzcat('print -painters -depsc ',outlab);
    %eval([EPSprint]);





alvl = 0.05;
disp('rank sum sig')
[sh,p] = kstest2(MCSmaxpfarea_smallMPatmcsi(:),MCSmaxpfarea_largeMPatmcsi(:),'Alpha',alvl);
% text(8,90,['K-S test at ', num2str(alvl),' significance lvl:'])
if(sh == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p)])
elseif(sh == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p)]) 
end
disp('rank sum sig')
[p2,sh2] = ranksum(MCSmaxpfarea_smallMPatmcsi(:),MCSmaxpfarea_largeMPatmcsi(:),'Alpha',alvl);
text(8,70,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
if(sh2 == 0)
    disp(['Sig diff distributions? NO.  P-val:',num2str(p2)])
elseif(sh2 == 1)
    disp(['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
end











%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%
%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%





%}




















