function HRVparams = InitializeHRVparams(project_name)
%
%   settings = InitializeHRVparams('demo')
%
%   OVERVIEW:   
%       This file stores settings and should be configured before
%       each use of the HRV toolbox:
%       1.  Project Specific Input/Output Data type and Folders
%       2.  How much does the user trust the data
%       3.  Global Settings for signal segmentation
%       4.  Quality Threshold Settings
%       5.  Debug Settings
%       6.  SQI Settings
%       7.  Output Settings 
%       8.  Time of Process and Filename to Save Data
%       9.  Preprocess Settings
%       10. Time Domain Analysis Settings
%       11. Frequency Domain Analysis Settings
%       12. SDANN and SDNNI Analysis Settings
%       13. PRSA Analysis Settings
%       14. AF Detection Settings
%       15. Peak Detection Settings
%
%   INPUT:      
%       project_name = a string with the name of the project - this
%       will determine the naming convention of file folders
%
%   OUTPUT:
%       HRVparams - struct of various settings for the hrv_toolbox analysis
%
%   DEPENDENCIES & LIBRARIES:
%       HRV_toolbox https://github.com/cliffordlab/hrv_toolbox
%       WFDB Matlab toolbox https://github.com/ikarosilva/wfdb-app-toolbox
%       WFDB Toolbox https://physionet.org/physiotools/wfdb.shtml
%   REFERENCE: 
%	REPO:       
%       https://github.com/cliffordlab/hrv_toolbox
%   ORIGINAL SOURCE AND AUTHORS:     
%       This script written by Adriana N. Vest
%       Dependent scripts written by various authors 
%       (see functions for details)       
%	COPYRIGHT (C) 2016 
%   LICENSE:    
%       This software is offered freely and without warranty under 
%       the GNU (v3 or later) public license. See license file for
%       more information
%% 
% Initialize

if nargin < 1
    project_name = 'demo';
end

% Set up input options
switch project_name   
    
    % Define new project name and parameters
    case 'myProjectName1'          % Update with your project name
        HRVparams.readdata = 'MIT_Arrhythmia';           % Specify data input folder\dir
        HRVparams.writedata = 'Output_MIT_Arrhythmia';   % Specify data output folder
        HRVparams.Fs = 333;                % Spacify sampling frequency
        HRVparams.datatype = '';           % Spacify Data type
        HRVparams.ext = 'dat';             % Spacify file extension (e.g., 'mat','qrs')
        HRVparams.input_data_format = 'input_waveform';  % Spacify input_RR_intervals OR input_waveform
        
    % Existing demo projects
    case 'demo'                    % Parameters for demo using qrs data
        HRVparams.readdata = 'TestData';
        HRVparams.writedata = 'OutputData';
        HRVparams.ext = 'qrs';
        HRVparams.datatype = 'MARS';
        HRVparams.input_data_format = 'input_RR_intervals';
        HRVparams.Fs = 125;
        % RRGEN Optionn, these parameters are passed to rrgen.m only for 
        %demo pourposes 
        HRVparams.demo.length = 24*60*60;  % Length of demo RR intervals in seconds
        HRVparams.demo.pe = 0.0003;        % Probability of ectopy ~ 1 per hr 
        HRVparams.demo.pn = 0.0048;        % Probability of noise ~ 16 per hr 
        HRVparams.demo.seed = 1;           % Seed for RRGEN

    case 'rawdatademo'             % Parameters for demo using raw ECG data
        HRVparams.readdata = 'TestData';
        HRVparams.writedata = 'OutputData';
        HRVparams.Fs = 128;
        HRVparams.datatype = 'MARS';
        HRVparams.ext = 'mat';
        HRVparams.input_data_format = 'input_waveform';
    
    case 'mitarr'             % Parameters for demo using raw ECG data
        HRVparams.readdata = 'MIT-Arrhythmia';
        HRVparams.writedata = ['OutputData' filesep 'MIT_Arrhythmia'];
        HRVparams.Fs = 360;
        HRVparams.ext = 'dat';
        HRVparams.input_data_format = 'input_waveform';
             
end

% Check existence of Input\Output data folders and add to search path

if  isempty(HRVparams.readdata) || ~exist([pwd filesep HRVparams.readdata], 'dir')    
    error('Invalid data INPUT folder');    % If folder name is empty
end
addpath(HRVparams.readdata)

if  isempty(HRVparams.writedata)    
    % Default data OUTPUT folder name based on project name
    HRVparams.writedata = strcat(project_name,'_Results');  
    fprintf('Creating new OUTPUT folder: "%s"\n', HRVparams.writedata)
    mkdir(HRVparams.writedata);          % Create output folder and 
