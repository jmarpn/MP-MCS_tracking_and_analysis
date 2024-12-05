
%%% v5 - renames "SYN", "PSI", etc.  ->  "MP" 
     
%v6: adds reading in MPstats environemtnal vars (AFWA, shear, dynamic,
%kinematic, etc.) and does some side plots (e.g., MP env vars with MCS, vs
%without MCSs.


%   clear all



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
            '2005';   %2
            '2006';
            '2007';
            '2008';
            '2009';
            '2010';
            '2011';
            '2012';   %9
            '2013';
            '2014';   %11
            '2015';
            '2016';   %13
            '2017';
            '2018';
            '2019';
            '2020';
            '2021'];
        

[ay by] = size(YEARS); clear by
        

MP_times = 800;
MP_tracks = 1500;
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
%basetime_MPstats_met_yymmddhhmmss_ALLYRS(:)  = NaN;
dAdt_MPstats_ALLYRS(:)  = NaN;
MotionX_MPstats_ALLYRS(:)  = NaN;
MotionY_MPstats_ALLYRS(:)  = NaN;
maxVOR600_MPstats_ALLYRS(:)  = NaN;
maxW600bpf_MPstats_ALLYRS(:) = NaN;
maxW600_MPstats_ALLYRS(:)= NaN;                 
% meanPW_MPstats_ALLYRS(:)= NaN;
% maxMUCAPE_MPstats_ALLYRS(:)= NaN;
% maxVIWVConv_MPstats_ALLYRS(:)= NaN;
LStracks_perMP_ALLYRS(:)= NaN;

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

MASK_KEEPERS_MP_ALLYRS(:)  = NaN;
MASK_TOSSERS_MP_ALLYRS(:)  = NaN;
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

    matout =  strcat(rootdir,'/matlab/',YEARS(yr,:),'_vorstats_masks_zone_v5b_justmatchupandW.mat')   ;

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
        'pfETH10_MCSstats', 'pfETH30_MCSstats', 'pfETH40_MCSstats', 'pfETH45_MCSstats', 'pfETH50_MCSstats')

    
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
%     meanPW_MPstats_ALLYRS(1:stimes,1:stracks,yr)                    = meanPW_MPstats;
%     maxMUCAPE_MPstats_ALLYRS(1:stimes,1:stracks,yr)                 = maxMUCAPE_MPstats;
%     maxVIWVConv_MPstats_ALLYRS(1:stimes,1:stracks,yr)               = maxVIWVConv_MPstats;
    LStracks_perMP_ALLYRS(1:stimes,1:stracks,yr)                    = LStracks_perMP;

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
        pf_convrate_MCSstats  pf_stratrate_MCSstats pf_convarea_MCSstats pf_stratarea_MCSstats
    
end

basetime_MCSstats_met_yymmddhhmmss_ALLYRS = datetime(basetime_MCSstats_ALLYRS, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;
basetime_MPstats_met_yymmddhhmmss_ALLYRS = datetime(basetime_MPstats_ALLYRS, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;
basetime_LSstats_met_yymmddhhmmss_ALLYRS = datetime(basetime_LSstats_ALLYRS, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss') ;


%%%%% make MP motion dir and speed:
MotionSPD_MPstats_ALLYRS = ( MotionX_MPstats_ALLYRS .* MotionX_MPstats_ALLYRS  +  MotionY_MPstats_ALLYRS .* MotionY_MPstats_ALLYRS ).^0.5 ;
MotionDIR_MPstats_ALLYRS = atan2(MotionY_MPstats_ALLYRS,MotionX_MPstats_ALLYRS) * (180/3.14159) + 180 ;

% %works
% uu = -4;   vv = 0;
% blah = atan2( uu,vv ) ;  blah = blah*(180/3.14159) + 180 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% 
%%%%%%%               Load MPs' era5 env files  
%%%%%%%%%%%%%% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%% load era5 environment files
mpenvdir = '/Users/marq789/Documents/PROJECTS/WACCEM/MPera5envs/';
maxYR = length(YEARS);
maxT = 800;
maxN  = 1500;

meanMUCAPE_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);   meanMUCAPE_MPstats_ALLYRS(:) = NaN;
maxMUCAPE_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);    maxMUCAPE_MPstats_ALLYRS(:) = NaN;
meanMUCIN_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);    meanMUCIN_MPstats_ALLYRS(:) = NaN;
minMUCIN_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);     minMUCIN_MPstats_ALLYRS(:) = NaN;
meanMULFC_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);    meanMULFC_MPstats_ALLYRS(:) = NaN;
meanMUEL_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);     meanMUEL_MPstats_ALLYRS(:) = NaN;
meanPW_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);       meanPW_MPstats_ALLYRS(:) = NaN;
maxPW_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);        maxPW_MPstats_ALLYRS(:) = NaN;
minPW_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);        minPW_MPstats_ALLYRS(:) = NaN;

meanshearmag0to2_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);    meanshearmag0to2_MPstats_ALLYRS(:) = NaN;
maxshearmag0to2_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);     maxshearmag0to2_MPstats_ALLYRS(:) = NaN;
meanshearmag0to6_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);    meanshearmag0to6_MPstats_ALLYRS(:) = NaN;
maxshearmag0to6_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);     maxshearmag0to6_MPstats_ALLYRS(:) = NaN;
meanshearmag2to9_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);    meanshearmag2to9_MPstats_ALLYRS(:) = NaN;
maxshearmag2to9_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);     maxshearmag2to9_MPstats_ALLYRS(:) = NaN;
meanOMEGA600_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);        meanOMEGA600_MPstats_ALLYRS(:) = NaN;
minOMEGA600_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);         minOMEGA600_MPstats_ALLYRS(:) = NaN;
minOMEGAsub600_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);      minOMEGAsub600_MPstats_ALLYRS(:) = NaN;
meanVIWVD_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);           meanVIWVD_MPstats_ALLYRS(:) = NaN;
minVIWVD_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);            minVIWVD_MPstats_ALLYRS(:) = NaN;
maxVIWVD_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);            maxVIWVD_MPstats_ALLYRS(:) = NaN;
meanDIV750_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);          meanDIV750_MPstats_ALLYRS(:) = NaN;
minDIV750_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);           minDIV750_MPstats_ALLYRS(:) = NaN;
minDIVsub600_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);        minDIVsub600_MPstats_ALLYRS(:) = NaN;

meanWNDSPD600_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);       meanWNDSPD600_MPstats_ALLYRS(:) = NaN;
meanWNDDIR600_MPstats_ALLYRS = zeros(maxT,maxN,maxYR);       meanWNDDIR600_MPstats_ALLYRS(:) = NaN;

% meanWNDSPD600
% meanWNDDIR600


%AFWA MP vars
for yr = 1 : maxYR

      %  yr  = 11

    if(yr == 11) %pending: 2014    %%%% 2014 times out at 24 hours wallclock! Ugh, will probably have to spli

        %dont log anything beyond NANs
%         meanMUCAPE_MPstats_ALLYRS(:,:,yr) = NaN;
%         maxMUCAPE_MPstats_ALLYRS(:,:,yr) = NaN;
%         meanMUCIN_MPstats_ALLYRS(:,:,yr) = NaN;
%         minMUCIN_MPstats_ALLYRS(:,:,yr) = NaN;
%         meanMULFC_MPstats_ALLYRS(:,:,yr) = NaN;
%         meanMUEL_MPstats_ALLYRS(:,:,yr) = NaN;
%         meanPW_MPstats_ALLYRS(:,:,yr) = NaN;
%         maxPW_MPstats_ALLYRS(:,:,yr) = NaN;
%         minPW_MPstats_ALLYRS(:,:,yr) = NaN;
        afwainfile = [mpenvdir,'/piecewise/AFWA_',num2str(YEARS(yr,:)),'_piecewise.nc'] ;
        dum = ncread( afwainfile, 'meanMUCAPE' )  ; [tims tracks] = size(dum);
        %tracks = tracks(end)+1 ; %stupid zero index!

        meanMUCAPE_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'meanMUCAPE');
        maxMUCAPE_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'maxMUCAPE');
        meanMUCIN_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'meanMUCIN');
        minMUCIN_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'minMUCIN');
        meanMULFC_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'meanMULFC');
        meanMUEL_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'meanMUEL');
        meanPW_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'meanPW');
        maxPW_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'maxPW');
        minPW_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'minPW');

    else
        afwainfile = [mpenvdir,'mp_tracks_era5_afwa_',num2str(YEARS(yr,:)),'0501.0000_',num2str(YEARS(yr,:)),'0831.2300.nc'] ;
        tracks = ncread( afwainfile, 'tracks' )  ;
        tracks = tracks(end)+1 ; %stupid zero index!

        meanMUCAPE_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'meanMUCAPE');
        maxMUCAPE_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'maxMUCAPE');
        meanMUCIN_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'meanMUCIN');
        minMUCIN_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'minMUCIN');
        meanMULFC_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'meanMULFC');
        meanMUEL_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'meanMUEL');
        meanPW_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'meanPW');
        maxPW_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'maxPW');
        minPW_MPstats_ALLYRS(:,1:tracks,yr) = ncread(afwainfile,'minPW');
    end
end

%apply MASK_TOSSERS_MP (geo-fence deletion) as was dont for analogous variables in the earlier versions of the preceeding .m file code:
for yr = 1:maxYR
    kills = MASK_TOSSERS_MP_ALLYRS(:,yr); kills(isnan(kills)) = [];
    meanMUCAPE_MPstats_ALLYRS(:, kills, yr) = NaN;
    maxMUCAPE_MPstats_ALLYRS(:, kills, yr) = NaN;
    meanMUCIN_MPstats_ALLYRS(:, kills, yr) = NaN;
    minMUCIN_MPstats_ALLYRS(:, kills, yr) = NaN;
    meanMULFC_MPstats_ALLYRS(:, kills, yr) = NaN;
    meanMUEL_MPstats_ALLYRS(:, kills, yr) = NaN;
    meanPW_MPstats_ALLYRS(:, kills, yr) = NaN;
    maxPW_MPstats_ALLYRS(:, kills, yr) = NaN;
    minPW_MPstats_ALLYRS(:, kills, yr) = NaN;
end


%%% quick correction;  PW isn't actually PW, it's era5's total column vapor, convert to PW here by dividing by density of water: 
% will now be units of meters
meanPW_MPstats_ALLYRS = meanPW_MPstats_ALLYRS / 998.0;
maxPW_MPstats_ALLYRS = maxPW_MPstats_ALLYRS / 998.0;
minPW_MPstats_ALLYRS = minPW_MPstats_ALLYRS / 998.0;


%%%%%%%%%%%%%%% now shear/dyn MP vars

for yr = 1 : maxYR

    if( yr==2 | yr==9 | yr==11 | yr==13 ) %pending: 2014    %%%% 2014 times out at 24 hours wallclock! Ugh, will probably have to spli

        %dont log anything beyond NANs
%         meanMUCAPE_MPstats_ALLYRS(:,:,yr) = NaN;
%         maxMUCAPE_MPstats_ALLYRS(:,:,yr) = NaN;
%         meanMUCIN_MPstats_ALLYRS(:,:,yr) = NaN;
%         minMUCIN_MPstats_ALLYRS(:,:,yr) = NaN;
%         meanMULFC_MPstats_ALLYRS(:,:,yr) = NaN;
%         meanMUEL_MPstats_ALLYRS(:,:,yr) = NaN;
%         meanPW_MPstats_ALLYRS(:,:,yr) = NaN;
%         maxPW_MPstats_ALLYRS(:,:,yr) = NaN;
%         minPW_MPstats_ALLYRS(:,:,yr) = NaN;
        dyninfile = [mpenvdir,'/piecewise/KINEM_',num2str(YEARS(yr,:)),'_piecewise.nc'] ;
        dum = ncread( dyninfile, 'meanWNDSPD600' )  ; [tims tracks] = size(dum);
        %tracks = tracks(end)+1 ; %stupid zero index!

        meanshearmag0to2_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'meanshearmag0to2');
        maxshearmag0to2_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'maxshearmag0to2');
        meanshearmag0to6_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'meanshearmag0to6');
        maxshearmag0to6_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'maxshearmag0to6');
        meanshearmag2to9_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'meanshearmag2to9');
        maxshearmag2to9_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'maxshearmag2to9');
        meanOMEGA600_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'meanOMEGA600');
        minOMEGA600_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'minOMEGA600');
        minOMEGAsub600_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'minOMEGAsub600');
        meanVIWVD_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'meanVIWVD');
        minVIWVD_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'minVIWVD');
        maxVIWVD_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'maxVIWVD');
        meanDIV750_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'meanDIV750');
        minDIV750_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'minDIV750');
        minDIVsub600_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'minDIVsub600');

        %wininfile = [mpenvdir,'/piecewise/KINEM_',YRLIST(YY,:),'_piecewise.nc'] ;
        meanWNDSPD600_MPstats_ALLYRS(:,1:tracks,yr)  = ncread(dyninfile,'meanWNDSPD600');    
        meanWNDDIR600_MPstats_ALLYRS(:,1:tracks,yr)  = ncread(dyninfile,'meanWNDDIR600');  

    else
        dyninfile = [mpenvdir,'mp_tracks_era5_Dyn_',num2str(YEARS(yr,:)),'0501.0000_',num2str(YEARS(yr,:)),'0831.2300.nc'] ;
        tracks = ncread( dyninfile, 'tracks' )  ;
        tracks = tracks(end)+1 ; %stupid zero index!

        meanshearmag0to2_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'meanshearmag0to2');
        maxshearmag0to2_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'maxshearmag0to2');
        meanshearmag0to6_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'meanshearmag0to6');
        maxshearmag0to6_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'maxshearmag0to6');
        meanshearmag2to9_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'meanshearmag2to9');
        maxshearmag2to9_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'maxshearmag2to9');
        meanOMEGA600_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'meanOMEGA600');
        minOMEGA600_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'minOMEGA600');
        minOMEGAsub600_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'minOMEGAsub600');
        meanVIWVD_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'meanVIWVD');
        minVIWVD_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'minVIWVD');
        maxVIWVD_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'maxVIWVD');
        meanDIV750_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'meanDIV750');
        minDIV750_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'minDIV750');
        minDIVsub600_MPstats_ALLYRS(:,1:tracks,yr) = ncread(dyninfile,'minDIVsub600');


        wininfile = [mpenvdir,'mp_tracks_era5_win_',num2str(YEARS(yr,:)),'0501.0000_',num2str(YEARS(yr,:)),'0831.2300.nc'] ;
        meanWNDSPD600_MPstats_ALLYRS(:,1:tracks,yr)  = ncread(wininfile,'meanWNDSPD600');    
        meanWNDDIR600_MPstats_ALLYRS(:,1:tracks,yr)  = ncread(wininfile,'meanWNDDIR600');   

    end
