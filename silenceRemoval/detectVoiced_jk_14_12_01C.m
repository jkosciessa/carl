function [segments, Fs] = detectVoiced_jk_14_12_01C(x, Fs , temp ,segments)

y = abs(x);                                                                 % change to absolute data
y = diff(y);                                                                % calculate first derivative

sampling_factor = round(size(x,1)/100000);
alpha = 0.45;
a = ones(1, sampling_factor)/sampling_factor;
b = [1 alpha-1];
y = filter(a,b,y);                                                          % highpass filter
z = zeros(size(y));

criterion = trimmean(abs(y),0.5)+3*std(abs(y));                                                 % define threshold (mean + std)!

z(abs(y)>criterion) = 1;                                                    % mark datapoints that cross threshold
    
zy = find(z==1);

for ind = 2: size(zy,1)
    if diff([zy(ind-1) zy(ind)]) < Fs
        z(zy(ind-1):zy(ind)) = 1;
    end;
end;

% h = figure;
% plot(z*max(abs(y)));
% hold on; plot(abs(y), 'r');

selected            = zeros(size(z));
selected(z==1)      = 1;
diff_points         = diff(selected);
onsets              = find(diff_points == 1);
offsets             = find(diff_points == -1);

Limits(:, 1)        = onsets - 0.5*Fs;
Limits(:, 2)        = offsets + 0.5*Fs;

if ~isempty (Limits(Limits <= 0))
    Limits(Limits <= 0) = 1;
end;

if ~isempty (Limits(Limits > size(x,1)))
    Limits(Limits > size(x,1)) = size(x,1);
end;


%% post-process

% A. MERGE OVERLAPPING SEGMENTS:

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

% B. Get final segments:

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
