% This is an example script that segments audio data and
% can be used to transcribe verbal responses.

% There are two options here: 
%   (1) a continuous recording that first has to be segmented 
%   into potential words (with some post-hoc control)
%   (2) a structure, in which every recording corresponds to a
%   single word/response/trial.

%% add CARL ressources

pn.CARL_internal = '/Users/kosciessa/OneDrive/Work/Dev/CARLrepos/CARL/internal/';
addpath(pn.CARL_internal)

%% Option 1: pre-existing trial structure
% Use this if you have a seperate voice recording for each to-be-labelled
% trial, e.g., recorded within Psychtoolbox.

% load audio data (as .wav or .mat file)

pn.dataIN = '/Users/kosciessa/OneDrive/Work/Dev/CARLrepos/examples/1105_StroopData_1.mat';
load(pn.dataIN)

AudioData = StroopAudio; clear StroopAudio;

% pre-sequence voice segments: try to mark on- & offsets of the voice segments                            
                                                                            
segments = cell(5,1);
for trial = 1:size(AudioData.audio,2)
    disp([num2str(trial), '/', num2str(size(AudioData.audio,2))]);
    Audio = AudioData.audio{1,trial}(1,:);
    Fs = AudioData.s.SampleRate;
	segments = CARL_auto_detect_on_offset(Audio, Fs, trial, segments, 2.5);
end; clear trial;

% create GUI and transcribe words manually                                

ind = []; % empty cell -> start at last empty trial
Fs = AudioData.s.SampleRate;
info.ID = '0';
CARL_GUI(segments, ind, Fs, pn, info.ID, 'Labeling');

% Stop here and label everything
% Output to save: segments, Fs

%% Alternative for continous recording: automatically split into separate word 'chunks' first

pn.audioFile = '/Users/kosciessa/OneDrive/Work/Dev/CARLrepos/examples/Counting-from-1-to-20.wav';

% pre-sequencing voice segments (iterate through single audio file)
% this file is very short, if there are very long recordings, they have to
% be chunked, here I use a chunk siye of 20s, with an assumed pause between
% words of 0.5s
[segments, Fs] = CARL_get_voice_segments(pn.audioFile, 20, .5);
% try to mark on- & offsets of the actual voice segments
for trial = 1:size(segments,2)
    Audio = segments{1,trial};
    if numel(Audio)/Fs < 4 % only label chunks shorter than x s (here 4s)
        segments = CARL_auto_detect_on_offset(Audio, Fs, trial, segments, 2.5);
    end
end; clear trial;

ind = []; % empty cell -> start at last empty trial
Fs = AudioData.s.SampleRate;
info.ID = '0';
CARL_GUI(segments, ind, Fs, pn, info.ID, 'Labeling');