end

%  meblah = meanshearmag0to2_MPstats_ALLYRS(:,:,12) ; 

%apply MASK_TOSSERS_MP (geo-fence deletion) as was dont for analogous variables in the earlier versions of the preceeding .m file code:
for yr = 1:maxYR
    kills = MASK_TOSSERS_MP_ALLYRS(:,yr); kills(isnan(kills)) = [];
    meanshearmag0to2_MPstats_ALLYRS(:, kills, yr) = NaN;
    maxshearmag0to2_MPstats_ALLYRS(:, kills, yr) = NaN;
    meanshearmag0to6_MPstats_ALLYRS(:, kills, yr) = NaN;
    maxshearmag0to6_MPstats_ALLYRS(:, kills, yr) = NaN;
    meanshearmag2to9_MPstats_ALLYRS(:, kills, yr) = NaN;
    maxshearmag2to9_MPstats_ALLYRS(:, kills, yr) = NaN;
    meanOMEGA600_MPstats_ALLYRS(:, kills, yr) = NaN;
    minOMEGA600_MPstats_ALLYRS(:, kills, yr) = NaN;
    minOMEGAsub600_MPstats_ALLYRS(:, kills, yr) = NaN;
    meanVIWVD_MPstats_ALLYRS(:, kills, yr) = NaN;
    minVIWVD_MPstats_ALLYRS(:, kills, yr) = NaN;
    maxVIWVD_MPstats_ALLYRS(:, kills, yr) = NaN;
    meanDIV750_MPstats_ALLYRS(:, kills, yr) = NaN;
    minDIV750_MPstats_ALLYRS(:, kills, yr) = NaN;
    minDIVsub600_MPstats_ALLYRS(:, kills, yr) = NaN;

    meanWNDSPD600_MPstats_ALLYRS(:, kills, yr) = NaN;
    meanWNDDIR600_MPstats_ALLYRS(:, kills, yr) = NaN;
end






%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% more QC
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

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
                    maxW600_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    maxW600bpf_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    %meanPW_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    rainrate_heavyrain_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    speed_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    status_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    stratrain_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 
                    totalrain_MCSstats_ALLYRS(:,MASK_KEEPERS_MCS_ALLYRS(n,y),y) = NaN; 

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
for yr = 1:18
    yr
    tracktokill = find( (isnan(MPtracks_perMCS_ALLYRS(1,:,yr))==0   &  isnan(convrain_MCSstats_ALLYRS(1,:,yr))==1)==1  ) 
    MPtracks_perMCS_ALLYRS(:,tracktokill,yr) = NaN;
end








%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  

%%%%%%%%%%%%%        PLOTS  ANALYSIS   PLOTS   ANALYSIS   PLOTS

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






num_all_mcs = length(find(isnan(duration_MCSstats_ALLYRS)==0))




%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Some resulting big-picture stats stuff:
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%MCSs:
mcs_preLSfilter = MPtracks_perMCS_ALLYRS(2,:,:); mcs_preLSfilter = mcs_preLSfilter(:);  %find number of mcss that either have an MP or dont (ignoring the nans)
num_mcs_preLSfilter = length(  find(isnan(mcs_preLSfilter)==0)  ) 

filt_MCS = MPtracks_perMCS_ALLYRS .* mask_kill_mcs_because_LS_present_early .* mask_kill_mcs_because_MP_has_an_LS ;   
mcs_postLSfilter = filt_MCS(2,:,:) ; mcs_postLSfilter = mcs_postLSfilter(:);
num_mcs_postLSfilter = length(  find(isnan(mcs_postLSfilter)==0)  ) 





%MPs:

%oops: MPstats not yet filtered on CONUS domain in previous .m file?. Will have to add that later. until then, I will jerry-rig it
% by using an already filtered field to conjure a mask for LStracks_perMP:
maskMP =  permute(meanlon_MPstats_ALLYRS(1,:,:),[2 3 1]); maskMP(isnan(maskMP)==0) =1;   maskMP = maskMP(:);
%mp_preLSfilter = permute(LStracks_perMP_ALLYRS(1,:,:),[2 3 1]); mp_preLSfilter = mp_preLSfilter(:);
num_mp_preLSfilter = length(  find(maskMP==1) )  

maskMP = permute(meanlon_MPstats_ALLYRS(1,:,:),[2 3 1]) .* mask_kill_mp_because_LS_present;  maskMP(isnan(maskMP)==0) =1;  maskMP = maskMP(:);
num_mp_postLSfilter = length(  find(maskMP==1) )  



% blah  = permute(meanlon_MPstats_ALLYRS(1,:,:),[2 3 1]); 
% blah2 = mask_kill_mp_because_LS_present; 












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
    % Now work to keep only the MP stats values that dont have an LS present at some
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
    duration_MPstats_ALLYRS                     = duration_MPstats_ALLYRS .* mask_kill_mp_because_LS_present ;
    %LStracks_perMP_ALLYRS =
    %basetime_MPstats_met_yymmddhhmmss_ALLYRS    = basetime_MPstats_met_yymmddhhmmss_ALLYRS .* mask800_kill_mp_because_LS_present ; 
    MotionSPD_MPstats_ALLYRS =    MotionSPD_MPstats_ALLYRS  .*  mask800_kill_mp_because_LS_present ;
    MotionDIR_MPstats_ALLYRS =    MotionDIR_MPstats_ALLYRS  .*  mask800_kill_mp_because_LS_present ;

    meanMUCAPE_MPstats_ALLYRS      = meanMUCAPE_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxMUCAPE_MPstats_ALLYRS       = maxMUCAPE_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanMUCIN_MPstats_ALLYRS       = meanMUCIN_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minMUCIN_MPstats_ALLYRS        = minMUCIN_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanMULFC_MPstats_ALLYRS       = meanMULFC_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanMUEL_MPstats_ALLYRS        = meanMUEL_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanPW_MPstats_ALLYRS          = meanPW_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxPW_MPstats_ALLYRS           = maxPW_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minPW_MPstats_ALLYRS           = minPW_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;

    meanshearmag0to2_MPstats_ALLYRS   = meanshearmag0to2_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxshearmag0to2_MPstats_ALLYRS    = maxshearmag0to2_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanshearmag0to6_MPstats_ALLYRS   = meanshearmag0to6_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxshearmag0to6_MPstats_ALLYRS    = maxshearmag0to6_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanshearmag2to9_MPstats_ALLYRS   = meanshearmag2to9_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxshearmag2to9_MPstats_ALLYRS    = maxshearmag2to9_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanOMEGA600_MPstats_ALLYRS       = meanOMEGA600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minOMEGA600_MPstats_ALLYRS        = minOMEGA600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minOMEGAsub600_MPstats_ALLYRS     = minOMEGAsub600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanVIWVD_MPstats_ALLYRS          = meanVIWVD_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minVIWVD_MPstats_ALLYRS           = minVIWVD_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    maxVIWVD_MPstats_ALLYRS           = maxVIWVD_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanDIV750_MPstats_ALLYRS         = meanDIV750_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minDIV750_MPstats_ALLYRS          = minDIV750_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    minDIVsub600_MPstats_ALLYRS       = minDIVsub600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;

    meanWNDSPD600_MPstats_ALLYRS = meanWNDSPD600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;
    meanWNDDIR600_MPstats_ALLYRS = meanWNDDIR600_MPstats_ALLYRS .* mask800_kill_mp_because_LS_present ;



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

meanPW_MPstats_ALLYRS          = meanPW_MPstats_ALLYRS *1000 ;
maxPW_MPstats_ALLYRS           = maxPW_MPstats_ALLYRS  *1000 ;
minPW_MPstats_ALLYRS           = minPW_MPstats_ALLYRS *1000 ;





% filter MPtracks_perMCS_ALLYRS on PW24
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




%   blah_mcs = datetime( basetime_MCSstats_ALLYRS( notnan(1:2),n,y ), 'convertfrom','posixtime','Format','dd-MM-y-HH') 
%   blah_mcs = datetime( basetime_MCSstats_ALLYRS( :,n,y ), 'convertfrom','posixtime','Format','dd-MM-y-HH') 







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



%by this point, the env vars have faced the following filtering (above):
% i) MASK_TOSSER (geofence 1) filtering 
% ii) anti-LS MP filtering
%
%
% They have not faced filters (below):
% i) secondary geofence filtering when splitting up MPwith and MPwithoutMCS
% ii) filterint MP with PW < 24mm
%

matvarsout = [imout,'/SemiprocessedEnvVars.mat']
%/Volumes/LaCie/WACCEM/datafiles/Bandpass//images/SemiprocessedEnvVars.mat
save(matvarsout,'meanMUCAPE_MPstats_ALLYRS',...
    'maxMUCAPE_MPstats_ALLYRS',...
    'meanMUCIN_MPstats_ALLYRS',...
    'minMUCIN_MPstats_ALLYRS',...
    'meanMULFC_MPstats_ALLYRS',...
    'meanMUEL_MPstats_ALLYRS',...
    'meanPW_MPstats_ALLYRS',...
    'maxPW_MPstats_ALLYRS',...
    'minPW_MPstats_ALLYRS',...  
    'meanshearmag0to2_MPstats_ALLYRS',...
    'maxshearmag0to2_MPstats_ALLYRS',...
    'meanshearmag0to6_MPstats_ALLYRS',...
    'maxshearmag0to6_MPstats_ALLYRS',...
    'meanshearmag2to9_MPstats_ALLYRS',...
    'maxshearmag2to9_MPstats_ALLYRS',...
    'meanOMEGA600_MPstats_ALLYRS',...
    'minOMEGA600_MPstats_ALLYRS',...
    'minOMEGAsub600_MPstats_ALLYRS',...
    'meanVIWVD_MPstats_ALLYRS',...
    'minVIWVD_MPstats_ALLYRS',...
    'maxVIWVD_MPstats_ALLYRS',...
    'meanDIV750_MPstats_ALLYRS',...
    'minDIV750_MPstats_ALLYRS',...
    'minDIVsub600_MPstats_ALLYRS',...
    'meanWNDSPD600_MPstats_ALLYRS',...
    'meanWNDDIR600_MPstats_ALLYRS');


%%





dualpol_colmap










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

numMCSI_with_LS = length(find(isnan(duration_MCSstats_ALLYRS_YESLS)==0))
numMCSI_without_LS = length(find(isnan(duration_MCSstats_ALLYRS_NOLS)==0))
num_all_MCSI = numMCSI_with_LS + numMCSI_without_LS

length(MCSI_without_MP) +  length(MCSI_with_MP)  % 
length(MCSI_without_MP)   % 
length(MCSI_with_MP)      % size not allowing multiple MDs present at MCSI
length(MCSI_with_multiMP) % size allowing multiple MDs present at MCSI events





% %%%%%%%%%%%%   mapped histogram of MCSI locations with MP object present
% 
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% 
% title([' Locations of MCSI events that have MP objects present'])
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
% % overlay density kernel of MCSIs with MP obs 
% [pdfx xi]= ksdensity(MCSI_withMP_lon);
% [pdfy yi]= ksdensity(MCSI_withMP_lat);
% [xxi,yyi]     = meshgrid(xi,yi);
% [pdfxx,pdfyy] = meshgrid(pdfx,pdfy);
% pdfxy = pdfxx.*pdfyy; 
% contour(ax5,xxi,yyi,pdfxy,8,'--r','LineWidth',0.5)
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
% axis([-170 -50 20 60])
% 
% %%%%%%%% image out:
% 
% %saveas(ff,horzcat(imout,'/MCSIorigins_withMP.png'));
% 
% outlab = horzcat(imout,'/MCSIorigins_withMP_filtLS',num2str(filteroutLS),'.eps');
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);