elseif ~exist([pwd filesep HRVparams.writedata], 'dir')
    fprintf('Creating new OUTPUT folder: "%s"\n',HRVparams.writedata)
    mkdir(HRVparams.writedata);          % Create output folder and 
end
addpath(genpath(HRVparams.writedata));   % Add folder to search path



%% 2. How much does the user trust the data:
% This setting determines how stringently filtered the data is prior to
% calculating HRV metrics. Raw ECG or Pulse data that has been labeled
% using a peak detector (like jqrs) would require the most stringent
% filtering, whereas RR interval data that has been reviewed by a human
% technician would require the least amount of filtering. 

%   - qrs detection no beats labeled - most stringent filters
%   - automatic beat detection beat typed - moderately stringent filtered
%   - hand corrected - least filtered, maybe no filter

% EXPLAIN THE THRESHOLDS BETTER
% ADD THIS TO A DEMO

HRVparams.data_confidence_level = 1;
% 1 - raw data with automatic beat detection
% 2 - raw data with automatic beat detection, but beat typed (ie N, SV,etc)
% 3 - technician reviewed data

% * ^^^^ NOT YET IN USE ^^^^  *

%% 3. Global Settings

HRVparams.windowlength = 300;	% 300 seconds or 5 minutes
HRVparams.increment = 60;       % 60 seconds or 1 minute window increment
HRVparams.numsegs = 5;          % number of segments to collect with lowest HR

%% 4. Quality Threshold Settings
HRVparams.threshold1 = 0;       % Threshold for which SQI represents good data
HRVparams.threshold2 = .20;     % Amount (%) of data that can be rejected before a
                        % window is considered too low quality for analysis
HRVparams.win_tol = .15;        % maximum percentage of data allowable to be missing
                        %  from a window .15 = 15%
%% 5. Debug Settings

HRVparams.rawsig = 0;           % Load raw signal if it is available for debugging
HRVparams.debug = 0;

%% SQI Settings

HRVparams.sqi.windowlength = 10; % In seconds
HRVparams.sqi.increment = 1;     % In seconds
HRVparams.sqi.threshold = 0.1;   % In seconds
HRVparams.sqi.margin = 2;        % In seconds

%% 6. Output Settings

HRVparams.gen_figs = 0;             % Generate figures
HRVparams.save_figs = 0;            % Save generated figures
if HRVparams.save_figs == 1
    HRVparams.gen_figs = 1;
end

% Format settings for HRV Outputs
HRVparams.output.format = 'csv';        % 'csv' - creates csv file for output
                                % 'mat' - creates .mat file for output
HRVparams.output.separate = 0;          % 1 = separate files for each subject
                                % 0 = all results in one file
HRVparams.output.num_win = [];          % Specify number of lowest hr windows returned
                                % leave blank if all windows should be returned

                                % Format settings for annotations generated
HRVparams.output.ann_format = 'binary'; % 'binary'  = binary annotation file generated
                                % 'csv'     = ASCII CSV file generated
                            

%% 3. Time of Process and Filename to Save Data

HRVparams.time = datestr(now);                  % Setup time for filename of output
HRVparams.time = strrep(HRVparams.time,'-','');
HRVparams.time = strrep(HRVparams.time,' ','');
HRVparams.time = strrep(HRVparams.time,':','');
HRVparams.filename = [project_name '_' HRVparams.time];

%% 7. Preprocess Settings

HRVparams.preprocess.figures = HRVparams.gen_figs;      % Figures on = 1, Figures off = 0
HRVparams.preprocess.gaplimit = 4;              % seconds; maximum believable gap 
                                        % in rr intervals
HRVparams.preprocess.per_limit = 0.2;           % Percent limit of change from one 
                                        % interval to the next
HRVparams.preprocess.forward_gap = 3;	        % Maximum tolerable gap at beginning  
                                        % of timeseries in seconds
HRVparams.preprocess.method_outliers = 'pchip';   % Method of dealing with outliers
                                        % 'cub' = replace outlier points 
                                        %  with cubic spline method
                                        % 'rem' = remove outlier points
                                        % 'pchip' = replace with pchip method
HRVparams.preprocess.lowerphysiolim = 60/160;
HRVparams.preprocess.upperphysiolim = 60/30;
HRVparams.preprocess.method_unphysio = 'pchip';   % Method of dealing with 
                                        % unphysiologically low beats
                                        % 'cub' = replace outlier points 
                                        %  with cubic spline method
                                        % 'rem' = remove outlier points
                                        % 'pchip' = replace with pchip method

