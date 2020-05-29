%======================================================================
%======================================================================
%                       Iconic memory task
%======================================================================
% Displays 8 letters in circular array around fixation, then provides a retro-cue. Subjects
% have to identify the letter at the cued position.
%======================================================================
%Author: Amalia Gomoiu- University of Glasgow
%======================================================================


%======================================================================
% clear and set working directory
%======================================================================
sca
clear all;
close all;
tic
%========================================================
% set to 1 if you want the scrist to ans the Qs
%========================================================
debug_mode = 0;
% ========================================================
% set to 1 if you want to use eye-tracker
% ========================================================
UseEyetracker = 1;
loc = '/data/Experiments/IcomemTask2/';
cd (loc)
%======================================================================
% how to ask for help with Psychtoolbox functions 
%=======================================================================
% Screen('OpenWindow?')
%======================================================================
% ignore synnchronization tests
%=======================================================================
Screen('Preference', 'SkipSyncTests', 0); % useful when you're writing your script because it ignores synchronization tests % set Screen('Preference', 'SkipSyncTests', 0) for maximum accuracy and reliability.

%======================================================================
% website to find RGB numbers
%======================================================================
% https://www.rapidtables.com/web/color/RGB_Color.html 


%======================================================================
% load in the xlsx file (either practice or experiment) 
%=======================================================================
% for the ***EXP***
% protocol=xlsread('PracticeProtocol128.xlsx','A2:H129');% ***only up to col H => we don't separate the target Q here 
% for the ***PRACTICE***
protocol=xlsread('PracticeProtocol64.xlsx','A2:H65'); % **** use this instead of the experiment one because you decided to have only 64 trials(you haved the trials/block)
%======================================================================
% save each col from it into an individual variable 
%======================================================================
colorsetList = protocol(:,2); % doesn't do anything, just a reminance of Roberto's old code
attTrials = protocol(:,3); % att condition in each trial 
cueposList = protocol(:,4);% 1/8 possible positions 
cueoriList = protocol(:,5); % in degrees 
ITIList = protocol(:,6); % ITI varies so that participants don't predict it over time 
CDTrials = protocol(:,8); % CD condition in each trial 
nTrials = size(protocol,1); % no of trials (NB this includes the break "trials")
%targetQ = protocol(:,9); % tells you the trials where you ask them to report the target
att_delay = 0.3; % this is the time that the greycircle+ att circles are on the screen for
%======================================================================
% find where the break trials are and the real no. of trials 
%======================================================================
trials = 1:nTrials;
trials = trials';
brkIndx = isnan(cueoriList);
brkTrials = trials(brkIndx);
realTrials = trials;
realTrials(brkTrials) = [];% trick to get the real no of trials 

%===============================================================================================
% randomise the trial order and select the proper (ie get rid of brk trials) randCD and randAtt
%===============================================================================================
%=======================================================================
% trial randomisation
%=======================================================================
% randomized trials excluding the break trials
trialOrder = datasample(realTrials,length(realTrials),'Replace', false);

% add the break trials to the randomised trials 
fullTrialOrder = zeros(nTrials,1); % make a matrix of 0 ...
fullTrialOrder(brkTrials) = brkTrials; % where you put the break trials ...
indxFull = find(fullTrialOrder==0); % find where in this full matrix you have empty trials
fullTrialOrder(indxFull) = trialOrder; % and replace them with the randomized trials  

% use the randomization matrix to mingle the CD and Att conditions
randCD = CDTrials(fullTrialOrder);
randCD(brkTrials) = 1;% we put 1s just as placeholders for where the breaks are 
randAtt = attTrials(fullTrialOrder);
randAtt(brkTrials) = 5;% we put 5s because later we make an if cond where att=5 to give the participant a break 

%======================================================================
% select the VS trials % uncomment and use if you want to ask the TARGET Q
% only on SOME trials 
%======================================================================
% percentageVS_trials = 50;% % of in how many trials you want to ask about the target
% noVS_trials = round((percentageVS_trials * length(realTrials))/100);
% noVS_trialsPerAttCond = noVS_trials/3;
% % out of the total no of REALtrials sample without replacement the ones you
% % want to ask question about the VS task 
% VS_trials = datasample(realTrials,noVS_trials,'Replace', false); % the trials were you ask about VS  

%=======================================================================
% set stimulus parameters
%=======================================================================
stimuli = {'S','D','F','H','J','K','L','Z','X','C','V','B','N','M'};
stimpars.letterSizeVD = 1.3;
stimpars.letterEccentricityVD = 4;
stimpars.smooth_circleSizeVD = 0.65;% 1st no for height, 2nd for width of ** white ** circles 
stimpars.pegged_circleSizeVD = 0.65;
stimpars.pegg_SizeVD = 0.33;% the size of the peg 
stimpars.smoothCircle_EccentricityVD = 1.75;
stimpars.peggedCircle_EccentricityVD = 1.75;
% stimpars.smooth_circleSizeVD = [0.4 0.6];% 1st no for height, 2nd for width of ** white ** circles 
% stimpars.pegged_circleSizeVD = [0.4 0.8];% 1st no for height, 2nd for width of ** white ** circles 
stimpars.letterDuration = 5;  % 4 frames in previous exp which means 40 msec when 100HZ % 5 frames if we want it for 50ms
stimpars.col = [72,118,255];
stimpars.cueSizeVD = [2 0.09]; % changed from 0.07
stimpars.cueEccentricityVD = 1.75;
stimpars.cueDuration = 1; %in frames

%=======================================================================
% set letter colours
%=======================================================================
% the range of possible colors 
% http://cloford.com/resources/colours/500col.htm
% pink 1, violetred 1, orchid 1, mediumorchid 1, purple 1, slateblue 1,
% blue 1, royalblue 1, steelblue 1, turquoise 1, springgreen 1, green 1, olivedrab
% 1, yellow 1, gold 1, orange 1, sienna 1, orangered 1, red 1

Colors = [255	181	197; ...
    255	62	150; ...
    255	131	250; ...
    224	102	255; ...
    155	48	255; ...
    131	111	255; ...
    0	0	255; ... 
    72	118	255; ...
    99	184	255; ...
    0	245	255; ...
    0	238	118; ...
    0	255	0; ...
    192	255	62; ...
    255	255	0; ...
    255	215	0; ...        
    255	165	0;...
    255	130	71;...
    255	69	0;...
    255	0	0];

AmountOfColors = length(Colors);
TotalNumOfTrials = 1;