% 
% %%%%%%%%%%%%   mapped histogram of MCSI locations without MP object present
% 
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% 
% title([' Locations of MCSI events that DO NOT have MP objects present'])
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% histogram2(ax2, MCSI_withoutMP_lon, MCSI_withoutMP_lat,[-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 25])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% 
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] , 'LineColor', [0 0.7 0] , 'LineWidth', 1.25 ) %'FaceColor', 'k')%'none','LineColor','k')
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% xlabel(ax1,'latitude')
% ylabel(ax1,'longitude')
% 
% axis([-170 -50 15 60])
% 
% %%%%%%%% image out:
% 
% %saveas(ff,horzcat(imout,'/MCSIorigins_withoutMP.png'));
% 
% outlab = horzcat(imout,'/MCSIorigins_withoutMP_filtLS',num2str(filteroutLS),'.eps');
% EPSprint = horzcat('print -painters -depsc ',outlab);
% % %eval([EPSprint]);
% 
% 
% 
% %%%%%%%%%%%%%%%%
% %%% are MCSI locations with and without MP objs statistically different?
% %%%%%%%%%%%%%%%%
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







% 
% %%%%%%%%%%%%   mapped histogram of all MCSI locations
% 
% ff = figure  
% ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% 
% title([' Locations of all MCSI events. filtLS=',num2str(filteroutLS)])
% 
% ax1 = axes; 
% ax2 = axes; 
% ax3 = axes; 
% linkaxes([ax1,ax2,ax3],'xy'); 
% 
% plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
% hold on
% 
% lon1 = meanlon_MCSstats_ALLYRS(1,:,:);    lat1 = meanlat_MCSstats_ALLYRS(1,:,:); 
% histogram2(ax2, lon1(:), lat1(:), [-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
% colormap(ax2,flipud(creamsicle2))   
% caxis(ax2,[1 50])
% view(ax2,0,90)
% cb = colorbar(ax2)
% agr=get(cb); %gets properties of colorbar
% aa = agr.Position; %gets the positon and size of the color bar
% set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
% hold on
% 
% load coastlines
% plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);  
% 
% hold on
% 
% load topo topo 
% highelev = topo ;
% highelev(topo < 1500) = 0;
% contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] , 'LineColor', [0 0.7 0] , 'LineWidth', 1.25 ) %'FaceColor', 'k')%'none','LineColor','k')
% 
% xlabel(ax1,'latitude')
% ylabel(ax1,'longitude')
% 
% set(ax2,'Color','None')       %p
% set(ax2, 'visible', 'off');   %p
% 
% set(ax3,'Color','None')       %p
% set(ax3, 'visible', 'off');   %p
% 
% 
% 
% axis([-170 -50 15 60])
% 
% %%%%%%%% image out:
% 
% saveas(ff,horzcat(imout,'/MCSIorigins_allevents_filtLS',num2str(filteroutLS),'.png'));
% 
% outlab = horzcat(imout,'/MCSIorigins_allevents_filtLS',num2str(filteroutLS),'.png');
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);
% 
% 
% 
% if(  filteroutLS ==  1)
%     %%%%%%%%%%%%   mapped histogram of all MCSI locations
% 
%     ff = figure
%     ff.Position = [166.9156895252448,56.10000000000002,995.0743029389615,415.6500000000002];
% 
%     title([' Locations of MCSI events WITHLS. filtLS=',num2str(filteroutLS)])
% 
%     ax1 = axes;
%     ax2 = axes;
%     ax3 = axes;
%     linkaxes([ax1,ax2,ax3],'xy');
% 
%     plot(ax1,polyshape([-170 -170  -50  -50],[15 65 65 15]))
%     hold on
% 
%     lon1 = meanlon_MCSstats_ALLYRS_YESLS(1,:,:);    lat1 = meanlat_MCSstats_ALLYRS_YESLS(1,:,:);
%     histogram2(ax2, lon1(:), lat1(:), [-180:2:-50],[20:2:60],'FaceColor','flat', 'LineStyle','none') %'CDataMode','auto','FaceColor','interp');
%     colormap(ax2,flipud(creamsicle2))
%     caxis(ax2,[1 25])
%     view(ax2,0,90)
%     cb = colorbar(ax2)
%     agr=get(cb); %gets properties of colorbar
%     aa = agr.Position; %gets the positon and size of the color bar
%     set(cb,'Position',[aa(1)+0.05 aa(2) aa(3) aa(4)])
%     hold on
% 
%     load coastlines
%     plot(ax3,coastlon,coastlat,'Color',[0.4 0.2 0],'LineWidth',1.5);
% 
%     hold on
% 
%     load topo topo
%     highelev = topo ;
%     highelev(topo < 1500) = 0;
%     contour(ax3,[0 : 359]-360 , [-89 : 90], highelev, [1600 :500: 5000] , 'LineColor', [0 0.7 0] , 'LineWidth', 1.25 ) %'FaceColor', 'k')%'none','LineColor','k')
% 
%     xlabel(ax1,'latitude')
%     ylabel(ax1,'longitude')
% 
%     set(ax2,'Color','None')       %p
%     set(ax2, 'visible', 'off');   %p
% 
%     set(ax3,'Color','None')       %p
%     set(ax3, 'visible', 'off');   %p
% 
% 
% 
%     axis([-170 -50 15 60])
% 
%     %%%%%%%% image out:
% 
%     saveas(ff,horzcat(imout,'/MCSIorigins_allevents_WITHLS_filtLS',num2str(filteroutLS),'.png'));
% 
%     outlab = horzcat(imout,'/MCSIorigins_allevents_WITHLS_filtLS',num2str(filteroutLS),'.png');
%     EPSprint = horzcat('print -painters -depsc ',outlab);
%     %eval([EPSprint]);
% 
% end









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% 3)  SOME NUMBERY STATSY THINGS
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%% number of MCSs events with(out) synoptic objects

PERCENT_MCSI_with_MP = length(MCSI_with_MP)/( length(MCSI_with_MP) + length(MCSI_without_MP)) * 100 
PERCENT_MCSI_without_MP = length(MCSI_without_MP)/( length(MCSI_with_MP) + length(MCSI_without_MP)) * 100 

NUM_mcsi_with_allowmultiMP =  length(MCSI_with_MP) + length(MCSI_without_MP)   %can be repeated MP objs (touching multiple MCSI events)
NUM_mcsi_with_allowmultiMP =  length(MCSI_with_multiMP) + length(MCSI_without_MP) 

%%%% number of syn objects touching an MCS where synoptic object is made
%%%% AFTER MCSI. Note, this doesnt necessarily mean that the MCS MAKES the
%%%% syn object (it could mean that a previously made syn obj just cross
%%%% paths with the MCS - so you have to make sure that the syn
%%%% object formed after the MCS did. 

% blah = MPtracks_perMCS_ALLYRS(:,:,1);

MPobjs_formed_after_mcsi = [];   % tabulated list of MP objects touching mcs which formed after MCSI period
MPobjs_formed_by_mcs_and_present_at_subsequent_mcsi = [];  % tally of MP objs "made" by an MCS goes on to be present at a subsequent MCS's birth. currently includes duplicate syn objs per year if they go on to "make" multiple MCSs. It's most useful for number of times a syn object is made by MCS then goes on to  makes MCS
MPobjs_concidentaloverlap_after_mcsi = []; %tally of MP object numbers that may look like they are formed by an MCS post MCSI, but really, the syn objects formed prior to MCSI and there is conincidental spatiotemporal overlap with an MCS after MCSI

for y = 1:mcs_years
    
    
    for n = 2:mcs_tracks  %starts at 2 because of the step below when looking for syn objs in prior-occuring  MCSs
        
        %         y = 1
        %         n = 90 %110
        
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
                    
                    %record the syn obj:
                    MPobjs_formed_after_mcsi = cat(1, MPobjs_formed_after_mcsi, currpostmcs(s)  ) ;
                    
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


%filter MP_with(out)_MCS on PW24 and noLS here:

%need to filter MP_with_MCS on noLS & PW24 thresholds
%  MP_with_MCSs_ALLYRS_before = MP_with_MCSs_ALLYRS;
%  MP_without_MCSs_ALLYRS_before = MP_without_MCSs_ALLYRS;
%  MP_with_MCSs_ALLYRS =   MP_with_MCSs_ALLYRS_before;

%%wrongly done:
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
        %n = 40; y = 1; n = 2
        mp =  MP_with_MCSs_ALLYRS(n,y) ;
        if( isnan(mp)==0   &     mean(   meanPW_MPstats_ALLYRS(:,mp,y), 'omitnan'   ) < 24.0        )  
            MP_with_MCSs_ALLYRS(n,y) = NaN;
        end

        mp =  MP_without_MCSs_ALLYRS(n,y) ;
        if( isnan(mp)==0   &     mean(   meanPW_MPstats_ALLYRS(:,mp,y), 'omitnan'   ) < 24.0        )  
            MP_without_MCSs_ALLYRS(n,y) = NaN;
        end

    end
end

%m2 = MP_with_MCSs_ALLYRS;





% post-process the resuts:

%collate the syn objs each year touching an MCS into one long array
total_MP_touching_mcss = [];
for y = 1:mcs_years
    total_MP_touching_mcss = cat(1,total_MP_touching_mcss, MP_with_MCSs_ALLYRS( find( isnan(MP_with_MCSs_ALLYRS(:,y))==0 ),y)  ) ;
end

% %MP objects touching an MCS but form after MCSI
% PERCENT_MPtouchingmcs_formed_after_mcsi = 100 * ( length(MPobjs_formed_after_mcsi) / length(total_MP_touching_mcss) ) 
% 
% PERC_MPtouchingmcs_formed_by_mcs_and_present_at_subseq_mcsi = 100 * ( length(MPobjs_formed_by_mcs_and_present_at_subsequent_mcsi) / length(total_MP_touching_mcss) ) 
% 
% PERCENT_MPtouchingmcs_concidentaloverlap_after_mcsi = 100 * ( length(MPobjs_concidentaloverlap_after_mcsi) / length(total_MP_touching_mcss) ) 


% TotalMP_ALLTRACKEDMPOBJS = length(find(isnan(duration_MPstats_ALLYRS)==0))    
% TotalMP_INMCSCONUSdom = length( find(isnan(MASK_KEEPERS_MP_ALLYRS)==0) )  
% %TotalMP_INMCSCONUSdom = length( find(isnan(MASK_zone_ALLYRS)==0) )
% TotalMP_TouchingMCS = length(total_MP_touching_mcss)  

%add up the number of unique mp objs present at MCSi each year:
NumUniqueMP_presentatMCSI = [];
for y = 1:1:mcs_years
    % y = 2
    curryr = MPtracks_perMCS_ALLYRS(1:2,:,y) ;
    NumUniqueMP_presentatMCSI = vertcat( NumUniqueMP_presentatMCSI , length( unique(   curryr(find(curryr > 1)) )    ) ) ;
end
TotalUniqueMP_presentAtMCSI = sum(NumUniqueMP_presentatMCSI);

% % % %diagnostics: 
% blah_sfpi = datetime(basetime_MPstats_ALLYRS(1,500,1), 'convertfrom','posixtime','Format','dd-MM-y-HH') 
% blah_mcs = datetime(basetime_MCSstats_ALLYRS(:,:,:),'convertfrom','posixtime','Format','dd-MM-y-HH') ;
% blah_sybmcsi =    MPatMCSI_perMCS_ALLYRS(:,:,1); 









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%% duration of MP objects PRIOR to MCSi time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


mpI_vs_mcsI_dt = [];  % tabulated list of the time differential (hours) between MCSI and synoptic object formation for those that are present at MCSI birth
MPPREDURatMCSI_ALLYRS = zeros(mcs_tracks,mcs_years) ;    MPPREDURatMCSI_ALLYRS(:) = NaN;   % same as 1 line above, just in MCS(track,year) space. 

for y = 1 : mcs_years % which is same as num years of syn objects)
    for n = 1 : mcs_tracks
             
        mpobjs = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ;      % synoptic object(s) number (or lack thereof) for this MCSI event
        
        for u = 1:length(mpobjs)   %note, there could be more than one syn obj present at MCSI because of calling MCSI period as t = 1-2 of MCS
            if(  isempty( mpobjs(u) ) == 0  & isnan( mpobjs(u) ) == 0  &  mpobjs(u) > 0 )  
                
                mpItime = basetime_MPstats_ALLYRS(1, mpobjs(u)  , y) ;   %MP obj initiation time for this MCS
                mcsItime = basetime_MCSstats_ALLYRS(1, n, y) ;   %MP obj initiation time for this MCS
                
                mpI_vs_mcsI_dt = vertcat( mpI_vs_mcsI_dt , (mcsItime - mpItime)/3600  ) ;  % [HOURS]   %you could alter this loop to make this variable in the format of MCSstats arrays if you want to.
                MPPREDURatMCSI_ALLYRS(n,y) = (mcsItime - mpItime)/3600 ;  % logging it in MCS (tracks, year) space
                
            end
        end
        
    end
