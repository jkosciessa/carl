function [segments, Fs] = CARL_detectVoiced_141203(x, Fs , temp ,segments)

y = abs(hilbert(x));
sampling_factor = round(size(x,1)/Fs);
alpha = 0.2;
a = ones(1, sampling_factor)/sampling_factor;
b = [1 alpha-1];
y = filter(a,b,y); %http://de.mathworks.com/help/matlab/data_analysis/filtering-data.html

[b,a] = butter(6,0.01);
% freqz(b,a)
y = filter(b,a,y);
y = y.^2;

% m = length(x);          % Window length
% n = pow2(nextpow2(m));  % Transform length
% y = fft(x,n);           % DFT
% f = (0:n-1)*(Fs/n);     % Frequency range
% power = y.*conj(y)/n;   % Power of the DFT
% plot(f,power)
% xlabel('Frequency (Hz)')
% ylabel('Power')
% title('{\bf Periodogram}')

% change to absolute data
%y = diff(y);                                                                % calculate first derivative

% repeat = 1;
factor = 1;

% while repeat == 1
    z = zeros(size(y));
    criterion = trimmean(abs(y),0.1)+ 0.5*std(abs(y));                                                 % define threshold (mean + std)!

    z(abs(y)>criterion) = 1;                                                    % mark datapoints that cross threshold

    zy = find(z==1);

    for ind = 2: size(zy,1)
        if diff([zy(ind-1) zy(ind)]) < factor*Fs
            z(zy(ind-1):zy(ind)) = 1;
        end;
    end;

%     h = figure;
%     plot(z*max(abs(y)));
%     hold on; plot(abs(y), 'r');

    selected            = zeros(size(z));
    selected(z==1)      = 1;
    diff_points         = diff(selected);
    onsets              = find(diff_points == 1);
    offsets             = find(diff_points == -1);

    if isempty(onsets)
        onsets(1) = 1;
    end;
    
    if isempty (offsets)
        offsets(1) = size(z,1);
    end;
    
    if onsets(end) > offsets(end)
        offsets(end+1,:) = size(z,1);
    end;
    
%     if max(offsets-onsets)>0.6*size(z,1)
% %          temp.lims = detection_new_14_12_03 (x, Fs,0);
% %          clear onsets offsets;
% %          onsets = temp.lims(:,1);
% %          offsets = temp.lims(:,2);
%          repeat = 0;
% %          if factor > 0.5
% %             factor = factor -0.1;
% %          else repeat = 0;
% %          end;
%     else repeat = 0;
%     end;
% 
% end;

Limits(:, 1)        = onsets - 0.25*Fs;
Limits(:, 2)        = offsets + 0.25*Fs;

if ~isempty (Limits(Limits <= 0))
    Limits(Limits <= 0) = 1;
end;

if ~isempty (Limits(Limits > size(x,1)))
    Limits(Limits > size(x,1)) = size(x,1);
end;


%% post-process
%% merge overlapping segments

RUN = 1;
while (RUN==1)
    RUN = 0;
    for i=1:(size(Limits,1)-1)                                              % for each segment
        if (Limits(i,2)>=Limits(i+1,1))
            RUN = 1;
            Limits(i,2) = Limits(i+1,2);
            Limits(i+1,:) = [];
            break;
        end
    end
end

%% plot results

% h = figure;
% v = zeros(size(y));
% v(Limits) = 1;
% plot(v*max(abs(y)));
% hold on; plot(abs(y), 'r');

%% write final segments into structure

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