%=======================================================================
% preallocate data variables
%=======================================================================
presentedLett = zeros(nTrials,14);  % pre-allocate space for presented lettes in all trials
dataLog = zeros(nTrials, 11);
trialN = zeros(nTrials,1);
targetID = cell(nTrials,1); %  will be storing the cued letter for each trial (by actual letter)
targetIDnum = zeros(nTrials,1);
targetPos = zeros(nTrials,1);
targetColor = zeros(nTrials,1);
cueDelay = zeros(nTrials,1);
respLett = cell(nTrials,1); % preallocation for the participant responses for Letter question 
respCD = cell(nTrials,1); % preallocation for the participant responses for CD question 
respVS = cell(nTrials,1); % preallocation for the participant responses for VS question 
targetACC = zeros(nTrials,1); % will be used to store acc of letter recall
CDACC = cell(nTrials,1); % will be used to store acc of CD recall
stimPresTimes = zeros(nTrials,1);    
ISItime = zeros(nTrials,1);
ITIreal = zeros(nTrials,1); % will store the actual ITI 
thisTrialITI = zeros(nTrials,1);
StartinColorLog = zeros(nTrials,1);
randCDTransf = cell(nTrials,1);
% white circle pos 
rand_circlePos = zeros(nTrials,10); % 10 circle positions to choose from
no_selected_positions = 8; % no of circles you will display
selected_circlePos = zeros(nTrials,no_selected_positions); % 8 circles positions are selected

%=======================================================================
% calculate and set screen parameters
%=======================================================================
screen.viewingdistance_CM = 57; % IMPORTANT!!! distance of the particiopant from the screen
screen.width_CM = 60; %40.5 ; % IMPORTANT!!! screen widht (cm)
screen.height_CM = 34; %30.5;  % IMPORTANT!!! screen height (cm) 
screen.id = max(Screen('Screens')); % Choose screen with maximum id - the secondary display:
screen.res=get(screen.id,'ScreenSize');
screen.widthpix=screen.res(3); 
screen.heightpix=screen.res(4); 
screen.sizepix=[screen.widthpix,screen.heightpix];
screen.sizecm=[screen.width_CM,screen.height_CM];
screen.Xcentre=(screen.widthpix/2);
screen.Ycentre=(screen.heightpix/2);

%=======================================================================
%recompute letter, small circles and cue parameters in pixel
%=======================================================================
pixperdeg = pi * (screen.widthpix / atan(screen.width_CM/screen.viewingdistance_CM/2)) / 360; % pixels per degree        
% for letters 
stimpars.letterSizePX = stimpars.letterSizeVD * pixperdeg;
stimpars.letterEccentricityPX = stimpars.letterEccentricityVD * pixperdeg;
% for cue
stimpars.cueSizePX = stimpars.cueSizeVD * pixperdeg;
stimpars.cueEccentricityPX = stimpars.cueEccentricityVD * pixperdeg;
% for small circles
stimpars.smooth_circleSizePX = stimpars.smooth_circleSizeVD * pixperdeg; % for the smooth small white circles
stimpars.pegged_circleSizePX = stimpars.pegged_circleSizeVD * pixperdeg; % for the pegged white circles
stimpars.pegg_SizePY = stimpars.pegg_SizeVD * pixperdeg; % pixels on the x axis for the tiny pegg
stimpars.smoothCircle_EccentricityPX = stimpars.smoothCircle_EccentricityVD * pixperdeg;
stimpars.peggedCircle_EccentricityPX = stimpars.peggedCircle_EccentricityVD * pixperdeg;
 
%=======================================================================
% compute centres of LETTER texture rectangles to draw at each position
%======================================================================
% higher x-value means pixel will be more to the right
% higher y-value means pixel will be more down the display
Pos1 = [round(screen.Xcentre), round(screen.Ycentre-stimpars.letterEccentricityPX)];
Pos2 = [round(screen.Xcentre+(stimpars.letterEccentricityPX/sqrt(2))), round(screen.Ycentre-(stimpars.letterEccentricityPX/sqrt(2)))];
Pos3 = [round(screen.Xcentre+stimpars.letterEccentricityPX), round(screen.Ycentre)];
Pos4 = [round(screen.Xcentre+(stimpars.letterEccentricityPX/sqrt(2))), round(screen.Ycentre+(stimpars.letterEccentricityPX/sqrt(2)))];
Pos5 = [round(screen.Xcentre), round(screen.Ycentre+stimpars.letterEccentricityPX)];
Pos6 = [round(screen.Xcentre-(stimpars.letterEccentricityPX/sqrt(2))), round(screen.Ycentre+(stimpars.letterEccentricityPX/sqrt(2)))];
Pos7 = [round(screen.Xcentre-stimpars.letterEccentricityPX), round(screen.Ycentre)];
Pos8 = [round(screen.Xcentre-(stimpars.letterEccentricityPX/sqrt(2))), round(screen.Ycentre-(stimpars.letterEccentricityPX/sqrt(2)))];

%=======================================================================
% compute centres of CUE texture rectangles to draw at each position
%=======================================================================
cue1 = [round(screen.Xcentre), round(screen.Ycentre-stimpars.cueEccentricityPX)];
cue2 = [round(screen.Xcentre + (stimpars.cueEccentricityPX/sqrt(2))), round(screen.Ycentre-(stimpars.cueEccentricityPX/sqrt(2)))];
cue3 = [round(screen.Xcentre + stimpars.cueEccentricityPX), round(screen.Ycentre)];
cue4 = [round(screen.Xcentre + (stimpars.cueEccentricityPX/sqrt(2))), round(screen.Ycentre+(stimpars.cueEccentricityPX/sqrt(2)))];
cue5 = [round(screen.Xcentre), round(screen.Ycentre+stimpars.cueEccentricityPX)];
cue6 = [round(screen.Xcentre - (stimpars.cueEccentricityPX/sqrt(2))), round(screen.Ycentre+(stimpars.cueEccentricityPX/sqrt(2)))];
cue7 = [round(screen.Xcentre - stimpars.cueEccentricityPX), round(screen.Ycentre)];
cue8 = [round(screen.Xcentre - (stimpars.cueEccentricityPX/sqrt(2))), round(screen.Ycentre-(stimpars.cueEccentricityPX/sqrt(2)))];

%=======================================================================
% compute centres of CIRCLES texture rectangles to draw at each position
%=======================================================================
% the numbers in paranthesis are from Persuh (2012) from their task in
% Presentation Neurobehavioural Systems 

% circle1 = [round(screen.Xcentre+(-28)) ,round(screen.Ycentre+(-25))];
% circle2 = [round(screen.Xcentre+(30)) ,round(screen.Ycentre+(0))];
% circle3 = [round(screen.Xcentre+(6)) ,round(screen.Ycentre+(16))];
% circle4 = [round(screen.Xcentre+(-5)) ,round(screen.Ycentre+(-15))]; % instead of -11 for Y because it was oculding the fixation cross
% circle5 = [round(screen.Xcentre+(-3)) ,round(screen.Ycentre+(38))];
% circle6 = [round(screen.Xcentre+(-25)) ,round(screen.Ycentre+(23))];
% circle7 = [round(screen.Xcentre+(-23)) ,round(screen.Ycentre+(1))];
% circle8 = [round(screen.Xcentre+(27)) ,round(screen.Ycentre+(40))];
% circle9 = [round(screen.Xcentre+(0)) ,round(screen.Ycentre+(-36))];
% circle10 = [round(screen.Xcentre+(23)) ,round(screen.Ycentre+(-23))];