end
mpI_vs_mcsI_dt(find(mpI_vs_mcsI_dt<0.5)) = 0;
MPPREDURatMCSI_ALLYRS( find(MPPREDURatMCSI_ALLYRS < 0.5) ) = 0;









%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%                
%%%%             Looking at MPs' environmental ERA5 vars (e.g., PW, W, cape, ...)
%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%make more stringent geo-fencing box to
gf_meanMUCAPE_MPstats_ALLYRS   = meanMUCAPE_MPstats_ALLYRS;
gf_maxMUCAPE_MPstats_ALLYRS    = maxMUCAPE_MPstats_ALLYRS;
gf_meanMUCIN_MPstats_ALLYRS    = meanMUCIN_MPstats_ALLYRS;
gf_minMUCIN_MPstats_ALLYRS     = minMUCIN_MPstats_ALLYRS;
gf_meanMULFC_MPstats_ALLYRS    = meanMULFC_MPstats_ALLYRS;
gf_meanMUEL_MPstats_ALLYRS     = meanMUEL_MPstats_ALLYRS;
gf_meanPW_MPstats_ALLYRS       = meanPW_MPstats_ALLYRS;
gf_maxPW_MPstats_ALLYRS        = maxPW_MPstats_ALLYRS;
gf_minPW_MPstats_ALLYRS        = minPW_MPstats_ALLYRS;
gf_meanshearmag0to2_MPstats_ALLYRS   =    meanshearmag0to2_MPstats_ALLYRS;
gf_maxshearmag0to2_MPstats_ALLYRS    =    maxshearmag0to2_MPstats_ALLYRS;
gf_meanshearmag0to6_MPstats_ALLYRS   =    meanshearmag0to6_MPstats_ALLYRS;
gf_maxshearmag0to6_MPstats_ALLYRS    =    maxshearmag0to6_MPstats_ALLYRS;
gf_meanshearmag2to9_MPstats_ALLYRS   =    meanshearmag2to9_MPstats_ALLYRS;
gf_maxshearmag2to9_MPstats_ALLYRS    =    maxshearmag2to9_MPstats_ALLYRS;
gf_meanOMEGA600_MPstats_ALLYRS       =    meanOMEGA600_MPstats_ALLYRS;
gf_minOMEGA600_MPstats_ALLYRS        =    minOMEGA600_MPstats_ALLYRS;
gf_minOMEGAsub600_MPstats_ALLYRS     =    minOMEGAsub600_MPstats_ALLYRS;
gf_meanVIWVD_MPstats_ALLYRS          =    meanVIWVD_MPstats_ALLYRS;
gf_minVIWVD_MPstats_ALLYRS           =    minVIWVD_MPstats_ALLYRS;
gf_maxVIWVD_MPstats_ALLYRS           =    maxVIWVD_MPstats_ALLYRS;
gf_meanDIV750_MPstats_ALLYRS         =    meanDIV750_MPstats_ALLYRS;
gf_minDIV750_MPstats_ALLYRS          =    minDIV750_MPstats_ALLYRS;
gf_minDIVsub600_MPstats_ALLYRS       =    minDIVsub600_MPstats_ALLYRS;
gf_meanWNDSPD600_MPstats_ALLYRS      =    meanWNDSPD600_MPstats_ALLYRS;
gf_meanWNDDIR600_MPstats_ALLYRS      =    meanWNDDIR600_MPstats_ALLYRS;

gf_MotionSPD_MPstats_ALLYRS =       MotionSPD_MPstats_ALLYRS; 
gf_MotionDIR_MPstats_ALLYRS =       MotionDIR_MPstats_ALLYRS;


minlat = 32.;
maxlat = 50;
minlon = -112.  + 360;
maxlon = -80.5  + 360;;
kill = find( meanlat_MPstats_ALLYRS > maxlat | ...
             meanlat_MPstats_ALLYRS < minlat | ... 
             meanlon_MPstats_ALLYRS > maxlon | ...
             meanlon_MPstats_ALLYRS < minlon );

gf_meanMUCAPE_MPstats_ALLYRS(kill)  = NaN;
gf_maxMUCAPE_MPstats_ALLYRS(kill)   = NaN;
gf_meanMUCIN_MPstats_ALLYRS(kill)   = NaN;
gf_minMUCIN_MPstats_ALLYRS(kill)    = NaN;
gf_meanMULFC_MPstats_ALLYRS(kill)   = NaN;
gf_meanMUEL_MPstats_ALLYRS(kill)    = NaN;
gf_meanPW_MPstats_ALLYRS(kill)      = NaN;
gf_maxPW_MPstats_ALLYRS(kill)       = NaN;
gf_minPW_MPstats_ALLYRS(kill)       = NaN;
gf_meanshearmag0to2_MPstats_ALLYRS(kill)       = NaN;
gf_maxshearmag0to2_MPstats_ALLYRS(kill)       = NaN;
gf_meanshearmag0to6_MPstats_ALLYRS(kill)       = NaN;
gf_maxshearmag0to6_MPstats_ALLYRS(kill)       = NaN;
gf_meanshearmag2to9_MPstats_ALLYRS(kill)       = NaN;
gf_maxshearmag2to9_MPstats_ALLYRS(kill)       = NaN;
gf_meanOMEGA600_MPstats_ALLYRS(kill)       = NaN;
gf_minOMEGA600_MPstats_ALLYRS(kill)       = NaN;
gf_minOMEGAsub600_MPstats_ALLYRS(kill)       = NaN;
gf_meanVIWVD_MPstats_ALLYRS(kill)       = NaN;
gf_minVIWVD_MPstats_ALLYRS(kill)       = NaN;
gf_maxVIWVD_MPstats_ALLYRS(kill)       = NaN;
gf_meanDIV750_MPstats_ALLYRS(kill)       = NaN;
gf_minDIV750_MPstats_ALLYRS(kill)       = NaN;
gf_minDIVsub600_MPstats_ALLYRS(kill)       = NaN;
gf_meanWNDSPD600_MPstats_ALLYRS(kill)       = NaN;
gf_meanWNDDIR600_MPstats_ALLYRS(kill)       = NaN;
gf_MotionSPD_MPstats_ALLYRS(kill)       = NaN;
gf_MotionDIR_MPstats_ALLYRS(kill)       = NaN;

