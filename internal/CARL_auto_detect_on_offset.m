function segments = CARL_auto_detect_on_offset(speechSignal, Fs, ind, segments, tolerance)
    
% This function determines the on-and offset of a single speech sample as
% created by the main function. To determine the on- and offset, the
% short-time energy is used, downsampled and low-pass-filtered.
    
    % conduct Short-Time Energy calculation
    winLen = round(numel(speechSignal)/800)+1;                              % Specify hamming window
    winOverlap = round(numel(speechSignal)/800);
    wHamm = hamming(winLen);
    sigFramed = buffer(speechSignal, winLen, winOverlap, 'nodelay');        % Framing and windowing the signal without for loops.
    sigWindowed = diag(sparse(wHamm)) * sigFramed;
    energyST = sum(sigWindowed.^2,1);                                       % Short-Time Energy calculation
    absdiff_out = abs(diff(energyST));

    a = 1;
    sampling_factor = round(numel(speechSignal)/100);
    b = 1/(sampling_factor)*ones((sampling_factor),1);
    dataOut = filter(b,a,absdiff_out);
    dataOut = downsample(dataOut, sampling_factor);
    initialPoints = dataOut(1:round(2+(size(dataOut,2)/10)));
    finalPoints = dataOut(end-(size(dataOut,2)/10):end);
    select_points = dataOut > tolerance*median([initialPoints, finalPoints]);
    select_points_upsampled = upsample(select_points, sampling_factor);
    detected_points = find(select_points_upsampled);
    match_diff = diff(detected_points)>5*sampling_factor;
    if ~isempty(match_diff)
        if match_diff(end)
            match_diff(size(match_diff,2)) = 0;
            match_diff(size(match_diff,2)+1) = 1;
        end;
    end;
    select_points_upsampled(detected_points(match_diff)) = 0;

    % get minimum and maximum values
    
    min_absdiff = find(select_points_upsampled == 1, 1, 'first'); 
    if min_absdiff - 2*sampling_factor  > 0 
        min_absdiff = min_absdiff - sampling_factor;
    end;
    max_absdiff = find(select_points_upsampled == 1, 1, 'last');
    if max_absdiff + 2*sampling_factor < numel(speechSignal)
        max_absdiff = max_absdiff + 2*sampling_factor;
    end;

    %% save result in segments-structure
    
    segments{1,ind} = speechSignal';
    segments{2,ind} = segments{2,ind};
    if isempty(segments{2,ind})
        segments{2,ind} = [1:numel(speechSignal)]';
    end
    segments{3,ind} = numel(speechSignal)/Fs;
    segments{4,ind} = '';
    segments{5,ind} = [];
    segments{6,ind} = [];
    segments{7,ind} = [];
    if ~isempty(min_absdiff) && ~isempty(max_absdiff)
        xd1 = min_absdiff;
        xd2 = max_absdiff;
        % save only edges:
        segments{5,ind} = [xd1;xd2]';
        segments{6,ind} = [];
    end

end