% circle1 = [round(screen.Xcentre+(-45)) ,round(screen.Ycentre+(-42))];
% circle2 = [round(screen.Xcentre+(57)) ,round(screen.Ycentre+(0))];
% circle3 = [round(screen.Xcentre+(26)) ,round(screen.Ycentre+(36))];
% circle4 = [round(screen.Xcentre+(-15)) ,round(screen.Ycentre+(-20))];
% circle5 = [round(screen.Xcentre+(-7)) ,round(screen.Ycentre+(50))];
% circle6 = [round(screen.Xcentre+(-25)) ,round(screen.Ycentre+(23))];
% circle7 = [round(screen.Xcentre+(-47)) ,round(screen.Ycentre+(1))];
% circle8 = [round(screen.Xcentre+(27)) ,round(screen.Ycentre+(-15))];
% circle9 = [round(screen.Xcentre+(0)) ,round(screen.Ycentre+(-54))];
% circle10 = [round(screen.Xcentre+(35)) ,round(screen.Ycentre+(-46))];

circle1 = [round(screen.Xcentre+(0)) ,round(screen.Ycentre+(-27))];
circle2 = [round(screen.Xcentre+(35)) ,round(screen.Ycentre+(-33))];
circle3 = [round(screen.Xcentre+(25)) ,round(screen.Ycentre+(3))];% y= 10
circle4 = [round(screen.Xcentre+(-35)) ,round(screen.Ycentre+(-33))]; % instead of -11 for Y because it was oculding the fixation cross
circle5 = [round(screen.Xcentre+(-25)) ,round(screen.Ycentre+(3))];% y =10
circle6 = [round(screen.Xcentre+(0)) ,round(screen.Ycentre+(27))];
circle7 = [round(screen.Xcentre+(-35)) ,round(screen.Ycentre+(33))];
circle8 = [round(screen.Xcentre+(-25)) ,round(screen.Ycentre+(-3))]; % y= -10
circle9 = [round(screen.Xcentre+(35)) ,round(screen.Ycentre+(33))];
circle10 = [round(screen.Xcentre+(25)) ,round(screen.Ycentre+(-3))]; % y =-10


n=15;
circle1 = [circle1(1,1), circle1(1,2)-n];
circle2 = [circle2(1,1)+n, circle2(1,2)-n];
circle3 = [circle3(1,1)+n, circle3(1,2)+n];
circle4 = [circle4(1,1)-n, circle4(1,2)-n];
circle5 = [circle5(1,1)-n, circle5(1,2)+n];
circle6 = [circle6(1,1), circle6(1,2)+n];
circle7 = [circle7(1,1)-n, circle7(1,2)+n];
circle8 = [circle8(1,1)-n, circle8(1,2)-n];
circle9 = [circle9(1,1)+n, circle9(1,2)+n];
circle10= [circle10(1,1)+n, circle10(1,2)-n];


%=======================================================================
% retrieve codes for response keys
%=======================================================================
KbName('UnifyKeyNames');
S=KbName('s');
D=KbName('d');
F=KbName('f');
H=KbName('h');
J=KbName('j');
K=KbName('k');
L=KbName('l');
Z=KbName('z');
X=KbName('x');
C=KbName('c');
V=KbName('v');
B=KbName('b');
N=KbName('n');
M=KbName('m');
ESC=KbName('ESCAPE');
highCD = KbName('UpArrow'); % up arrow = high CD
lowCD = KbName('DownArrow'); %  down arrow = low CD
noVS = KbName('RightArrow'); % right arrow = I did not see the target 
yesVS = KbName('LeftArrow'); %  left arrow = I did see the target 
space = KbName('space'); % press space to advance the task 

%=======================================================================
%load letters, resize and add alpha
%=======================================================================
for stimN = 1:size(stimuli,2) % 14 letters to choose from 
    