%make a set filtered on PW < 24mm (e.g., Fengfei's 2021 paper)
gfpw_meanMUCAPE_MPstats_ALLYRS   = gf_meanMUCAPE_MPstats_ALLYRS;
gfpw_maxMUCAPE_MPstats_ALLYRS    = gf_maxMUCAPE_MPstats_ALLYRS;
gfpw_meanMUCIN_MPstats_ALLYRS    = gf_meanMUCIN_MPstats_ALLYRS;
gfpw_minMUCIN_MPstats_ALLYRS     = gf_minMUCIN_MPstats_ALLYRS;
gfpw_meanMULFC_MPstats_ALLYRS    = gf_meanMULFC_MPstats_ALLYRS;
gfpw_meanMUEL_MPstats_ALLYRS     = gf_meanMUEL_MPstats_ALLYRS;
gfpw_meanPW_MPstats_ALLYRS       = gf_meanPW_MPstats_ALLYRS;
gfpw_maxPW_MPstats_ALLYRS        = gf_maxPW_MPstats_ALLYRS;
gfpw_minPW_MPstats_ALLYRS        = gf_minPW_MPstats_ALLYRS;
gfpw_meanshearmag0to2_MPstats_ALLYRS   =    gf_meanshearmag0to2_MPstats_ALLYRS;
gfpw_maxshearmag0to2_MPstats_ALLYRS    =    gf_maxshearmag0to2_MPstats_ALLYRS;
gfpw_meanshearmag0to6_MPstats_ALLYRS   =    gf_meanshearmag0to6_MPstats_ALLYRS;
gfpw_maxshearmag0to6_MPstats_ALLYRS    =    gf_maxshearmag0to6_MPstats_ALLYRS;
gfpw_meanshearmag2to9_MPstats_ALLYRS   =    gf_meanshearmag2to9_MPstats_ALLYRS;
gfpw_maxshearmag2to9_MPstats_ALLYRS    =    gf_maxshearmag2to9_MPstats_ALLYRS;
gfpw_meanOMEGA600_MPstats_ALLYRS       =    gf_meanOMEGA600_MPstats_ALLYRS;
gfpw_minOMEGA600_MPstats_ALLYRS        =    gf_minOMEGA600_MPstats_ALLYRS;
gfpw_minOMEGAsub600_MPstats_ALLYRS     =    gf_minOMEGAsub600_MPstats_ALLYRS;
gfpw_meanVIWVD_MPstats_ALLYRS          =    gf_meanVIWVD_MPstats_ALLYRS;
gfpw_minVIWVD_MPstats_ALLYRS           =    gf_minVIWVD_MPstats_ALLYRS;
gfpw_maxVIWVD_MPstats_ALLYRS           =    gf_maxVIWVD_MPstats_ALLYRS;
gfpw_meanDIV750_MPstats_ALLYRS         =    gf_meanDIV750_MPstats_ALLYRS;
gfpw_minDIV750_MPstats_ALLYRS          =    gf_minDIV750_MPstats_ALLYRS;
gfpw_minDIVsub600_MPstats_ALLYRS       =    gf_minDIVsub600_MPstats_ALLYRS;
gfpw_meanWNDSPD600_MPstats_ALLYRS      =    gf_meanWNDSPD600_MPstats_ALLYRS;
gfpw_meanWNDDIR600_MPstats_ALLYRS      =    gf_meanWNDDIR600_MPstats_ALLYRS;
gfpw_MotionSPD_MPstats_ALLYRS  =  gf_MotionSPD_MPstats_ALLYRS;
gfpw_MotionDIR_MPstats_ALLYRS  =  gf_MotionDIR_MPstats_ALLYRS;

kill = find( gfpw_meanPW_MPstats_ALLYRS < 24.0) ;
%kill = find( gfpw_meanPW_MPstats_ALLYRS < 0.024) ;
gfpw_meanMUCAPE_MPstats_ALLYRS(kill) = NaN;
gfpw_maxMUCAPE_MPstats_ALLYRS(kill) = NaN;
gfpw_meanMUCIN_MPstats_ALLYRS(kill) = NaN;
gfpw_minMUCIN_MPstats_ALLYRS(kill) = NaN;
gfpw_meanMULFC_MPstats_ALLYRS(kill) = NaN;
gfpw_meanMUEL_MPstats_ALLYRS(kill) = NaN;
gfpw_meanPW_MPstats_ALLYRS(kill) = NaN;
gfpw_maxPW_MPstats_ALLYRS(kill) = NaN;
gfpw_minPW_MPstats_ALLYRS(kill) = NaN;
gfpw_meanshearmag0to2_MPstats_ALLYRS(kill) = NaN;
gfpw_maxshearmag0to2_MPstats_ALLYRS(kill) = NaN;
gfpw_meanshearmag0to6_MPstats_ALLYRS(kill) = NaN;
gfpw_maxshearmag0to6_MPstats_ALLYRS(kill) = NaN;
gfpw_meanshearmag2to9_MPstats_ALLYRS(kill) = NaN;
gfpw_maxshearmag2to9_MPstats_ALLYRS(kill) = NaN;
gfpw_meanOMEGA600_MPstats_ALLYRS(kill) = NaN;
gfpw_minOMEGA600_MPstats_ALLYRS(kill) = NaN;
gfpw_minOMEGAsub600_MPstats_ALLYRS(kill) = NaN;
gfpw_meanVIWVD_MPstats_ALLYRS(kill) = NaN;
gfpw_minVIWVD_MPstats_ALLYRS(kill) = NaN;
gfpw_maxVIWVD_MPstats_ALLYRS(kill) = NaN;
gfpw_meanDIV750_MPstats_ALLYRS(kill) = NaN;
gfpw_minDIV750_MPstats_ALLYRS(kill) = NaN;
gfpw_minDIVsub600_MPstats_ALLYRS(kill) = NaN;
gfpw_meanWNDSPD600_MPstats_ALLYRS(kill) = NaN;
gfpw_meanWNDDIR600_MPstats_ALLYRS(kill) = NaN;
gfpw_MotionSPD_MPstats_ALLYRS(kill) = NaN;
gfpw_MotionDIR_MPstats_ALLYRS(kill) = NaN;

%diagnostics
%   blah_gf = gf_maxMUCAPE_MPstats_ALLYRS(:,:,2);
%   blahlat = meanlat_MPstats_ALLYRS(:,:,2);
%   blahlon = meanlon_MPstats_ALLYRS(:,:,2);

% look through each year' MP_with(out)_MCS and find it's mean/max/min env var
MPwithMCS_meanMUCAPE_ALLYRS = zeros(MP_tracks,maxYR);     MPwithMCS_meanMUCAPE_ALLYRS(:) = NaN;
MPwithMCS_maxMUCAPE_ALLYRS = zeros(MP_tracks,maxYR);      MPwithMCS_maxMUCAPE_ALLYRS(:) = NaN;
MPwithMCS_meanMUCIN_ALLYRS = zeros(MP_tracks,maxYR);      MPwithMCS_meanMUCIN_ALLYRS(:) = NaN;
MPwithMCS_minMUIN_ALLYRS   = zeros(MP_tracks,maxYR);      MPwithMCS_minMUCIN_ALLYRS(:) = NaN;
MPwithMCS_meanMULFC_ALLYRS = zeros(MP_tracks,maxYR);      MPwithMCS_meanMULFC_ALLYRS(:) = NaN;
MPwithMCS_meanMUEL_ALLYRS = zeros(MP_tracks,maxYR);       MPwithMCS_meanMUEL_ALLYRS(:) = NaN;
MPwithMCS_meanPW_ALLYRS   = zeros(MP_tracks,maxYR);       MPwithMCS_meanPW_ALLYRS(:) = NaN;
MPwithMCS_minPW_ALLYRS    = zeros(MP_tracks,maxYR);       MPwithMCS_minPW_ALLYRS(:) = NaN;
MPwithMCS_maxPW_ALLYRS    = zeros(MP_tracks,maxYR);       MPwithMCS_maxPW_ALLYRS(:) = NaN;
MPwithMCS_meanshearmag0to2_ALLYRS    = zeros(MP_tracks,maxYR);    MPwithMCS_meanshearmag0to2_ALLYRS(:) = NaN;
MPwithMCS_maxshearmag0to2_ALLYRS     = zeros(MP_tracks,maxYR);    MPwithMCS_maxshearmag0to2_ALLYRS(:) = NaN;
MPwithMCS_meanshearmag0to6_ALLYRS    = zeros(MP_tracks,maxYR);    MPwithMCS_meanshearmag0to6_ALLYRS(:) = NaN;
MPwithMCS_maxshearmag0to6_ALLYRS     = zeros(MP_tracks,maxYR);    MPwithMCS_maxshearmag0to6_ALLYRS(:) = NaN;
MPwithMCS_meanshearmag2to9_ALLYRS    = zeros(MP_tracks,maxYR);    MPwithMCS_meanshearmag2to9_ALLYRS(:) = NaN; 
MPwithMCS_maxshearmag2to9_ALLYRS     = zeros(MP_tracks,maxYR);    MPwithMCS_maxshearmag2to9_ALLYRS(:) = NaN;
MPwithMCS_meanOMEGA600_ALLYRS        = zeros(MP_tracks,maxYR);    MPwithMCS_meanOMEGA600_ALLYRS(:) = NaN;
MPwithMCS_minOMEGA600_ALLYRS         = zeros(MP_tracks,maxYR);    MPwithMCS_minOMEGA600_ALLYRS(:) = NaN;
MPwithMCS_minOMEGAsub600_ALLYRS      = zeros(MP_tracks,maxYR);    MPwithMCS_minOMEGAsub600_ALLYRS(:) = NaN;
MPwithMCS_meanVIWVD_ALLYRS           = zeros(MP_tracks,maxYR);    MPwithMCS_meanVIWVD_ALLYRS(:) = NaN;
MPwithMCS_minVIWVD_ALLYRS            = zeros(MP_tracks,maxYR);    MPwithMCS_minVIWVD_ALLYRS(:) = NaN;
MPwithMCS_maxVIWVD_ALLYRS            = zeros(MP_tracks,maxYR);    MPwithMCS_maxVIWVD_ALLYRS(:) = NaN;
MPwithMCS_meanDIV750_ALLYRS          = zeros(MP_tracks,maxYR);    MPwithMCS_meanDIV750_ALLYRS(:) = NaN;
MPwithMCS_minDIV750_ALLYRS           = zeros(MP_tracks,maxYR);    MPwithMCS_minDIV750_ALLYRS(:) = NaN; 
MPwithMCS_minDIVsub600_ALLYRS        = zeros(MP_tracks,maxYR);    MPwithMCS_minDIVsub600_ALLYRS(:) = NaN;
MPwithMCS_meanWNDSPD600_ALLYRS        = zeros(MP_tracks,maxYR);    MPwithMCS_meanWNDSPD600_ALLYRS(:) = NaN;
MPwithMCS_meanWNDDIR600_ALLYRS        = zeros(MP_tracks,maxYR);    MPwithMCS_meanWNDDIR600_ALLYRS(:) = NaN;
MPwithMCS_MotionSPD_ALLYRS           = zeros(MP_tracks,maxYR);    MPwithMCS_MotionSPD_ALLYRS(:) = NaN;
MPwithMCS_MotionDIR_ALLYRS           = zeros(MP_tracks,maxYR);    MPwithMCS_MotionDIR_ALLYRS(:) = NaN;

% look through each year' MP_with_MCS and find it's mean/max/min/etc env
% var, but only before it contacts the MCS
MPwithMCS_preMCS_maxMUCAPE_ALLYRS           = zeros(MP_tracks,maxYR);    MPwithMCS_preMCS_maxMUCAPE_ALLYRS(:) = NaN;
MPwithMCS_preMCS_meanMUCIN_ALLYRS           = zeros(MP_tracks,maxYR);    MPwithMCS_preMCS_meanMUCIN_ALLYRS(:) = NaN;
MPwithMCS_preMCS_meanMULFC_ALLYRS           = zeros(MP_tracks,maxYR);    MPwithMCS_preMCS_meanMULFC_ALLYRS(:) = NaN;
MPwithMCS_preMCS_meanMUEL_ALLYRS            = zeros(MP_tracks,maxYR);    MPwithMCS_preMCS_meanMUEL_ALLYRS(:) = NaN;
MPwithMCS_preMCS_meanPW_ALLYRS              = zeros(MP_tracks,maxYR);    MPwithMCS_preMCS_meanPW_ALLYRS(:) = NaN;
MPwithMCS_preMCS_meanshearmag0to2_ALLYRS    = zeros(MP_tracks,maxYR);    MPwithMCS_preMCS_meanshearmag0to2_ALLYRS(:) = NaN;
MPwithMCS_preMCS_meanshearmag0to6_ALLYRS    = zeros(MP_tracks,maxYR);    MPwithMCS_preMCS_meanshearmag0to6_ALLYRS(:) = NaN;
MPwithMCS_preMCS_meanshearmag2to9_ALLYRS    = zeros(MP_tracks,maxYR);    MPwithMCS_preMCS_meanshearmag2to9_ALLYRS(:) = NaN; 
MPwithMCS_preMCS_minOMEGAsub600_ALLYRS      = zeros(MP_tracks,maxYR);    MPwithMCS_preMCS_minOMEGAsub600_ALLYRS(:) = NaN;
MPwithMCS_preMCS_minDIVsub600_ALLYRS        = zeros(MP_tracks,maxYR);    MPwithMCS_preMCS_minDIVsub600_ALLYRS(:) = NaN;



MPwithoutMCS_meanMUCAPE_ALLYRS = zeros(MP_tracks,maxYR);     MPwithoutMCS_meanMUCAPE_ALLYRS(:) = NaN;
MPwithoutMCS_maxMUCAPE_ALLYRS = zeros(MP_tracks,maxYR);      MPwithoutMCS_maxMUCAPE_ALLYRS(:) = NaN;
MPwithoutMCS_meanMUCIN_ALLYRS = zeros(MP_tracks,maxYR);      MPwithoutMCS_meanMUCIN_ALLYRS(:) = NaN;
MPwithoutMCS_minMUIN_ALLYRS   = zeros(MP_tracks,maxYR);      MPwithoutMCS_minMUCIN_ALLYRS(:) = NaN;
MPwithoutMCS_meanMULFC_ALLYRS = zeros(MP_tracks,maxYR);      MPwithoutMCS_meanMULFC_ALLYRS(:) = NaN;
MPwithoutMCS_meanMUEL_ALLYRS = zeros(MP_tracks,maxYR);       MPwithoutMCS_meanMUEL_ALLYRS(:) = NaN;
MPwithoutMCS_meanPW_ALLYRS   = zeros(MP_tracks,maxYR);       MPwithoutMCS_meanPW_ALLYRS(:) = NaN;
MPwithoutMCS_minPW_ALLYRS    = zeros(MP_tracks,maxYR);       MPwithoutMCS_minPW_ALLYRS(:) = NaN;
MPwithoutMCS_maxPW_ALLYRS    = zeros(MP_tracks,maxYR);       MPwithoutMCS_maxPW_ALLYRS(:) = NaN;
MPwithoutMCS_meanshearmag0to2_ALLYRS    = zeros(MP_tracks,maxYR);    MPwithoutMCS_meanshearmag0to2_ALLYRS(:) = NaN;
MPwithoutMCS_maxshearmag0to2_ALLYRS     = zeros(MP_tracks,maxYR);    MPwithoutMCS_maxshearmag0to2_ALLYRS(:) = NaN;
MPwithoutMCS_meanshearmag0to6_ALLYRS    = zeros(MP_tracks,maxYR);    MPwithoutMCS_meanshearmag0to6_ALLYRS(:) = NaN;
MPwithoutMCS_maxshearmag0to6_ALLYRS     = zeros(MP_tracks,maxYR);    MPwithoutMCS_maxshearmag0to6_ALLYRS(:) = NaN;
MPwithoutMCS_meanshearmag2to9_ALLYRS    = zeros(MP_tracks,maxYR);    MPwithoutMCS_meanshearmag2to9_ALLYRS(:) = NaN; 
MPwithoutMCS_maxshearmag2to9_ALLYRS     = zeros(MP_tracks,maxYR);    MPwithoutMCS_maxshearmag2to9_ALLYRS(:) = NaN;
MPwithoutMCS_meanOMEGA600_ALLYRS        = zeros(MP_tracks,maxYR);    MPwithoutMCS_meanOMEGA600_ALLYRS(:) = NaN;
MPwithoutMCS_minOMEGA600_ALLYRS         = zeros(MP_tracks,maxYR);    MPwithoutMCS_minOMEGA600_ALLYRS(:) = NaN;
MPwithoutMCS_minOMEGAsub600_ALLYRS      = zeros(MP_tracks,maxYR);    MPwithoutMCS_minOMEGAsub600_ALLYRS(:) = NaN;
MPwithoutMCS_meanVIWVD_ALLYRS           = zeros(MP_tracks,maxYR);    MPwithoutMCS_meanVIWVD_ALLYRS(:) = NaN;
MPwithoutMCS_minVIWVD_ALLYRS            = zeros(MP_tracks,maxYR);    MPwithoutMCS_minVIWVD_ALLYRS(:) = NaN;
MPwithoutMCS_maxVIWVD_ALLYRS            = zeros(MP_tracks,maxYR);    MPwithoutMCS_maxVIWVD_ALLYRS(:) = NaN;
MPwithoutMCS_meanDIV750_ALLYRS          = zeros(MP_tracks,maxYR);    MPwithoutMCS_meanDIV750_ALLYRS(:) = NaN;
MPwithoutMCS_minDIV750_ALLYRS           = zeros(MP_tracks,maxYR);    MPwithoutMCS_minDIV750_ALLYRS(:) = NaN; 
MPwithoutMCS_minDIVsub600_ALLYRS        = zeros(MP_tracks,maxYR);    MPwithoutMCS_minDIVsub600_ALLYRS(:) = NaN;

MPwithoutMCS_meanWNDSPD600_ALLYRS       = zeros(MP_tracks,maxYR);    MPwithoutMCS_meanWNDSPD600_ALLYRS(:) = NaN; 
MPwithoutMCS_meanWNDDIR600_ALLYRS       = zeros(MP_tracks,maxYR);    MPwithoutMCS_meanWNDDIR600_ALLYRS(:) = NaN;
MPwithoutMCS_MotionSPD_ALLYRS           = zeros(MP_tracks,maxYR);    MPwithoutMCS_MotionSPD_ALLYRS(:) = NaN;
MPwithoutMCS_MotionDIR_ALLYRS           = zeros(MP_tracks,maxYR);    MPwithoutMCS_MotionDIR_ALLYRS(:) = NaN;




for yr = 1 : maxYR

    %env vars boiled down to one value for each MP that overlaps with at
    %MCS at any point during MCS lifecycle
    %   yr = 8

    MPwithMCS = MP_with_MCSs_ALLYRS(:,yr)  ;      MPwithMCS(isnan(MPwithMCS)) = [] ;

    btM = basetime_MCSstats_ALLYRS(:,:,yr)   ;

    for m = 1:length(MPwithMCS) %loop over mps
        %    m = 1 ; 

        mcswithmp =  find(  MPwithMCS(m) == MPtracks_perMCS_ALLYRS(:,:,yr)  )   ;  %the MCS IDs that touch the current MP     
        mcsts = btM( mcswithmp )   ;
        %  blah = MPtracks_perMCS_ALLYRS(:,:,yr) ;

        if(   isempty(mcswithmp) == 0   &   isnan(mcsts)==0   )

            %find first/last basetimes that this MP touches any MCS @ any time in MCS life
            %mcsts = btM( mcswithmp )   ;
            t1  =  min(mcsts,[],'omitnan')  ;  %this is a basetime
            t2    = max(mcsts,[],'omitnan')  ;   %this is a basetime
            %time incidces in MPstats for first/last times overlapping with MCS:
            mp_tstart   =   find( floor(t1/100) == floor(basetime_MPstats_ALLYRS(:,MPwithMCS(m),yr)/100) ) ;   
            mp_tend     =   find( floor(t2/100) == floor(basetime_MPstats_ALLYRS(:,MPwithMCS(m),yr)/100) ) ; 
            %  % alternatively, if you want to just look at the MP lifetime stats intead (not caring about when they overlap with MCSs), just set  
            %  mp_tstart  =  1 ;   
            %  mp_tend    =  200; 

            % % diagnostics
            %   blaht1 = t1;
            %   blaht2 = t2;
            %   blaht3 = basetime_MPstats_ALLYRS(:,MPwithMCS(m),yr);
            %   blaht1 = datetime(t1, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss')
            %   blaht2 = datetime(t2, 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss')
            %   blaht3 = datetime(basetime_MPstats_ALLYRS(:,MPwithMCS(m),yr), 'convertfrom','posixtime','Format','dd-MM-y-HH-mm-ss')

            for m = 1:length( MPwithMCS )
                mp = MPwithMCS(m);
                MPwithMCS_meanMUCAPE_ALLYRS(mp,yr)  =  max( gfpw_meanMUCAPE_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),[],'omitnan' );
                MPwithMCS_maxMUCAPE_ALLYRS(mp,yr)   =  max( gfpw_maxMUCAPE_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),[],'omitnan' );
                MPwithMCS_meanMUCIN_ALLYRS(mp,yr)   =  min( gfpw_meanMUCIN_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),[],'omitnan' );
                MPwithMCS_minMUCIN_ALLYRS(mp,yr)    =  min( gfpw_minMUCIN_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),[],'omitnan' );
                MPwithMCS_meanMULFC_ALLYRS(mp,yr)   =  min( gfpw_meanMULFC_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),[],'omitnan' );
                MPwithMCS_meanMUEL_ALLYRS(mp,yr)    =  max( gfpw_meanMUEL_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),[],'omitnan' );
                MPwithMCS_meanPW_ALLYRS(mp,yr)      =  max( gfpw_meanPW_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),[],'omitnan' );
                MPwithMCS_minPW_ALLYRS(mp,yr)       =  min( gfpw_minPW_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),[],'omitnan' );
                MPwithMCS_maxPW_ALLYRS(mp,yr)       =  max( gfpw_maxPW_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),[],'omitnan' );

                MPwithMCS_meanshearmag0to2_ALLYRS(mp,yr)  =  max(gfpw_meanshearmag0to2_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr), [],'omitnan' );
                MPwithMCS_maxshearmag0to2_ALLYRS(mp,yr)   =  max(gfpw_maxshearmag0to2_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),  [],'omitnan' );
                MPwithMCS_meanshearmag0to6_ALLYRS(mp,yr)  =  max(gfpw_meanshearmag0to6_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr), [],'omitnan' );
                MPwithMCS_maxshearmag0to6_ALLYRS(mp,yr)   =  max(gfpw_maxshearmag0to6_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),  [],'omitnan' );
                MPwithMCS_meanshearmag2to9_ALLYRS(mp,yr)  =  max(gfpw_meanshearmag2to9_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr), [],'omitnan' );
                MPwithMCS_maxshearmag2to9_ALLYRS(mp,yr)   =  max(gfpw_maxshearmag2to9_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),  [],'omitnan' );
                MPwithMCS_meanOMEGA600_ALLYRS(mp,yr)      =  min(gfpw_meanOMEGA600_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),     [],'omitnan' );
                MPwithMCS_minOMEGA600_ALLYRS(mp,yr)       =  min(gfpw_minOMEGA600_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),      [],'omitnan' );
                MPwithMCS_minOMEGAsub600_ALLYRS(mp,yr)    =  min(gfpw_minOMEGAsub600_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),   [],'omitnan' );
                MPwithMCS_meanDIV750_ALLYRS(mp,yr)        =  min(gfpw_meanDIV750_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),    [],'omitnan' );
                MPwithMCS_minDIV750_ALLYRS(mp,yr)         =  min(gfpw_minDIV750_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),     [],'omitnan' );
                MPwithMCS_minDIVsub600_ALLYRS(mp,yr)      =  min(gfpw_minDIVsub600_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr),  [],'omitnan' );
                
                MPwithMCS_meanWNDSPD600_ALLYRS(mp,yr)      =  mean(gfpw_meanWNDSPD600_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr), 'omitnan' );
                MPwithMCS_meanWNDDIR600_ALLYRS(mp,yr)      =  mean(gfpw_meanWNDDIR600_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr), 'omitnan' );

                MPwithMCS_MotionSPD_ALLYRS(mp,yr)         =  mean(gfpw_MotionSPD_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr), 'omitnan' );          
                MPwithMCS_MotionDIR_ALLYRS(mp,yr)         =  mean(gfpw_MotionDIR_MPstats_ALLYRS(mp_tstart:mp_tend,mp,yr), 'omitnan' );        

