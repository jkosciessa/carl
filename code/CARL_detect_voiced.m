function [segments, Fs] = CARL_detect_voiced(x, Fs , temp ,segments,distance_s)

    y = abs(hilbert(x));
    sampling_factor = round(size(x,1)/Fs);
    alpha = 0.2;
    a = ones(1, sampling_factor)/sampling_factor;
    b = [1 alpha-1];
    y = filter(a,b,y);
    
    [b,a] = butter(6,0.01);
    y = filter(b,a,y);
    y = y.^2;

    z = zeros(size(y));
    criterion = trimmean(abs(y),0.1)+ 0.5*std(abs(y));                                                 % define threshold (mean + std)!

    z(abs(y)>criterion) = 1;                                                    % mark datapoints that cross threshold

    zy = find(z==1);

    for ind = 2: size(zy,1)
        if diff([zy(ind-1) zy(ind)]) < distance_s*Fs
            z(zy(ind-1):zy(ind)) = 1;
        end;
    end;

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

    Limits(:, 1)        = onsets - 0.5*distance_s*Fs;
    Limits(:, 2)        = offsets + 0.5*distance_s*Fs;

    if ~isempty (Limits(Limits <= 0))
        Limits(Limits <= 0) = 1;
    end;

    if ~isempty (Limits(Limits > size(x,1)))
        Limits(Limits > size(x,1)) = size(x,1);
    end;


%% post-process : merge overlapping segments

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

%% write final segments into structure

    for i=1:size(Limits,1)
        if temp.locBeg+Limits(i,1) <= temp.previousEnd + 1
            segments{1, end} = [segments{1, end}; x(Limits(i,1):Limits(i,2))]';                              % write recording 
            segments{2, end} = [segments{2, end}; (temp.locBeg+Limits(i,1):temp.locBeg+Limits(i,2))'];     % write position in recording
            segments{3, end} = segments{3, end} + size(segments{2, end},1)./Fs;                            % write length in seconds
        else
            segments{1, end+1} = x(Limits(i,1):Limits(i,2))';                            % write recording 
            segments{2, end} = (temp.locBeg+Limits(i,1):temp.locBeg+Limits(i,2))';     % write position in recording
            segments{3, end} = size(segments{2, end},1)./Fs;                            % write length in seconds
        end;
    end
