function [segments, fs] = detectVoiced_jk_14_11_25B(x, fs , temp ,segments)

% 
% function [segments, fs] = detectVoiced(wavFileName)
% 
% Theodoros Giannakopoulos
% http://www.di.uoa.gr/~tyiannak
%
% (c) 2010
%
% This function implements a simple voice detector. The algorithm is
% described in more detail, in the readme.pdf file
%
% ARGUMENTS:
%  - wavFileName: the path of the wav file to be analyzed
% 
% RETURNS:
%  - segments: a cell array of M elements. M is the total number of
%  detected segments. Each element of the cell array is a vector of audio
%  samples of the respective segment. 
%  - fs: the sampling frequency of the audio signal
%
% EXECUTION EXAMPLE:
%
% [segments, fs] = detectVoiced('example.wav',1);
%


% Convert mono to stereo
if (size(x, 2)==2)
	x = mean(x')';
end

% Window length and step (in seconds):
win = 0.050;
step = 0.050;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  THRESHOLD ESTIMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%

Weight = 5; % used in the threshold estimation method

% Compute spectral centroid of the signal:

Cor = SpectralCentroid(x, win*fs, step*fs, fs);

% Apply median filtering in the feature sequences (twice), using 5 windows:
% (i.e., 250 mseconds)
C = medfilt1(Cor, 5); C = medfilt1(C, 5);

% Get the average values of the smoothed feature sequences:
Z_mean = mean(C);

% Find spectral centroid threshold:
[HistC, X_C] = hist(C, round(length(C) / 10));
[MaximaC, countMaximaC] = findMaxima(HistC, 3);
if (size(MaximaC,2)>=2)
    T_C = (Weight*X_C(MaximaC(1,1))+X_C(MaximaC(1,2))) / (Weight+1);
else
    T_C = Z_mean / 2;
end

% introduce another threshold

Eor = abs(x);
% plot(Eor)
% line([0 10000000],[mean(Eor)+std(Eor) mean(Eor)+std(Eor)], 'color','r')
Eor(Eor<=mean(Eor)+std(Eor)) = 0;

Eor = ShortTimeEnergy(Eor, win*fs, step*fs);

% Thresholding:
Flag1 = (C>=T_C);
Flag2 = Eor;
flags = Flag1 & Flag2;


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  SPEECH SEGMENTS DETECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
count = 1;
WIN = 5;
Limits = [];
while (count < length(flags)) % while there are windows to be processed:
	% initilize:
	curX = [];	
	countTemp = 1;
	% while flags=1:
	while ((flags(count)==1) && (count < length(flags)))
		if (countTemp==1) % if this is the first of the current speech segment:
			Limit1 = round((count-WIN)*step*fs)+1; % set start limit:
			if (Limit1<1)	Limit1 = 1; end        
		end	
		count = count + 1; 		% increase overall counter
		countTemp = countTemp + 1;	% increase counter of the CURRENT speech segment
	end

	if (countTemp>1) % if at least one segment has been found in the current loop:
		Limit2 = round((count+WIN)*step*fs);			% set end counter
		if (Limit2>length(x))
            Limit2 = length(x);
        end
        
        Limits(end+1, 1) = Limit1;
        Limits(end,   2) = Limit2;
    end
	count = count + 1; % increase overall counter
end

%%%%%%%%%%%%%%%%%%%%%%%
% POST - PROCESS      %
%%%%%%%%%%%%%%%%%%%%%%%

% A. MERGE OVERLAPPING SEGMENTS:
RUN = 1;
while (RUN==1)
    RUN = 0;
    for (i=1:size(Limits,1)-1) % for each segment
        if (Limits(i,2)>=Limits(i+1,1))
            RUN = 1;
            Limits(i,2) = Limits(i+1,2);
            Limits(i+1,:) = [];
            break;
        end
    end
end

% B. Get final segments:
%segments = {};
for i=1:size(Limits,1)
    if temp.locBeg+Limits(i,1) <= temp.previousEnd + 1
        segments{1, end} = [segments{1, end}; x(Limits(i,1):Limits(i,2))];                              % write recording 
        segments{2, end} = [segments{2, end}; (temp.locBeg+Limits(i,1):temp.locBeg+Limits(i,2)).'];     % write position in recording
        segments{3, end} = segments{3, end} + size(segments{2, end},1)./fs;                            % write length in seconds
    else
        segments{1, end+1} = x(Limits(i,1):Limits(i,2));                            % write recording 
        segments{2, end} = (temp.locBeg+Limits(i,1):temp.locBeg+Limits(i,2)).';     % write position in recording
        segments{3, end} = size(segments{2, end},1)./fs;                            % write length in seconds
    end;
end