%                 MPwithMCS_meanVIWVD_ALLYRS(mp,yr)         =  
%                 MPwithMCS_minVIWVD_ALLYRS(mp,yr)          =
%                 MPwithMCS_maxVIWVD_ALLYRS(mp,yr)          =
                
                if(  (mp_tstart-3) > 4   )
                    MPwithMCS_preMCS_maxMUCAPE_ALLYRS(mp,yr)           =  max( gfpw_maxMUCAPE_MPstats_ALLYRS(1:mp_tstart-3,mp,yr),[],'omitnan' );
                    MPwithMCS_preMCS_meanMUCIN_ALLYRS(mp,yr)           =  min( gfpw_meanMUCIN_MPstats_ALLYRS(1:mp_tstart-3,mp,yr),[],'omitnan' );
                    MPwithMCS_preMCS_meanMULFC_ALLYRS(mp,yr)           =  min( gfpw_meanMULFC_MPstats_ALLYRS(1:mp_tstart-3,mp,yr),[],'omitnan' );
                    MPwithMCS_preMCS_meanMUEL_ALLYRS(mp,yr)            =  max( gfpw_meanMUEL_MPstats_ALLYRS(1:mp_tstart-3,mp,yr),[],'omitnan' );
                    MPwithMCS_preMCS_meanPW_ALLYRS(mp,yr)              =  max( gfpw_meanPW_MPstats_ALLYRS(1:mp_tstart-3,mp,yr),[],'omitnan' );
                    MPwithMCS_preMCS_meanshearmag0to2_ALLYRS(mp,yr)    =  max(gfpw_meanshearmag0to2_MPstats_ALLYRS(1:mp_tstart-3,mp,yr), [],'omitnan' );
                    MPwithMCS_preMCS_meanshearmag0to6_ALLYRS(mp,yr)    =  max(gfpw_meanshearmag0to6_MPstats_ALLYRS(1:mp_tstart-3,mp,yr), [],'omitnan' );
                    MPwithMCS_preMCS_meanshearmag2to9_ALLYRS(mp,yr)    =  max(gfpw_meanshearmag2to9_MPstats_ALLYRS(1:mp_tstart-3,mp,yr), [],'omitnan' );
                    MPwithMCS_preMCS_minOMEGAsub600_ALLYRS(mp,yr)      =  min(gfpw_minOMEGAsub600_MPstats_ALLYRS(1:mp_tstart-3,mp,yr),   [],'omitnan' );
                    MPwithMCS_preMCS_minDIVsub600_ALLYRS(mp,yr)        =  min(gfpw_minDIVsub600_MPstats_ALLYRS(1:mp_tstart-3,mp,yr),  [],'omitnan' );
                end

            end
        end %isempty(mcswithmp)
    end  % m loop

    %env vars boiled down to one value for each MP that doesnt overlap with MCS
    MPwithoutMCS = MP_without_MCSs_ALLYRS(:,yr); MPwithoutMCS(isnan(MPwithoutMCS)) = [] ;
    for m = 1:length( MPwithoutMCS ) 
        mp = MPwithoutMCS(m);
        MPwithoutMCS_meanMUCAPE_ALLYRS(mp,yr)  =  max( gfpw_meanMUCAPE_MPstats_ALLYRS(:,mp,yr),[],'omitnan' );
        MPwithoutMCS_maxMUCAPE_ALLYRS(mp,yr)   =  max( gfpw_maxMUCAPE_MPstats_ALLYRS(:,mp,yr),[],'omitnan' );
        MPwithoutMCS_meanMUCIN_ALLYRS(mp,yr)   =  min( gfpw_meanMUCIN_MPstats_ALLYRS(:,mp,yr),[],'omitnan' );
        MPwithoutMCS_minMUCIN_ALLYRS(mp,yr)    =  min( gfpw_minMUCIN_MPstats_ALLYRS(:,mp,yr),[],'omitnan' );
        MPwithoutMCS_meanMULFC_ALLYRS(mp,yr)   =  min( gfpw_meanMULFC_MPstats_ALLYRS(:,mp,yr),[],'omitnan' );
        MPwithoutMCS_meanMUEL_ALLYRS(mp,yr)    =  max( gfpw_meanMUEL_MPstats_ALLYRS(:,mp,yr),[],'omitnan' );
        MPwithoutMCS_meanPW_ALLYRS(mp,yr)      =  max( gfpw_meanPW_MPstats_ALLYRS(:,mp,yr),[],'omitnan' );
        MPwithoutMCS_minPW_ALLYRS(mp,yr)       =  min( gfpw_minPW_MPstats_ALLYRS(:,mp,yr),[],'omitnan' );
        MPwithoutMCS_maxPW_ALLYRS(mp,yr)       =  max( gfpw_maxPW_MPstats_ALLYRS(:,mp,yr),[],'omitnan' ); 

        MPwithoutMCS_meanshearmag0to2_ALLYRS(mp,yr)  =  max(gfpw_meanshearmag0to2_MPstats_ALLYRS(:,mp,yr), [],'omitnan' );
        MPwithoutMCS_maxshearmag0to2_ALLYRS(mp,yr)   =  max(gfpw_maxshearmag0to2_MPstats_ALLYRS(:,mp,yr),  [],'omitnan' );
        MPwithoutMCS_meanshearmag0to6_ALLYRS(mp,yr)  =  max(gfpw_meanshearmag0to6_MPstats_ALLYRS(:,mp,yr), [],'omitnan' );
        MPwithoutMCS_maxshearmag0to6_ALLYRS(mp,yr)   =  max(gfpw_maxshearmag0to6_MPstats_ALLYRS(:,mp,yr),  [],'omitnan' );
        MPwithoutMCS_meanshearmag2to9_ALLYRS(mp,yr)  =  max(gfpw_meanshearmag2to9_MPstats_ALLYRS(:,mp,yr), [],'omitnan' );
        MPwithoutMCS_maxshearmag2to9_ALLYRS(mp,yr)   =  max(gfpw_maxshearmag2to9_MPstats_ALLYRS(:,mp,yr),  [],'omitnan' );
        MPwithoutMCS_meanOMEGA600_ALLYRS(mp,yr)      =  min(gfpw_meanOMEGA600_MPstats_ALLYRS(:,mp,yr),     [],'omitnan' );
        MPwithoutMCS_minOMEGA600_ALLYRS(mp,yr)       =  min(gfpw_minOMEGA600_MPstats_ALLYRS(:,mp,yr),      [],'omitnan' );
        MPwithoutMCS_minOMEGAsub600_ALLYRS(mp,yr)    =  min(gfpw_minOMEGAsub600_MPstats_ALLYRS(:,mp,yr),   [],'omitnan' );
        MPwithoutMCS_meanDIV750_ALLYRS(mp,yr)        =  min(gfpw_meanDIV750_MPstats_ALLYRS(:,mp,yr),    [],'omitnan' );
        MPwithoutMCS_minDIV750_ALLYRS(mp,yr)         =  min(gfpw_minDIV750_MPstats_ALLYRS(:,mp,yr),     [],'omitnan' );
        MPwithoutMCS_minDIVsub600_ALLYRS(mp,yr)      =  min(gfpw_minDIVsub600_MPstats_ALLYRS(:,mp,yr),  [],'omitnan' );

        MPwithoutMCS_meanWNDSPD600_ALLYRS(mp,yr)     =  mean(gfpw_meanWNDSPD600_MPstats_ALLYRS(:,mp,yr), 'omitnan' );
        MPwithoutMCS_meanWNDDIR600_ALLYRS(mp,yr)     =  mean(gfpw_meanWNDDIR600_MPstats_ALLYRS(:,mp,yr), 'omitnan' );

        MPwithoutMCS_MotionSPD_ALLYRS(mp,yr)         =  mean(gfpw_MotionSPD_MPstats_ALLYRS(:,mp,yr), 'omitnan' );          
        MPwithoutMCS_MotionDIR_ALLYRS(mp,yr)         =  mean(gfpw_MotionDIR_MPstats_ALLYRS(:,mp,yr), 'omitnan' ); 

    end
end



%%






%histogram of MPvars during MCSs vs those without MCSs:

ff = figure('position',[84,497,1032,451]);
edges=[0:250:8000];
hold on

