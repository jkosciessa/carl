function [segments, Fs] = detectVoiced_jk_14_12_01(x, Fs , temp ,segments)

% 
% function [segments, Fs] = detectVoiced(wavFileName)
% 
% Theodoros Giannakopoulos (c) 2010
% http://www.di.uoa.gr/~tyiannak
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
%  - Fs: the sampling frequency of the audio signal
%
% EXECUTION EXAMPLE:
%
% [segments, Fs] = detectVoiced('example.wav',1);
%


% Convert mono to stereo
if (size(x, 2)==2)
	x = mean(x')';
end

% Window length and step (in seconds):
win = 0.05;
step = 0.05;

%%%%%%%%%%%%%%%%%%%%%%%%%%%
%  THRESHOLD ESTIMATION
%%%%%%%%%%%%%%%%%%%%%%%%%%%

Weight = 5; % used in the threshold estimation method

% Compute short-time energy and spectral centroid of the signal:
y = x;

%     a = 1;
%     sampling_factor = round(size(x,1)/100);
%     b = 1/(sampling_factor)*ones((sampling_factor),1);
%     dataOut = filter(b,a,y);
%     dataOut = downsample(dataOut, sampling_factor);

y(abs(x)>mean(abs(x))+5*std(abs(x))) = 0;
Eor = ShortTimeEnergy(y, win*Fs, step*Fs);
Cor = SpectralCentroid(y, win*Fs, step*Fs, Fs);

% Apply median filtering in the feature sequences (twice), using 5 windows:
% (i.e., 250 mseconds)
E = medfilt1(Eor, 5); E = medfilt1(E, 5);
C = medfilt1(Cor, 5); C = medfilt1(C, 5);

% Get the average values of the smoothed feature sequences:
E_mean = mean(E);
Z_mean = mean(C);

% Find energy threshold:
[HistE, X_E] = hist(E, round(length(E) / 10));  % histogram computation
[MaximaE, countMaximaE] = findMaxima(HistE, 3); % find the local maxima of the histogram
if (size(MaximaE,2)>=2) % if at least two local maxima have been found in the histogram:
    T_E = (Weight*X_E(MaximaE(1,1))+X_E(MaximaE(1,2))) / (Weight+1); % ... then compute the threshold as the weighted average between the two first histogram's local maxima.
else
    T_E = E_mean / 2;
end

% Find spectral centroid threshold:
[HistC, X_C] = hist(C, round(length(C) / 10));
[MaximaC, countMaximaC] = findMaxima(HistC, 3);
if (size(MaximaC,2)>=2)
    T_C = (Weight*X_C(MaximaC(1,1))+X_C(MaximaC(1,2))) / (Weight+1);
else
    T_C = Z_mean / 2;
end

% Thresholding:
Flags1 = (E>=T_E);
Flags2 = (C>=T_C);
flags = Flags1 & Flags2;

% plot results:

clf;
subplot(3,1,1); plot(Eor, 'g'); hold on; plot(E, 'c'); legend({'Short time energy (original)', 'Short time energy (filtered)'});
L = line([0 length(E)],[T_E T_E]); set(L,'Color',[0 0 0]); set(L, 'LineWidth', 2);
axis([0 length(Eor) min(Eor) max(Eor)]);

subplot(3,1,2); plot(Cor, 'g'); hold on; plot(C, 'c'); legend({'Spectral Centroid (original)', 'Spectral Centroid (filtered)'});    
L = line([0 length(C)],[T_C T_C]); set(L,'Color',[0 0 0]); set(L, 'LineWidth', 2);   
axis([0 length(Cor) min(Cor) max(Cor)]);


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
			Limit1 = round((count-WIN)*step*Fs)+1; % set start limit:
			if (Limit1<1)	Limit1 = 1; end        
		end	
		count = count + 1; 		% increase overall counter
		countTemp = countTemp + 1;	% increase counter of the CURRENT speech segment
	end

	if (countTemp>1) % if at least one segment has been found in the current loop:
		Limit2 = round((count+WIN)*step*Fs);			% set end counter
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
        segments{3, end} = segments{3, end} + size(segments{2, end},1)./Fs;                            % write length in seconds
    else
        segments{1, end+1} = x(Limits(i,1):Limits(i,2));                            % write recording 
        segments{2, end} = (temp.locBeg+Limits(i,1):temp.locBeg+Limits(i,2)).';     % write position in recording
        segments{3, end} = size(segments{2, end},1)./Fs;                            % write length in seconds
    end;
end