% The following settings do not yet have any functional effect on 
% the output of preprocess.m:                             
HRVparams.preprocess.threshold1 = HRVparams.threshold1;	 % Threshold for which SQI represents good data
HRVparams.preprocess.minlength = 30;             % (seconds) The minimum length of a good data segment
                                

%% 8. Time Domain Analysis Settings

HRVparams.timedomain.threshold1 = HRVparams.threshold1;  % Threshold for which SQI represents good data
HRVparams.timedomain.threshold2 = 0.20;          % Amount (%) of data that can be rejected before a
                                         % window is considered too low quality for analysis
HRVparams.timedomain.dataoutput = 0;             % 1 = Print results to .txt file
                                         % Anything else = utputs to return variables only
                                         % returned variables
HRVparams.timedomain.alpha = 0.050;              % In seconds
HRVparams.timedomain.win_tol = HRVparams.win_tol;        % Maximum percentage of data allowable 
                                         % to be missing from a window

%% 9. Frequency Domain Analysis Settings

ULF = [0 .0033];                    % Requires a
VLF = [0.0033 .04];                 % Requires at least 300 s window
LF = [.04 .15];                     % Requires at least 25 s window
HF = [0.15 0.4];                    % Requires at least 7 s window

HRVparams.freq.limits = [ULF; VLF; LF; HF];
HRVparams.freq.threshold1 = HRVparams.threshold1;	% Threshold for which SQI represents good data
                                    % (Used only when SQI is provided)
HRVparams.freq.threshold2 = 0.05;           % Amount (%) of data that can be rejected before a
                                    % window is considered too low quality for analysis
                                    % (Used only when SQI is provided)
HRVparams.freq.zero_mean = 1;               % Option for subtracting the mean from the input data
HRVparams.freq.methods = {'lomb'};
HRVparams.freq.plot_on = 0;
HRVparams.freq.dataoutput = 2;              % 1 = Print results to .txt file & outputs to return variables
                                    % Anything else = outputs to return variables only

% The following settings are for debugging spectral analysis methods
HRVparams.freq.debug_sine = 0;              % Adds sine wave to tachogram for debugging
HRVparams.freq.debug_freq = 0.15;  
HRVparams.freq.debug_weight = .03;

% Lomb:
HRVparams.freq.normalize_lomb = 0;	        % 1 = Normalizes Lomb Periodogram, 
                                    % 0 = Doesn't normalize

% Burg: (not recommended)
HRVparams.freq.burg_poles = 15;    % Number of coefficients for spectral 
                                    % estimation using the Burg method 
                                    % (not recommended)

% The following settings are only used when the user specifies spectral
% estimation methods that use resampling
% s.freq.methods = {'welch_rs','fft_rs'}
HRVparams.freq.resampling_freq = 7; %Hz 
HRVparams.freq.resample_interp_method = 'cub';  % 'cub' = cublic spline method (DEFAULT)
                                        % 'lin' = linear spline method
HRVparams.freq.resampled_burg_poles = 100; 

%% 10. SDANN and SDNNI Analysis Settings

HRVparams.sd.segmentlength = HRVparams.windowlength;

%% 10. PRSA Analysis Settings

HRVparams.prsa.win_length = 30;  % In seconds
HRVparams.prsa.thresh_per = 20;  % Percent difference that one beat can 
                                 % differ from the  next in the prsa code
HRVparams.prsa.plot_results = 0;    
HRVparams.prsa.threshold1= HRVparams.threshold1;  % Threshold for which SQI represents good data
HRVparams.prsa.threshold2 = 0.20; % Amount (%) of data that can be rejected 
                                  % before a window is considered too low 
                                  % quality for analysis                            
HRVparams.prsa.win_tol = HRVparams.win_tol; % Maximum percentage of data allowable to 
                                            % be missing from a window

%% 11. AF Detection Settings

HRVparams.af.on = 0;              % AF Detection On or Off
HRVparams.af.windowlength = 30;   % Set to include ~60 beats in each window
HRVparams.af.increment = 30;      % No overlap necessary in AF feat calc

%% 12. Peak Detection Settings

% The following settings are for qrs_detect2.m

HRVparams.REF_PERIOD = 0.250; 
HRVparams.THRES = .6; 
HRVparams.fid_vec = [];
HRVparams.SIGN_FORCE = [];
HRVparams.debug = 0;



end