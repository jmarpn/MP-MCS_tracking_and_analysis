# MP-MCS_tracking_and_analysis
Scripts accompanying analysis of Marquis et al. 2024 


1) [preprocess] Calcuates 600mb ERA5 vorticity fields used for tracking MPs and LSs. includes code by Sandro Lubio for FFT band-pass filtering. performed in python.

2) [MPtracking] Config files for Python pyflextrkr code (Feng et al. 2023) tracking MPs and LSs ("synoptic") which reads in preprocessed cdf ERA% vorticity files. done in config directory.

3) [postprocess]  matlab codes which reads in, collates, and analyzes into plots LS, MP, and MCS objects. 
