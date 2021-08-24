% This is an example script that segments audio data and
% can be used to transcribe verbal responses.

% CARL's detection mechanism and audio
% player are adapted from the following two sources:
% Ressource: http://class.ee.iastate.edu/mmina/EE186/labs/Audio.htm
% Ressource: http://www.mathworks.de/de/help/signal/ref/spectrogram.html

% There are two options here: 
%   (1) a continuous recording that first has to be segmented 
%   into potential words (with some post-hoc control)
%   (2) a structure, in which every recording corresponds to a
%   single word/response/trial.

%% add CARL ressources

pn.CARL_internal = '/Users/kosciessa/OneDrive/Work/Dev/CARLrepos/CARL/internal/';
addpath(pn.CARL_internal)

%% prespecified trial structure

% load audio data (as .wav or .mat file)

pn.dataIN = '/Users/kosciessa/OneDrive/Work/Dev/CARLrepos/examples/1105_StroopData_1.mat';
load(pn.dataIN)

AudioData = StroopAudio; clear StroopAudio;

% pre-sequence voice segments: try to mark on- & offsets of the voice segments                            
                                                                            
segments = cell(7,1);
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

%% only if continous recording: split into separate word chunks first

pn.audioFile = '/Users/kosciessa/OneDrive/Work/Dev/CARLrepos/examples/Cyborg-ignition-countdown.wav';

% pre-sequencing voice segments (iterate through single audio file)
[segments, Fs] = CARL_get_voice_segments(pn.audioFile, 20, .5);
% try to mark on- & offsets of the actual voice segments
for trial = 1:size(segments,2)
    Audio = segments{1,trial};
    if numel(Audio)/Fs < 4 % only label chunks shorter than 2s
        segments = CARL_auto_detect_on_offset(Audio, Fs, trial, segments, 2.5);
    end
end; clear trial;

ind = []; % empty cell -> start at last empty trial
Fs = AudioData.s.SampleRate;
info.ID = '0';
CARL_GUI(segments, ind, Fs, pn, info.ID, 'Labeling');