%load letter image
%[lettImg map alpha]=imread(['C:\experiments\Roberto\Amalia\Icomem EEG\' stimuli{stimN} '.png'], 'PNG'); %for Windows
 [lettImg map alpha]=imread([loc, stimuli{stimN} '.png'], 'PNG'); %for MAC
%add a fourth "alpha level" to the image 
lettImg(:,:,4) = alpha;
%resize to match desired size in VD
lettImg = imresize(lettImg,[stimpars.letterSizePX stimpars.letterSizePX]);
letterSet(:,:,:,stimN)=lettImg; % not preallocating space here for flexibility

end

%=======================================================================
%load cue, resize and add alpha
%=======================================================================

%[cue mapCue alphaCue]=imread('C:\experiments\Roberto\Amalia\Icomem EEG\cue.png', 'PNG'); %for Windows
[cue mapCue alphaCue] = imread([loc, 'cue.png'], 'PNG'); %for MAC
cue(:,:,4) = alphaCue;
%resize to match desired size in VD
cue = imresize(cue, stimpars.cueSizePX);

%=======================================================================
%load small white circles, resize 
%=======================================================================
% for smooth circle 
[smooth_circle map_smooth_Circle alpha_smooth_Circle]=imread([loc, 'C1.tiff'], 'TIFF'); %for MAC
smooth_circle = imresize(smooth_circle,[stimpars.smooth_circleSizePX stimpars.smooth_circleSizePX]);
%smooth_circle = imresize(smooth_circle, [20 20]);
smooth_circle_size = size(smooth_circle); % get the size of the resized image to use for display later on


% for pegged circle 
[pegged_circle map_peggrd_Circle alpha_pegged_Circle]=imread([loc, 'C3.tiff'], 'TIFF'); %for MAC
pegged_circle = imresize(pegged_circle,[stimpars.pegged_circleSizePX stimpars.pegged_circleSizePX + 8]); % + stimpars.pegg_SizePY
%pegged_circle = imresize(pegged_circle, [20 25]);
pegged_circle_size = size(pegged_circle); % get the size of the resized image to use for display later on

%=======================================================================
% specs for the background (grey) circle 
%=======================================================================
grey = 111;% col for background circle 
circle_size = 90;% radius of grey circle

%=======================================================================
% ask participant details
%=======================================================================
prompt={'Subject No (01-99):','Initials:', 'Gender (M/F):', 'Age:', 'Handedness (L/R):', 'Block No (01-99):'};
name='IcoMem';
numlines=1;
defaultanswer={'99','XX','F','0','R','00'};
 
answer=inputdlg(prompt,name,numlines,defaultanswer);
% these will be used in the save name at the end of the experiment 
subNo=answer{1};
subName=answer{2};
subSex=answer{3};
subAge=str2num(answer{4});
subHand=answer{5};
subCode=[answer{1} '_' answer{2}];
blockN=answer{6};


%=======================================================================
%% START task
%=======================================================================

PsychImaging('PrepareConfiguration'); % Prepare setup of imaging pipeline for onscreen window.
% This is the first step in the sequence of configuration steps.

PsychImaging('AddTask', 'General', 'FloatingPoint32BitIfPossible'); % Add a specific task or processing requirement to the list of actions
% to be performed by the pipeline for the currently selected onscreen window.

% Set to ?General? if the
% command doesn?t apply to a specific view, but is a general requirement.

% FloatingPoint32BitIfPossible? Ask PTB to choose the highest precision
% that is possible on your hardware without sacrificing functionality like,
% e.g., alpha-blending. PTB will choose the best compromise possible for
% your hardware setup.

AssertOpenGL; % Break and issue an eror message if the installed Psychtoolbox is not
% based on OpenGL or Screen() is not working properly

%oldVisualDebugLevel = Screen('Preference', 'VisualDebugLevel', 3);
%oldSupressAllWarnings = Screen('Preference', 'SuppressAllWarnings', 1);

% =======================================================================
% the black background
% =======================================================================
[win, winRect] = Screen('OpenWindow', screen.id, [0 0 0]);
Screen('BlendFunction', win, GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
% ========================================================
% INITIALISE EYETRACKER
% ========================================================
            
dummymode=0;       % set to 1 to initialize in dummymode
if UseEyetracker
    etname = [subCode '_' blockN '.edf']
    el = EyelinkInitDefaults(win);
    if ~EyelinkInit(dummymode)
        fprintf('Eyelink Init aborted.\n');
        cleanup;  % cleanup function
        return;
    end

    [v vs]=Eyelink('GetTrackerVersion');
    %fprintf('Running experiment on a ''%s'' tracker.\n', vs ); xb
    % open file for recording data
    Eyelink('Openfile', etname);
    % Do setup and calibrate the eye tracker
    fprintf('\n---------------------------------\n');
    fprintf('\nPress c to run calibration \n');
    fprintf('When finished press v to run validation \n');
    fprintf('Press ESC to continue \n\n');
    fprintf('\n---------------------------------\n');
    EyelinkDoTrackerSetup(el);
    pause(1);
    % VERY IMPORTANT TO DO THIS IF YOU USE SOUNDS LATER ON
    Snd('Close'); % immediately stops all sound and closes the channel.  
    
end

%=======================================================================
% remake the background black after eye-tracking C/V
%=======================================================================
Screen('FillRect', win, [0 0 0]); 

%=======================================================================
% timing parameters
%=======================================================================
topPriorityLevel = MaxPriority(win);% Retreive the maximum priority number
Priority(topPriorityLevel); %it is now suggested that you set Priority once at the start of a script after setting up your onscreen window.

ifi = Screen('GetFlipInterval', win); % Returns an estimate of the monitor flip interval for the specified onscreen window 
                                       % use this to find the PERIOD = how long it takes to complete 1 cycle (T=1/f)

% Length of time and number of frames we will use for each drawing test
numSecs = 1;
numFrames = round(numSecs / ifi);
% Numer of frames to wait when specifying good timing.  For example, by using waitframes = 2 one would flip on every other frame.
waitframes_fix = 100; %1sec
waitframes_att = 40; % 400ms
waitframes_lett = 5; % 50 ms
waitframes_delay = 6; % 60ms
waitframes_cue = 1; % 10ms

%=======================================================================
% set the refresh rate
%=======================================================================
hz = Screen('NominalFrameRate', win,1);% [, mode] [, reqFrameRate]);
if round(hz) ~=100
    sca
    error('Set the correct refresh rate!!!')
end 

%=======================================================================
%first flip to get vbl
%=======================================================================    
vbl = Screen('Flip', win); %  returns a high-precision estimate of the system time (in seconds) when the actual flip has happened
                     


HideCursor 
%=======================================================================
%retrieve the size of one letter texture as a seed (they're all the same size)
%=======================================================================
textLett=Screen('MakeTexture',win, letterSet(:,:,:,1)); % select the 1st letter, it doesn't matter since they are all the same
rect=Screen('Rect', textLett);

%======================================================================= 
% compute centres of all the letter textures to display (this is done only once on the first trial)
%=======================================================================
rect1 = CenterRectOnPoint(rect, Pos1(1), Pos1(2));
rect2 = CenterRectOnPoint(rect, Pos2(1), Pos2(2));
rect3 = CenterRectOnPoint(rect, Pos3(1), Pos3(2));
rect4 = CenterRectOnPoint(rect, Pos4(1), Pos4(2));
rect5 = CenterRectOnPoint(rect, Pos5(1), Pos5(2));
rect6 = CenterRectOnPoint(rect, Pos6(1), Pos6(2));
rect7 = CenterRectOnPoint(rect, Pos7(1), Pos7(2));
rect8 = CenterRectOnPoint(rect, Pos8(1), Pos8(2));
letterPos=[rect1' rect2' rect3' rect4' rect5' rect6' rect7' rect8'];%positions of all letters



%=======================================================================
%retrieve the size of the cue texture
%=======================================================================
cueText = Screen('MakeTexture',win, cue);
cueRect=Screen('Rect', cueText);

%=======================================================================
%compute centres of all the cue textures to display
%=======================================================================
% (this is done only once on the first trial)
% you have to do 8 cues (1 for each letter)
cueRect1 = CenterRectOnPoint(cueRect, cue1(1), cue1(2));
cueRect2 = CenterRectOnPoint(cueRect, cue2(1), cue2(2));
cueRect3 = CenterRectOnPoint(cueRect, cue3(1), cue3(2));
cueRect4 = CenterRectOnPoint(cueRect, cue4(1), cue4(2));
cueRect5 = CenterRectOnPoint(cueRect, cue5(1), cue5(2));
cueRect6 = CenterRectOnPoint(cueRect, cue6(1), cue6(2));
cueRect7 = CenterRectOnPoint(cueRect, cue7(1), cue7(2));
cueRect8 = CenterRectOnPoint(cueRect, cue8(1), cue8(2));
% put all cue positions together
cuePos = [cueRect1; cueRect2; cueRect3; cueRect4; cueRect5; cueRect6; cueRect7; cueRect8];%positions of all cues

%=======================================================================
% retrieve the size of the circle texture (smooth and pegged circle)
%=======================================================================
% for smooth circle
smooth_circleText = Screen('MakeTexture',win, smooth_circle);

% for pegged circle
pegged_circleText = Screen('MakeTexture',win, pegged_circle);

smooth_circleRect = Screen('Rect', smooth_circleText(1)); % for smooth
pegged_circleRect = Screen('Rect', pegged_circleText); % for pegged


%=======================================================================
% compute centres of circle textures to display
%=======================================================================
% (this is done only once on the first trial)
% as in Persuh et al, 2012 on any given trial there are only 8
% circles displayed (though you have 10 pre-determined
% positions)

smooth_circleRect1 = CenterRectOnPoint(smooth_circleRect, circle1(1), circle1(2));
smooth_circleRect2 = CenterRectOnPoint(smooth_circleRect, circle2(1), circle2(2));
smooth_circleRect3 = CenterRectOnPoint(smooth_circleRect, circle3(1), circle3(2));
smooth_circleRect4 = CenterRectOnPoint(smooth_circleRect, circle4(1), circle4(2));
smooth_circleRect5 = CenterRectOnPoint(smooth_circleRect, circle5(1), circle5(2));
smooth_circleRect6 = CenterRectOnPoint(smooth_circleRect, circle6(1), circle6(2));
smooth_circleRect7 = CenterRectOnPoint(smooth_circleRect, circle7(1), circle7(2));
smooth_circleRect8 = CenterRectOnPoint(smooth_circleRect, circle8(1), circle8(2));
smooth_circleRect9 = CenterRectOnPoint(smooth_circleRect, circle9(1), circle9(2));
smooth_circleRect10 = CenterRectOnPoint(smooth_circleRect, circle10(1), circle10(2));

pegged_circleRect1 = CenterRectOnPoint(pegged_circleRect, circle1(1), circle1(2));
pegged_circleRect2 = CenterRectOnPoint(pegged_circleRect, circle2(1), circle2(2));
pegged_circleRect3 = CenterRectOnPoint(pegged_circleRect, circle3(1), circle3(2));
pegged_circleRect4 = CenterRectOnPoint(pegged_circleRect, circle4(1), circle4(2));
pegged_circleRect5 = CenterRectOnPoint(pegged_circleRect, circle5(1), circle5(2));
pegged_circleRect6 = CenterRectOnPoint(pegged_circleRect, circle6(1), circle6(2));
pegged_circleRect7 = CenterRectOnPoint(pegged_circleRect, circle7(1), circle7(2));
pegged_circleRect8 = CenterRectOnPoint(pegged_circleRect, circle8(1), circle8(2));
pegged_circleRect9 = CenterRectOnPoint(pegged_circleRect, circle9(1), circle9(2));
pegged_circleRect10 = CenterRectOnPoint(pegged_circleRect, circle10(1), circle10(2));


% put all circle postions together

smooth_circlePos = [smooth_circleRect1', smooth_circleRect2', smooth_circleRect3', smooth_circleRect4', smooth_circleRect5', smooth_circleRect6', ...
    smooth_circleRect7', smooth_circleRect8',smooth_circleRect9',smooth_circleRect10'];%positions of all circles


pegged_circlePos = [pegged_circleRect1', pegged_circleRect2', pegged_circleRect3', pegged_circleRect4', pegged_circleRect5', pegged_circleRect6', ...
    pegged_circleRect7', pegged_circleRect8',pegged_circleRect9',pegged_circleRect10'];%positions of all circles
         
%=======================================================================
% Timming accuracy check 
%=======================================================================
actual_time = zeros(nTrials,10);
heading = { 'vbl_fix1', 'vbl_break', 'vbl_att', 'vbl_lett', 'vbl_fix2', 'vbl_retro', 'vbl_fix3', 'vbl_cd', 'vbl_target'};

%=======================================================================
% Start screen
%=======================================================================
text='Press spacebar to start experiment';
Screen('TextSize',win,50);
Screen('TextFont', win, 'Arial');
DrawFormattedText(win, text, 'center', 'center', [255 255 255]);
vbl_start = Screen('Flip',win, vbl - 0.5 * ifi);

% spacebar press to advance the task
keyCode_space(1,1:256) = 0;


while   keyCode_space(1,space)~=1 && keyCode_space(1,ESC)~=1
    
    [keyIsDown_space, secs_space, keyCode_space, deltaSecs_space] = KbCheck;
    
    if  keyCode_space(1,space)==1
      
        
        
    elseif keyCode_space(1,ESC)==1
        %sca
        
        Screen('CloseAll')
        ShowCursor
        
        error('experiment aborted!');
    end
    
    % record the button press
    buttonPress_start = GetSecs;
end


% ========================================================
% START Eye Tracking DATA COLLECTION
% ========================================================
if UseEyetracker
  Eyelink('StartRecording');
  pause(0.05)
  %   Eyelink('message',sprintf('TRIALID %d',itrial));
  %   pause(0.05)
end
%%

for currTrial = 1:nTrials %1:nTrials %[1,48,49,97,98];%[1,98,99,100,101] %[1,2,49,50]; %1:nTrials;  % [1,2,49,50]; 

KbReleaseWait(); % Start the trial only after all keys have been released.
ITIstart = GetSecs; % returns the time in seconds    
    
    %=======================================================================
    % generate random letter sequence
    %=======================================================================
    randLett = randperm(size(stimuli,2)); % for all 14 letters
    presentedLett(currTrial,:) = randLett;
    
    %=======================================================================
    % select Attention condition for current trial
    %=======================================================================
    %  randAtt(1:32,1) = 3; % uncomment in case you want to test some code
    %randAtt = zeros(size(randAtt));
    Att_currTrial = randAtt(currTrial);
    
    %===================================================================================================
    % select the CD condition for current trial and plug it into the GetColorsForSpecificLevel2 function
    %===================================================================================================
    %randCD(1:32,1) = 1; % uncomment in case you want to test some code
    CD_currTrial = randCD(currTrial); % 1 = low; 2=high
    StartingColor = randi(AmountOfColors, TotalNumOfTrials, 1); % the starting col from the color palet
    StartinColorLog(currTrial,1) = StartingColor;
    selected_cols = GetColorsForSpecificLevel2(Colors, StartingColor, CD_currTrial, 8 ); % use the Bronfman function to generate cols either with high or low diversity
    %selected_cols = ones(8,3)*255; % if you need to test timing
    colors = repmat(selected_cols,1,2);
    colors = colors';% needs to be transposed for drawing multiple textures at once
    
    %===============================================================================
    % prepare textures to display in this trial for letters + cue + att circles
    %===============================================================================
    % for letters
    text1=Screen('MakeTexture',win, letterSet(:,:,:,randLett(1))); %textureIndex=Screen('MakeTexture', WindowIndex, imageMatrix [, optimizeForDrawAngle=0] [, specialFlags=0] [, floatprecision=0] [, textureOrientation=0] [, textureShader=0]);
    text2=Screen('MakeTexture',win, letterSet(:,:,:,randLett(2))); % Convert the 2D or 3D matrix ?imageMatrix? into an OpenGL texture and return an
                                                                   % index which may be passed to ?DrawTexture? to specify the texture.
    text3=Screen('MakeTexture',win, letterSet(:,:,:,randLett(3)));
    text4=Screen('MakeTexture',win, letterSet(:,:,:,randLett(4)));
    text5=Screen('MakeTexture',win, letterSet(:,:,:,randLett(5)));
    text6=Screen('MakeTexture',win, letterSet(:,:,:,randLett(6)));
    text7=Screen('MakeTexture',win, letterSet(:,:,:,randLett(7)));
    text8=Screen('MakeTexture',win, letterSet(:,:,:,randLett(8)));
    allTexts=[text1; text2; text3; text4; text5; text6; text7; text8];
    
    % for cue
    cueText = Screen('MakeTexture',win, cue);
    
    % for smooth circle
    smooth_circleText = Screen('MakeTexture',win, smooth_circle);
    
    % for pegged circle
    pegged_circleText = Screen('MakeTexture',win, pegged_circle);
    
    %=======================================================================
    % put together the circle textures used on each trial
    %=======================================================================
    if Att_currTrial == 1 % 1=easy VSeach condition
        circle_Text = [repmat(smooth_circleText,7,1);repmat(pegged_circleText,1,1)];
        %circle_Text = [repmat(smooth_circleText,9,1);repmat(pegged_circleText,1,1)];
        
    elseif Att_currTrial == 2 % 2=hard VSeach condition
        circle_Text = [repmat(smooth_circleText,1,1);repmat(pegged_circleText,7,1)];
        %   circle_Text = [repmat(smooth_circleText,1,1);repmat(pegged_circleText,9,1)];
        
    elseif Att_currTrial == 3 % 3= easy catch condition (ie only smooth cirsles)
        circle_Text = repmat(smooth_circleText,8,1);
        %circle_Text = repmat(smooth_circleText,10,1);
        
    elseif Att_currTrial == 4 % 4= hard catch condition (ie only pegged cirsles)
        circle_Text = repmat(pegged_circleText,8,1);
        %    circle_Text = repmat(pegged_circleText,10,1);
        
    end % end the att condition branching for textures
    
    %=======================================================================
    % randomize the position of the small circles (has to be done
    % before if loop)
    %=======================================================================
    rand_circlePos(currTrial,:) = randperm(size(rand_circlePos,2)); % randomize the 10 possible postition for the white circles
    selected_circlePos(currTrial,:) = datasample(rand_circlePos(currTrial,:),no_selected_positions,'Replace', false); % pick 8 positions (sample without replacements)

    % ===============================================================
    % select position of attention circles depending on att condition
    % ===============================================================
    
    if Att_currTrial == 1 % 1=easy VSeach condition
        
        selected_smoothCirclePos = smooth_circlePos(:,selected_circlePos(currTrial,1:7));
        selected_peggedCirclePos = pegged_circlePos(:,selected_circlePos(currTrial,8));
        final_circlePos =[selected_smoothCirclePos,selected_peggedCirclePos] ;
        %final_circlePos = smooth_circlePos;
        
    elseif Att_currTrial == 2 % 2=hard VSearch condition
        selected_smoothCirclePos = smooth_circlePos(:,selected_circlePos(currTrial,8));
        selected_peggedCirclePos = pegged_circlePos(:,selected_circlePos(currTrial,1:7));
        final_circlePos =[selected_smoothCirclePos,selected_peggedCirclePos] ;
        % final_circlePos = pegged_circlePos;
        
    elseif Att_currTrial == 3 % 3=easy VSeach CATCH condition
        selected_smoothCirclePos = smooth_circlePos(:,selected_circlePos(currTrial,1:8));
        final_circlePos = selected_smoothCirclePos;
        %final_circlePos = smooth_circlePos;
        
    elseif Att_currTrial == 4 % 4=hard VSeach CATCH condition
        selected_peggedCirclePos = pegged_circlePos(:,selected_circlePos(currTrial,1:8));
        final_circlePos = selected_peggedCirclePos;
        %final_circlePos = pegged_circlePos;
        
    end % end of position selection/condition loop
    
    %=======================================================================
    % compute cue position and orientation for this trial
    %=======================================================================
    cuePosThisTrial = cuePos(cueposList(fullTrialOrder(currTrial)),:); % find the postion of the cue
    cueOriThisTrial = cueoriList(fullTrialOrder(currTrial)); % find the orientation of the cue
    %stimOnset = zeros(length(stimpars.letterDuration) +1 ,1);
    stimOnset=zeros(4,1);
    
    %=======================================================================
    % calculate ITI including computation time before stim display
    %=======================================================================
    thisTrialITI(currTrial,1)=(ITIList(fullTrialOrder(currTrial),1));
    computEnd = GetSecs;
    computTime = computEnd-ITIstart;
    ITIreal(currTrial,1) = thisTrialITI(currTrial,1)-computTime;
    WaitSecs(ITIreal(currTrial,1));
    
    
    %=======================================================
    % update LETTER logs for this trial; this is the letter that was
    % presented, NOT reported
    %=======================================================
    trialN(currTrial,1) = currTrial;
    targetID(currTrial,1) = (stimuli(1,randLett(cueposList(fullTrialOrder(currTrial),1))));
    targetIDnum(currTrial,1) = KbName(targetID(currTrial,1));
    targetPos(currTrial,1) = cueposList(fullTrialOrder(currTrial),1);

%=======================================================================
% finally display stimuli
%=======================================================================

%=======================================================================
%  Display fixation dot 
%=======================================================================
Screen('FillOval', win, grey, [screen.Xcentre - circle_size, screen.Ycentre - circle_size, screen.Xcentre + circle_size, screen.Ycentre + circle_size]);  % make a circle and display it
Screen('DrawDots', win,[screen.Xcentre screen.Ycentre],10, [255 255 255]);
vbl_fix1 = Screen('Flip',win); % make it wait 1 sec(fix_dur) on each trial % tell it to be ready to draw half a frame in advance
actual_time(currTrial,1) = vbl_fix1;
trialStart = GetSecs;

% create a counter which will be used in the edf name
brk_count =0;
%=======================================================================
% Eye tracker Trigger
%=======================================================================
if UseEyetracker
    Eyelink('message', num2str(currTrial)); 
end
         
            
            %=======================================================================          
            % an if loop for BREAKS % if the Att_currTrial is = 5 then display the break screen 
            %=======================================================================
            
            if Att_currTrial == 5  % if the currTril is = 5 then display the break screen 
                                    % IMPORTANT 3 here is not an att
                                    % condition but a trick to put up the
                                    % brak screen
            
                                    
            % stop the eye tracker 
            if UseEyetracker
                Eyelink('stoprecording');
            end
            
            % create a counter which will be used in the edf name
            brk_count = brk_count+1;           
            % save where the breaks are
            respLett(currTrial,1) = {'break'};
            respCD(currTrial,1) = {'break'};
            respVS(currTrial,1) = {'break'};
                
            
            % save the data from each block 
            workspace_name=['Workspace_' datestr(now,'dd_mm_yy_HH-MM-SS')]; % day mounth year, hour minute sec
            savepath = [pwd '/data/'];
            save ([savepath workspace_name]);
            
            % the break screen
            Screen('TextSize',win,50);
            Screen('TextFont', win, 'Arial');
            DrawFormattedText(win, 'Please take a break!', 'center', 'center', [255 255 255]);
            DrawFormattedText(win, 'Press space when you want to continue.', 'center',  screen.Ycentre + 130, [255 255 255]);
            vbl_break = Screen('Flip',win); % don't care about timing here 
            actual_time(currTrial,2) = vbl_break;
                                    
            % spacebar press to advance the task 
            keyCode_break(1,1:256) = 0;
   
           
            while   keyCode_break(1,space)~=1 && keyCode_break(1,ESC)~=1
                
                [keyIsDown_space, secs_space, keyCode_break, deltaSecs_space] = KbCheck;
                
                if  keyCode_break(1,space)==1      
                    
                elseif keyCode_break(1,ESC)==1
                    %sca
                    
                    Screen('CloseAll')
                    ShowCursor
           
                    error('experiment aborted!');         
                end
                
                % record when the response was made
                buttonPress_space=GetSecs;
            end % end of while loop 
            
            % ========================================================
            % INITIALISE EYETRACKER
            % ========================================================
            
            dummymode=0;       % set to 1 to initialize in dummymode
            if UseEyetracker
            etname = [subName '_' brk_count+48 '.edf'];    
                el = EyelinkInitDefaults(win);
                if ~EyelinkInit(dummymode)
                    fprintf('Eyelink Init aborted.\n');
                    cleanup;  % cleanup function
                    return;
                end
                
                [v vs]=Eyelink('GetTrackerVersion');
                %fprintf('Running experiment on a ''%s'' tracker.\n', vs ); xb
                % open file for recording data
                Eyelink('Openfile', etname);
                % Do setup and calibrate the eye tracker
                fprintf('\n---------------------------------\n');
                fprintf('\nPress c to run calibration \n');
                fprintf('When finished press v to run validation \n');
                fprintf('Press ESC to continue \n\n');
                fprintf('\n---------------------------------\n');
                EyelinkDoTrackerSetup(el);
                pause(1);
                % VERY IMPORTANT TO DO THIS IF YOU USE SOUNDS LATER ON
                Snd('Close'); % immediately stops all sound and closes the channel.
            end
            
            % ========================================================
            % START Eye Tracking DATA COLLECTION
            % ========================================================
            if UseEyetracker
                Eyelink('StartRecording');
                pause(0.05)
                %   Eyelink('message',sprintf('TRIALID %d',itrial));
                %   pause(0.05)
            end
            
            %=======================================================================
            % remake the background black after eye-tracking C/V
            %=======================================================================
            Screen('FillRect', win, [0 0 0]);
                
            %=======================================================================          
            % an if loop for easy and hard att manipulation
            % (Att_currTrial==1 or 2) and for eacy and hard catch trials (Att_currTrial == 3 or 4) 
            %=======================================================================
                
            % display for the easy and hard att manipulation + easy and had
            % catch trials 
            elseif Att_currTrial ==1 || Att_currTrial ==2 || Att_currTrial ==3 || Att_currTrial ==4
               
                % present the att task in advance for 300 ms 
                Screen('FillOval', win, grey, [screen.Xcentre - circle_size, screen.Ycentre - circle_size, screen.Xcentre + circle_size, screen.Ycentre + circle_size]);  % make a circle and display it
                Screen('DrawDots', win,[screen.Xcentre screen.Ycentre],10, [255 255 255]);
                Screen('DrawTextures', win,circle_Text,[],final_circlePos,...
                    [],[],[],[]); % draw the white circles
                vbl_att = Screen('Flip',win, vbl_fix1 + (waitframes_fix - 0.5) * ifi);
                actual_time(currTrial,3) = vbl_att;
              
               
                % present the letters for 50 ms only 
                Screen('FillOval', win, grey, [screen.Xcentre - circle_size, screen.Ycentre - circle_size, screen.Xcentre + circle_size, screen.Ycentre + circle_size]);  % make a circle and display it
                Screen('DrawDots', win,[screen.Xcentre screen.Ycentre],10, [255 255 255]);
                Screen('DrawTextures', win, allTexts, [], letterPos, [], [], [], [colors(colorsetList(fullTrialOrder(currTrial)):colorsetList(fullTrialOrder(currTrial))+2,:)]);
                Screen('DrawTextures', win,circle_Text,[],final_circlePos,...
                    [],[],[],[]); % draw the white circles
                vbl_lett = Screen('Flip',win, vbl_att + (waitframes_att - 0.5) * ifi);   
                actual_time(currTrial,4) = vbl_lett;
                
                %=======================================================================
                %  get rid of stim and display fixation dot only
                %=======================================================================
                Screen('DrawDots', win,[screen.Xcentre screen.Ycentre],10, [255 255 255]);
                vbl_fix2 = Screen('Flip', win, vbl_lett + (waitframes_lett - 0.5) * ifi);
                actual_time(currTrial,5) = vbl_fix2;
                stimOff_ISIstart = GetSecs;
                
                %=======================================================================
                % display retro-cue
                %=======================================================================
                Screen('DrawDots', win,[screen.Xcentre screen.Ycentre],10, [255 255 255]);
                Screen('DrawTexture', win, cueText, [ ], cuePosThisTrial, cueOriThisTrial);  %Screen('DrawTexture', windowPointer, texturePointer(s) [, sourceRect(s)] [, destinationRect(s)] [, rotationAngle(s)] [, filterMode(s)] [, globalAlpha(s)] [, modulateColor(s)] [, textureShader] [, specialFlags] [, auxParameters]);
                vbl_retro = Screen('Flip',win, vbl_fix2 + (waitframes_delay - 0.5) * ifi); % disp the retro cue in 40 ms 
                actual_time(currTrial,6) = vbl_retro;
                ISIend = GetSecs;
                
                %=======================================================================
                % present fixation dot
                %=======================================================================
                Screen('DrawDots', win,[screen.Xcentre screen.Ycentre],10, [255 255 255]);
                vbl_fix3 = Screen('Flip',win, vbl_retro + (waitframes_cue - 0.5) * ifi);
                actual_time(currTrial,7) = vbl_fix3;
                WaitSecs(0.9);
                
                %=======================================================================
                % Screen for the LETT question
                %=======================================================================
                Screen('TextSize',win,50);
                Screen('TextFont', win, 'Arial');
                DrawFormattedText(win, 'Letter?', 'center', 'center', [255 255 255]);
                vbl_lettQ = Screen('Flip',win);     
                actual_time(currTrial,10) = vbl_lettQ;
                
                 %=======================================================================
                 % use when debuging to give ans for lett 
                 %=======================================================================
                 keyCode(1,1:256) = 0; 
                 if debug_mode == 1
                     
                     pos = randi(length(stimuli));
                     keyCode(1,KbName(stimuli(pos)))= 1;
                     respLett(currTrial,1) = stimuli(pos);
                 end 
                 
                 
                %=======================================================================
                % response keys for letter task
                %=======================================================================
                % keyCode(1,1:256) = 0; 
                
                while   keyCode(1,S)~=1 && keyCode(1,D)~=1 && keyCode(1,F)~=1 && keyCode(1,H)~=1 && keyCode(1,J)~=1 && keyCode(1,K)~=1 && ...
                        keyCode(1,L)~=1 && keyCode(1,Z)~=1 && keyCode(1,X)~=1 && keyCode(1,C)~=1 && keyCode(1,V)~=1 && ...
                        keyCode(1,B)~=1 && keyCode(1,N)~=1 && keyCode(1,M)~=1 && keyCode(1,ESC)~=1
                    
                    
                    [keyIsDown, secs, keyCode, deltaSecs] = KbCheck;
                    
                    
                    if keyCode(1,S)==1
                       
                        respLett(currTrial,1) = {'S'} ;
                        
                    elseif keyCode(1,D)==1
                       
                        respLett(currTrial,1) = {'D'};
                        
                    elseif keyCode(1,F)==1
                        
                        respLett(currTrial,1) = {'F'};
                        
                    elseif keyCode(1,H)==1
                        
                        respLett(currTrial,1) = {'H'};
                        
                    elseif keyCode(1,J)==1
                        
                        respLett(currTrial,1) = {'J'};
                        
                    elseif keyCode(1,K)==1
                        respLett(currTrial,1) = {'K'};
             
                        
                    elseif keyCode(1,L)==1
              
                        respLett(currTrial,1) = {'L'};
                        
                    elseif keyCode(1,Z)==1
           
                        respLett(currTrial,1) = {'Z'};
                        
                    elseif keyCode(1,X)==1
           
                        respLett(currTrial,1) = {'X'};
                        
                    elseif keyCode(1,C)==1
                      
                        respLett(currTrial,1) = {'C'};
                        
                    elseif keyCode(1,V)==1

                        respLett(currTrial,1) = {'V'};
                        
                    elseif keyCode(1,B)==1
                   
                        respLett(currTrial,1) = {'B'};
                        
                    elseif keyCode(1,N)==1
        
                        respLett(currTrial,1) = {'N'};
                        
                    elseif keyCode(1,M)==1
                      
                        respLett(currTrial,1) = {'M'};
                        
                    elseif keyCode(1,ESC)==1
                        
                       
                        Screen('CloseAll')
                        ShowCursor
                        error('experiment aborted!');
                    end
                    % recorde when the response was made
                    buttonPress_Lett = GetSecs;
                end

                %=======================================================================
                % timestamp to check Letter ITI
                %=======================================================================
                ITIstart = GetSecs;
                
                %=======================================================================
                % Screen for Color-Diversity Question
                %======================================================================= 
                Screen('TextSize',win,50);
                Screen('TextFont', win, 'Arial');
                DrawFormattedText(win, 'Color-Diversity?', 'center', 'center', [255 255 255]);
                DrawFormattedText(win, 'High', 'center', screen.Ycentre + 100, [255 255 255]);
                DrawFormattedText(win, 'or', 'center', screen.Ycentre + 150, [255 255 255]);
                DrawFormattedText(win, 'Low', 'center', screen.Ycentre + 200, [255 255 255]);
                KbReleaseWait();
                vbl_cd = Screen('Flip',win);     
                actual_time(currTrial,8) = vbl_cd;
                
                
                 %=======================================================================
                 % use when debuging to give ans for CD 
                 %=======================================================================
                 CDkeyCode(1,1:256) = 0;
                 if debug_mode == 1
               
                     CDans = {highCD,lowCD};
                     CDansLett = {'h','l'};
                     posCD = randi(2);
                     CDkeyCode(1,cell2mat(CDans(posCD)))= 1;
                     respCD(currTrial,1) = CDansLett(posCD);
                 end 
                %=======================================================================
                % Response keys for Color-Diversity judgments
                %=======================================================================
                %CDkeyCode(1,1:256) = 0;
                
                while   CDkeyCode(1,highCD)~=1 && CDkeyCode(1,lowCD)~=1 && CDkeyCode(1,ESC)~=1
                    
                    
                    [CDkeyIsDown, CDsecs, CDkeyCode, CDdeltaSecs] = KbCheck;
                    
                    if CDkeyCode(1,highCD)==1
                        
                        respCD(currTrial,1) = {'h'};
                        
                    elseif CDkeyCode(1,lowCD)==1
                       
                        respCD(currTrial,1) = {'l'};
                        
                    elseif CDkeyCode(1,ESC)==1
                        
                        Screen('CloseAll')
                        ShowCursor
                        error('experiment aborted!');
                        
                    end % end if loop
                    
                    % recorde when the response was made
                    buttonPress_CD = GetSecs;
                    
                end % end keypress loop
                
                %=======================================================================
                % timestamp to check CD ITI
                %=======================================================================
                CDITIstart = GetSecs;
                
                %=======================================================================
                % the attention (target identification) question 
                %=======================================================================
                Screen('TextSize',win,50);
                Screen('TextFont', win, 'Arial');
                DrawFormattedText(win, 'Target?', 'center', 'center', [255 255 255]);
                DrawFormattedText(win, 'Yes or No', 'center', screen.Ycentre + 100, [255 255 255]);
                KbReleaseWait();
                vbl_target = Screen('Flip',win);
                actual_time(currTrial,9) = vbl_target;
                
                
                %=======================================================================
                 % use when debuging to give ans for Target 
                 %=======================================================================
                 keyCode_VS(1,1:256) = 0;
                 
                 if debug_mode == 1
               
                     VSans = {noVS,yesVS};
                     VSansLett = {'n','y'};
                     posVS = randi(2);
                     keyCode_VS(1,cell2mat(VSans(posVS)))= 1;
                     respVS(currTrial,1) = VSansLett(posVS);
                 end 
                
                %=======================================================================
                % the key buttons for the VS question
                %=======================================================================
                %keyCode_VS(1,1:256) = 0;
                
                while   keyCode_VS(1,noVS)~=1 && keyCode_VS(1,yesVS)~=1 && keyCode_VS(1,ESC)~=1
                    
                    [keyIsDown_VS, secs_VS, keyCode_VS, deltaSecs_VS] = KbCheck;
                    
                    if  keyCode_VS(1,noVS)==1
                       
                        respVS(currTrial,1) = {'n'};
                        
                        
                    elseif keyCode_VS(1,yesVS)==1
                       
                        respVS(currTrial,1) = {'y'};
                        
                        
                    elseif keyCode_VS(1,ESC)==1
                        %sca
                         
                        Screen('CloseAll')
                        ShowCursor
                        error('experiment aborted!');
                    end
                    % record when the response was made
                    buttonPress_VS=GetSecs;
                    
                end % end keypress loop for Taregt Q
                
                %=======================================================================
                % timestamp to check Att target ITI
                %=======================================================================
                 ATTITIstart = GetSecs;
                 
            end    % end of att condition if loop
           
            % waitforbuttonpress
            % WaitSecs(3)
            
            
           %=======================================================   
           % close all open textures to free memory
           %======================================================= 
           %--- Before closing the window, make sure that all keys are released, so
           %    no key presses "fall through" to the MATLAB's command window
           %    or editor and mess things up there.
           KbReleaseWait();
           Screen('Close',[cueText smooth_circleText pegged_circleText allTexts'])

            

            
end   % end of trial loop


%=======================================================
% transform the randCD from numbers into letters
%=======================================================
for currTrial =1:nTrials
    
if randCD(currTrial,1) == 1
    randCDTransf(currTrial,1) = {'l'};
elseif randCD(currTrial,1) == 2
    randCDTransf(currTrial,1) = {'h'};
end

end % end of trial loop 
%=======================================================   
%save the data
%=======================================================   
workspace_name=['Workspace_' datestr(now,'dd_mm_yy_HH-MM-SS')]; % day mounth year, hour minute sec
savepath = [pwd '/data/'];
save ([savepath workspace_name]);



ListenChar(0);
Priority(0);
    
%=======================================================
% stop eye-tracking
%=======================================================
if UseEyetracker
    Eyelink('stoprecording');
    Eyelink('shutdown');
end

%=======================================================
% goodbye screen
%=======================================================
textEnd='Thank you!';
Screen('TextSize',win,50);
Screen('TextFont', win, 'Arial');
DrawFormattedText(win, textEnd, 'center', 'center', [255 255 255]);
vbl_thanks = Screen('Flip',win);
WaitSecs(2);
Screen('CloseAll')
ShowCursor

toc