[h1,b] = hist(MPwithMCS_maxMUCAPE_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_maxMUCAPE_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_maxMUCAPE_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_maxMUCAPE_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_maxMUCAPE_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_maxMUCAPE_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' max MUCAPE in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [0:250:8000] )
xlabel('MP max MUCAPE','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([0 8000 0 0.1])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_maxMUCAPE_ALLYRS(:),MPwithoutMCS_maxMUCAPE_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_maxMUCAPE_ALLYRS(:),MPwithoutMCS_maxMUCAPE_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_mucapemax_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);







%histogram of MPvars during MCSs vs those without MCSs:

ff = figure('position',[84,497,1032,451]);
edges=[-500:10:0];
hold on

[h1,b] = hist(MPwithMCS_meanMUCIN_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_meanMUCIN_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_meanMUCIN_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_meanMUCIN_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_meanMUCIN_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_meanMUCIN_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' meanMUCIN in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [-500:10:0] )
xlabel('MP meanMUCIN','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([-300 0 0 0.13])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_meanMUCIN_ALLYRS(:),MPwithoutMCS_meanMUCIN_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_meanMUCIN_ALLYRS(:),MPwithoutMCS_meanMUCIN_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_meanMUCIN_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);






%histogram of MPvars during MCSs vs those without MCSs:

ff = figure('position',[84,497,1032,451]);
edges=[0:250:7000];
hold on

[h1,b] = hist(MPwithMCS_meanMULFC_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_meanMULFC_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_meanMULFC_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_meanMULFC_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_meanMULFC_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_meanMULFC_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' meanMULFC in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [0:250:7000] )
xlabel('MP meanMULFC','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([500 6000 0 0.17])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_meanMULFC_ALLYRS(:),MPwithoutMCS_meanMULFC_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_meanMULFC_ALLYRS(:),MPwithoutMCS_meanMULFC_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_meanMULFC_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);






%histogram of MPvars during MCSs vs those without MCSs:

ff = figure('position',[84,497,1032,451]);
edges=[2000:250:22000];
hold on

[h1,b] = hist(MPwithMCS_meanMUEL_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_meanMUEL_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_meanMUEL_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_meanMUEL_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_meanMUEL_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_meanMUEL_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' meanMUEL in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [0:250:15500] )
xlabel('MP meanMUEL','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([2500 15500 0 0.1])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_meanMUEL_ALLYRS(:),MPwithoutMCS_meanMUEL_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_meanMUEL_ALLYRS(:),MPwithoutMCS_meanMUEL_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_meanMUEL_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);













%histogram of MPvars during MCSs vs those without MCSs:

ff = figure('position',[84,497,1032,451]);
edges=[0:2:80];
hold on

[h1,b] = hist(MPwithMCS_meanPW_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_meanPW_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_meanPW_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_meanPW_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_meanPW_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_meanPW_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' meanPW in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [24:2:66] )
xlabel('MP meanPW','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([24 66 0 0.15])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_meanPW_ALLYRS(:),MPwithoutMCS_meanPW_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_meanPW_ALLYRS(:),MPwithoutMCS_meanPW_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_meanPW_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









%histogram of MPvars during MCSs vs those without MCSs:

ff = figure('position',[84,497,1032,451]);
edges=[0:1:36];
hold on

[h1,b] = hist(MPwithMCS_meanshearmag0to2_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_meanshearmag0to2_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_meanshearmag0to2_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_meanshearmag0to2_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_meanshearmag0to2_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_meanshearmag0to2_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' meanshearmag0to2 in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [0:1:36] )
xlabel('MP max meanshearmag0to2','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([0 26 0 0.15])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_meanshearmag0to2_ALLYRS(:),MPwithoutMCS_meanshearmag0to2_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_meanshearmag0to2_ALLYRS(:),MPwithoutMCS_meanshearmag0to2_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_meanshearmag0to2_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);







%histogram of MPvars during MCSs vs those without MCSs:

ff = figure('position',[84,497,1032,451]);
edges=[0:1:60];
hold on

[h1,b] = hist(MPwithMCS_meanshearmag0to6_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_meanshearmag0to6_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_meanshearmag0to6_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_meanshearmag0to6_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_meanshearmag0to6_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_meanshearmag0to6_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' meanshearmag0to6 in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [0:1:60] )
xlabel('MP max meanshearmag0to6','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([0 45 0 0.1])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_meanshearmag0to6_ALLYRS(:),MPwithoutMCS_meanshearmag0to6_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_meanshearmag0to6_ALLYRS(:),MPwithoutMCS_meanshearmag0to6_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_meanshearmag0to6_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









%histogram of MPvars during MCSs vs those without MCSs:

ff = figure('position',[84,497,1032,451]);
edges=[0:1:60];
hold on

[h1,b] = hist(MPwithMCS_meanshearmag2to9_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_meanshearmag2to9_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_meanshearmag2to9_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_meanshearmag2to9_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_meanshearmag2to9_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_meanshearmag2to9_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' meanshearmag2to9 in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [0:1:60] )
xlabel('MP max meanshearmag2to9','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([2 49 0 0.1])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_meanshearmag0to6_ALLYRS(:),MPwithoutMCS_meanshearmag2to9_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_meanshearmag0to6_ALLYRS(:),MPwithoutMCS_meanshearmag2to9_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_meanshearmag2to9_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









%histogram of MPvars during MCSs vs those without MCSs:

ff = figure('position',[84,497,1032,451]);
edges=[-16:0.5:1];
hold on

[h1,b] = hist(MPwithMCS_minOMEGA600_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_minOMEGA600_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_minOMEGA600_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_minOMEGA600_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_minOMEGA600_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_minOMEGA600_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' minOMEGA600 in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [-13:0.5:3] )
xlabel('MP min minOMEGA600 ','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([-11.5 0 0 0.25])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_minOMEGA600_ALLYRS(:),MPwithoutMCS_minOMEGA600_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_minOMEGA600_ALLYRS(:),MPwithoutMCS_minOMEGA600_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_minOMEGA600_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);








%histogram of MPvars during MCSs vs those without MCSs:

ff = figure('position',[84,497,1032,451]);
edges=[-16:0.5:1];
hold on

[h1,b] = hist(MPwithMCS_minOMEGAsub600_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_minOMEGAsub600_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_minOMEGAsub600_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_minOMEGAsub600_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_minOMEGAsub600_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_minOMEGAsub600_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' minOMEGAsub600 in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [-13:0.5:3] )
xlabel('MP min minOMEGAsub600 ','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([-11.5 0 0 0.25])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_minOMEGAsub600_ALLYRS(:),MPwithoutMCS_minOMEGAsub600_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_minOMEGAsub600_ALLYRS(:),MPwithoutMCS_minOMEGAsub600_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_minOMEGAsub600_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);









%histogram of MPvars during MCSs vs those without MCSs:

ff = figure('position',[84,497,1032,451]);
edges=[-16:0.25:1] * 0.0001;
hold on

[h1,b] = hist(MPwithMCS_minDIVsub600_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_minDIVsub600_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_minDIVsub600_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_minDIVsub600_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_minDIVsub600_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_minDIVsub600_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' minDIVsub600 in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [-10:0.25:3] * 0.0001 )
xlabel('MP min minDIVsub600 ','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([-7*0.0001 0 0 0.15])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_minDIVsub600_ALLYRS(:),MPwithoutMCS_minDIVsub600_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_minDIVsub600_ALLYRS(:),MPwithoutMCS_minDIVsub600_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_minDIVsub600_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);






%  mpmeanWNDDIR600_atMCSI_PWfilt:     [0 0.5 0.5]  [1 0.5 0]   [0 0.5 1]

%histogram of MPvars during MCSs vs those without MCSs:

ff = figure('position',[84,497,1032,451]);
edges = [0:5:360] ;
hold on

[h1,b] = hist(MPwithMCS_meanWNDDIR600_ALLYRS(:),edges) ;  blahwithout =  h1 ;%/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_meanWNDDIR600_ALLYRS(:),edges) ;  blahwith =  h1 ;%/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
%note, this came from running the full v6d_violin_XXX.m code, not from this
%script, so run that first (down to and thru the code that splits hi,med,lo
%for MP origins for MPs present at MCSI (NW/SW flow)   ~circa line ~14400,
%then this one minus the clear all at the top:
[h1,b] = hist(mpmeanWNDDIR600_atMCSI_PWfilt(:),edges) ;  blahwithout =  h1 ;%/(sum(h1));   %note, this came from running the full v6d_violin.m code, not from this one.
bar(b,blahwithout,1,'FaceColor',[0 0.5 1])
xticks(b); 
alpha 0.7
hold on
plot(median(MPwithMCS_meanWNDDIR600_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
% plot(mean(MPwithMCS_meanWNDDIR600_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_meanWNDDIR600_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
% plot(mean(MPwithoutMCS_meanWNDDIR600_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(median(mpmeanWNDDIR600_atMCSI_PWfilt(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 1])
% plot(mean(mpmeanWNDDIR600_atMCSI_PWfilt(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 1])
%legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
legend('MP with MCS','MP without MCS','MP at MCSI ','FontSize',15)
title(' mean wind dir in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [0:15:360])
xlabel('Mean in-MP wind direction ','FontSize',15)
ylabel('# MP events','FontSize',15)
%axis([0 360 0 0.1])
axis([0 360 0 120])
% 
% alvl = 0.05;
% [sh,p] = kstest2(MPwithMCS_meanWNDDIR600_ALLYRS(:),MPwithoutMCS_meanWNDDIR600_ALLYRS(:),'Alpha',alvl)
% [p2,sh2] = ranksum(MPwithMCS_meanWNDDIR600_ALLYRS(:),MPwithoutMCS_meanWNDDIR600_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_meanWNDDIR600_MPwithwithoutMCSsMCSI.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
eval([EPSprint]);










ff = figure('position',[84,497,1032,451]);
edges = [0:1:30] ;
hold on

[h1,b] = hist(MPwithMCS_meanWNDSPD600_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_meanWNDSPD600_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_meanWNDSPD600_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_meanWNDSPD600_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_meanWNDSPD600_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_meanWNDSPD600_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' mean wind SPD in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [0:2:30])
xlabel('Mean in-MP wind mag ','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([0 30 0 0.2])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_meanWNDSPD600_ALLYRS(:),MPwithoutMCS_meanWNDSPD600_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_meanWNDSPD600_ALLYRS(:),MPwithoutMCS_meanWNDSPD600_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_meanWNDSPD600_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);







ff = figure('position',[84,497,1032,451]);
edges = [0:5:360] ;
hold on

[h1,b] = hist(MPwithMCS_MotionDIR_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_MotionDIR_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_MotionDIR_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_MotionDIR_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_MotionDIR_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_MotionDIR_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' dir of MP motion in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [0:5:360])
xlabel('MP motion dir ','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([0 360 0 0.2])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_MotionDIR_ALLYRS(:),MPwithoutMCS_MotionDIR_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_MotionDIR_ALLYRS(:),MPwithoutMCS_MotionDIR_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_MotionDIR_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);
% 



ff = figure('position',[84,497,1032,451]);
edges = [0:2.5:100] ;
hold on

[h1,b] = hist(MPwithMCS_MotionSPD_ALLYRS(:),edges) ;  blahwithout =  h1/(sum(h1));
bar(b,blahwithout,1,'FaceColor',[0 0.5 0.5])
xticks(b); 
alpha 0.7
hold on
[h1,b] = hist(MPwithoutMCS_MotionSPD_ALLYRS(:),edges) ;  blahwith =  h1/(sum(h1));
bar(b,blahwith,1,'FaceColor',[1 0.5 0])
alpha 0.7
hold on
plot(median(MPwithMCS_MotionSPD_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(mean(MPwithMCS_MotionSPD_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
plot(median(MPwithoutMCS_MotionSPD_ALLYRS(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
plot(mean(MPwithoutMCS_MotionSPD_ALLYRS(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
legend('MP with MCS(s) & PW > 24mm','MP without MCS & PW > 24mm','FontSize',15)
title(' SPD of MP motion in MP object','FontSize',15)
ax = gca;
ax.FontSize = 15
xticks( [0:2.5:100])
xlabel('MP motion SPD ','FontSize',15)
ylabel('# MP events (normalized by sample size)','FontSize',15)
axis([0 100 0 0.2])

alvl = 0.05;
[sh,p] = kstest2(MPwithMCS_MotionDIR_ALLYRS(:),MPwithoutMCS_MotionDIR_ALLYRS(:),'Alpha',alvl)
[p2,sh2] = ranksum(MPwithMCS_MotionDIR_ALLYRS(:),MPwithoutMCS_MotionDIR_ALLYRS(:),'Alpha',alvl)

%saveas(ff,horzcat(imout,'/MCSIhist_totrain.png'));
outlab = horzcat(imout,'/MPhist_MotionSPD_MPwithwithoutMCSs.eps')
EPSprint = horzcat('print -painters -depsc ',outlab);
%eval([EPSprint]);










%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%   resample data according to wind dir in MP
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


% % condense [1:5] PF area stats 1-combined MCS pf area:
% areapf_MCSstats_ALLYRS = dAdt_MCSstats_ALLYRS;    areapf_MCSstats_ALLYRS(:) = NaN;  
% for y = 1 : mcs_years        % which is same as num years of syn objects
%     for n = 1 : mcs_tracks
%         for t = 1:mtimes
%             areapf_MCSstats_ALLYRS(t,n,y) = sum(pfarea_MCSstats_ALLYRS(:,t,n,y), 'omitnan' );
%         end
%     end
% end
% areapf_MCSstats_ALLYRS(areapf_MCSstats_ALLYRS==0) = NaN;
% 
% %make this var the MCS lifeime max:
% maxareapf_MCSstats_ALLYRS = max( areapf_MCSstats_ALLYRS, [], 1);   maxareapf_MCSstats_ALLYRS = permute(maxareapf_MCSstats_ALLYRS, [2 3 1]) ;



% [mpt mpy] =  size(MPwithMCS_meanWNDDIR600_ALLYRS)  ;
% % meanlat_MPstats_ALLYRS
% 
% %%%%% make syn origin locations broken down by hi, med, lo MCS duration:
% 
% % prescribed duration bins of mcs (hours):
% NWwind  = [285:315];
% Wwind   = [255:285];
% SWwind  = [225:255];
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
% blah = MPwithMCS_meanWNDDIR600_ALLYRS(:);
% blah2 = find(blah > NWwind(1)  &  blah  < NWwind(end)) ;
% 
% blah(blah2)
% 
% 
% for y = 1 : mpy        % which is same as num years of syn objects
%     for n = 1 : mpt
%         
%         %if there's a syn obj at mcsi
%         %if( MPatMCSI_perMCS_ALLYRS(1,n,y) > 0  | MPatMCSI_perMCS_ALLYRS(2,n,y) > 0  )
%             
%             % MCSwithMPareapf_list = vertcat(MCSwithMPareapf_list, maxareapf_MCSstats_ALLYRS(n,y) );
%             
%             %find the MP obj number & then it's origin lat/lon and cat it (for different mcs durations):
%             
%             if(  isnan(MPwithMCS_meanWNDDIR600_ALLYRS(n,y))==0  &  MPwithMCS_meanWNDDIR600_ALLYRS(n,y) > NWwind(1)  &  MPwithMCS_meanWNDDIR600_ALLYRS(n,y) < NWwind(end)    )
%                 
%                 %mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
%                 %for s = 1:length(mpnum)
%                 %    mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
%                 %    mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
%                 %end
%                  mplat_hiMCS = vertcat(mplat_hiMCS, meanlat_MPstats_ALLYRS(1,n,y) );
%                  mplon_hiMCS = vertcat(mplon_hiMCS, meanlon_MPstats_ALLYRS(1,n,y) );
%                 
%             elseif(  isnan(MPwithMCS_meanWNDDIR600_ALLYRS(n,y))==0  &  MPwithMCS_meanWNDDIR600_ALLYRS(n,y) > Wwind(1)  &  MPwithMCS_meanWNDDIR600_ALLYRS(n,y) < Wwind(end)      )
%                 
%                 %mpnum = unique(MPatMCSI_perMCS_ALLYRS(:,n,y)) ; mpnum(mpnum<0)=[];
%                 %for s = 1:length(mpnum)
% %                     mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
% %                     mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
%                 %end
%                  mplat_medMCS = vertcat(mplat_medMCS, meanlat_MPstats_ALLYRS(1,n,y) );
%                  mplon_medMCS = vertcat(mplon_medMCS, meanlon_MPstats_ALLYRS(1,n,y) );                
%                 
%             elseif(  isnan(MPwithMCS_meanWNDDIR600_ALLYRS(n,y))==0  &  MPwithMCS_meanWNDDIR600_ALLYRS(n,y) > SWwind(1)  &  MPwithMCS_meanWNDDIR600_ALLYRS(n,y) < SWwind(end)   )
%                 
%                 %mpnum = unique( MPatMCSI_perMCS_ALLYRS(:,n,y) ) ; mpnum(mpnum<0)=[];
%                 %for s = 1:length(mpnum)
% %                     mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,mpnum(s),y) );
% %                     mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,mpnum(s),y) );
%                 %end
%                 mplat_loMCS = vertcat(mplat_loMCS, meanlat_MPstats_ALLYRS(1,n,y) );
%                 mplon_loMCS = vertcat(mplon_loMCS, meanlon_MPstats_ALLYRS(1,n,y) );
%             end
%             
%             %if no mp obj present at MCSI
% 
%         %elseif(MPatMCSI_perMCS_ALLYRS(1,n,y) < 0  & MPatMCSI_perMCS_ALLYRS(2,n,y) < 0  ) %if not a syn obj at mcsi
%             
%         %    MCSwithoutMPareapf_list = vertcat(MCSwithoutMPareapf_list, maxareapf_MCSstats_ALLYRS(n,y) );
%             
%         %end
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
% title([' Origin locations of MPs contacting MCSs with MPwind dir: ',num2str(NWwind(1)),' to ', num2str(NWwind(end)) ,' N = ', num2str(length(mplat_hiMCS)) ])
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
% outlab = horzcat(imout,'/MPorigin_NWmpWIND_filtLS',num2str(filteroutLS),'.eps')
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
% title([' Origin locations of MPs contacting MCSs with MPwind dir: ',num2str(Wwind(1)),' to ', num2str(Wwind(end)) ,' N = ', num2str(length(mplat_medMCS)) ])
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
% outlab = horzcat(imout,'/MPorigin_WmpWIND_filtLS',num2str(filteroutLS),'.eps')
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
% title([' Origin locations of MPs contacting MCSs with MPwind dir: ',num2str(SWwind(1)),' to ', num2str(SWwind(end)) ,' N = ', num2str(length(mplat_loMCS)) ])
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
% outlab = horzcat(imout,'/MPorigin_SWmpWIND_filtLS',num2str(filteroutLS),'.eps')
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
% mean(mplat_loMCS-360)
% mean(mplat_hiMCS-360) 
% median(mplat_loMCS-360)
% median(mplat_hiMCS-360) 
% 
% [sh,p] = kstest2(mplat_hiMCS,mplat_loMCS,'Alpha',alvl) 
% [p2,sh2] = ranksum(mplat_hiMCS,mplat_loMCS,'Alpha',alvl)
















































% 
% 
% 
% %  ERA5 env metrics at MCSI
% 
% %soon to be depricated:
% maxW600_MCSstats_AtMCSI   = maxW600_MCSstats_ALLYRS(1,:,:) ;         maxW600_MCSstats_AtMCSI = permute(maxW600_MCSstats_AtMCSI, [2 3 1]) ;
% %depricated:
% meanPW_MCSstats_AtMCSI    = meanPW_MCSstats_ALLYRS(1,:,:) ;          meanPW_MCSstats_AtMCSI = permute(meanPW_MCSstats_AtMCSI, [2 3 1]) ;
% maxMUCAPE_MCSstats_AtMCSI = maxMUCAPE_MCSstats_ALLYRS(1,:,:) ;       maxMUCAPE_MCSstats_AtMCSI = permute(maxMUCAPE_MCSstats_AtMCSI, [2 3 1]) ;
% maxVIWVC_MCSstats_AtMCSI  = maxVIWVConv_MCSstats_ALLYRS(1,:,:) ;     maxVIWVC_MCSstats_AtMCSI = permute(maxVIWVC_MCSstats_AtMCSI, [2 3 1]) ;
% 
% 
% 
% 
% 
% 
% % divide up into MCSs with(out) syn objecst at MCSI:
% mask_mpatMCSI = zeros(mcs_tracks,mcs_years);  mask_mpatMCSI(:) = NaN;          %1 if synoptic object at MCSI, NaN if not
% mask_nompatMCSI = zeros(mcs_tracks,mcs_years);  mask_nompatMCSI(:) = NaN;      %1 if no synoptic object at MCSI, NaN if there is one
% %MCSI with syn:
% for y = 1:mcs_years
%     for m = 1:mcs_tracks
%         if( MPatMCSI_perMCS_ALLYRS(1,m,y) > 0   |   MPatMCSI_perMCS_ALLYRS(2,m,y) > 0  )
%             mask_mpatMCSI(m,y) = 1;  
%         else
%             mask_nompatMCSI(m,y) = 1;
%         end
%     end
% end
% 
% maxW600_MCSstats_mpatMCSI   = maxW600_MCSstats_AtMCSI .* mask_mpatMCSI;
% maxW600_MCSstats_nompatMCSI = maxW600_MCSstats_AtMCSI .* mask_nompatMCSI;
% 
% meanPW_MCSstats_mpatMCSI   = meanPW_MCSstats_AtMCSI .* mask_mpatMCSI;
% meanPW_MCSstats_nompatMCSI = meanPW_MCSstats_AtMCSI .* mask_nompatMCSI;
% 
% maxMUCAPE_MCSstats_mpatMCSI   = maxMUCAPE_MCSstats_AtMCSI .* mask_mpatMCSI;
% maxMUCAPE_MCSstats_nompatMCSI = maxMUCAPE_MCSstats_AtMCSI .* mask_nompatMCSI;
% 
% maxVIWVC_MCSstats_mpatMCSI    = maxVIWVC_MCSstats_AtMCSI .* mask_mpatMCSI;
% maxVIWVC_MCSstats_nompatMCSI  = maxVIWVC_MCSstats_AtMCSI .* mask_nompatMCSI;
% 
% 
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % histogram of raw MP W for MCSs with & without MP objs at birth:
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% 
% 
% ff = figure('position',[84,497,1032,451]);
% edges=[-10:0.1:5];
% hold on
% % hist(maxW600_MCSstats_nompatMCSI(:),edges);
% % h = findobj(gca,'Type','patch');
% % h.FaceColor = [0 0.5 0.5];
% % h.EdgeColor = [0 0 0];
% % hold on
% % hist(maxW600_MCSstats_mpatMCSI(:),edges);
% % h2 = findobj(gca,'Type','patch');
% % h2(1).FaceColor = [1 0.5 0];
% % h2(1).EdgeColor = [0 0 0];
% % h2(1).FaceAlpha = 0.8;
% [h1,b] = hist(maxW600_MCSstats_nompatMCSI,edges) ;  blah1 =  h1/(sum(h1));
% bar(b,blah1,1,'FaceColor',[0 0.5 0.5],'EdgeColor','k')
% alpha 0.7
% hold on
% %hist(MCSwithMPDuration_list,edges,'Normalization','probability');
% [h1,b] = hist(maxW600_MCSstats_mpatMCSI(:),edges) ;  blah2 =  h1/(sum(h1));
% bar(b,blah2,1,'FaceColor',[1 0.5 0],'EdgeColor','k')
% alpha 0.7
% hold on
% plot(median(maxW600_MCSstats_nompatMCSI(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
% plot(mean(maxW600_MCSstats_nompatMCSI(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[0 0.5 0.5])
% plot(median(maxW600_MCSstats_mpatMCSI(:),'omitnan'),0,'dk','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
% plot(mean(maxW600_MCSstats_mpatMCSI(:),'omitnan'),0,'ok','MarkerSize',10,'MarkerFaceColor',[1 0.5 0])
% legend('MCSI without MP obj','MCSI with MP obj','FontSize',15)
% title(' Max ERA5 updraft (min omega) surrounding MCS','FontSize',15)
% ax = gca;
% ax.FontSize = 15
% alvl = 0.05;
% [sh,p] = kstest2(maxW600_MCSstats_nompatMCSI(:),maxW600_MCSstats_mpatMCSI(:),'Alpha',alvl)
% % text(-4,225,['K-S test at ', num2str(alvl),' significance lvl:'])
% % if(sh == 0)
% %     text(-3.85,210,['Sig diff distributions? NO.  P-val:',num2str(p)])
% % elseif(sh == 1)
% %     text(-3.85,210,['Sig diff distributions? YES.  P-val:',num2str(p)]) 
% % end
% [p2,sh2] = ranksum(maxW600_MCSstats_nompatMCSI(:),maxW600_MCSstats_mpatMCSI(:),'Alpha',alvl)
% % text(-4,150,['Wilcoxon rank sum test at ', num2str(alvl),' sig lvl:'])
% % if(sh2 == 0)
% %     text(-3.85,135,['Sig diff distributions? NO.  P-val:',num2str(p2)])
% % elseif(sh2 == 1)
% %     text(-3.85,135,['Sig diff distributions? YES.  P-val:',num2str(p2)]) 
% % end
% xticks( [-5.0:0.5:5] )
% %xticks( [-5.05:0.4:4.9] )
% xlabel(['vertcal motion [Pa/s]'],'FontSize',15)
% ylabel(['Num of MCSs (normalized by sample size)'],'FontSize',15)
% axis([-5 1 0 0.12 ])
% 
% 
% %saveas(ff,horzcat(imout,'/MCSIwithwithoutsyn_maxW600.png'));
% outlab = horzcat(imout,'/MCSIwithwithoutsyn_maxW600.eps');
% EPSprint = horzcat('print -painters -depsc ',outlab);
% %eval([EPSprint]);
% 
% 
% 
% 










