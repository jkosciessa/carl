function segments = CARL_auto_detect_on_offset(speechSignal,ind, segments)
    
% This function determines the on-and offset of a single speech sample as
% created by the main function. To determine the on- and offset, the
% short-time energy is used, downsampled and low-pass-filtered.

    %speechSignal = segments{1,ind};
    
    % conduct Short-Time Energy calculation
    winLen = round(numel(speechSignal)/800)+1;                          % specify hamming window
    winOverlap = round(numel(speechSignal)/800);
    wHamm = hamming(winLen);
    sigFramed = buffer(speechSignal, winLen, winOverlap, 'nodelay');        % Framing and windowing the signal without for loops.
    sigWindowed = diag(sparse(wHamm)) * sigFramed;
    energyST = sum(sigWindowed.^2,1);                                       % Short-Time Energy calculation

%     t = [0:length(speechSignal)-1]/Fs;                                      % Time in seconds, for the graphs
%     subplot(1,1,1);
%     plot(t, speechSignal);
%     xlims = get(gca,'Xlim');
%     hold on;
%     delay = (winLen - 1)/2;
%     plot(t(delay+1:end - delay), energyST, 'r');
%     xlim(xlims);
%     xlabel('Time (sec)');
%     legend({'Speech','Short-Time Energy'});
%     hold off;
    
    dataOut = energyST;
    absdiff_out = abs(diff(dataOut));

    a = 1;
    sampling_factor = round(numel(speechSignal)/100);
    b = 1/(sampling_factor)*ones((sampling_factor),1);
    dataOut = filter(b,a,absdiff_out);
    dataOut = downsample(dataOut, sampling_factor);
    threshold = 2*mean(dataOut(2:round(2+(size(dataOut,2)/10)))+ ...
        dataOut(round(end-(size(dataOut,2)/10)):end)) + ...
        std(dataOut(2:round(2+(size(dataOut,2)/10)))+ ...
        dataOut(round(end-(size(dataOut,2)/10)):end));
    select_points = dataOut > threshold;
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

    % sound(speechSignal(min_absdiff:max_absdiff), Fs);
    
    % %% plot all detected points
    
%     plot(speechSignal)
%     plot(energyST)
%     hold on;
%     plot(0.1*select_points_upsampled,'r')

    % %% plot absolute difference
    % 
    % plot(absdiff_seg)
    % hold on; line([min_absdiff min_absdiff], [0 max(absdiff_seg)], 'Color',[1 0 0]);
    % hold on; line([max_absdiff max_absdiff], [0 max(absdiff_seg)], 'Color',[1 0 0]);
    % 
    % %% plot original
%     
%     plot(speechSignal)
%     hold on; line([min_absdiff min_absdiff], ...
%         [-max(speechSignal) max(speechSignal)], 'Color',[1 0 0]);
%     hold on; line([max_absdiff max_absdiff], ...
%         [-max(speechSignal) max(speechSignal)], 'Color',[1 0 0]);

    %% save result in segments-structure

    segments{1,ind} = speechSignal';
    segments{2,ind} = 1:numel(speechSignal)';
    segments{3,ind} = numel(speechSignal)/44100;
    segments{4,ind} = '';
    segments{5,ind} = [];
    segments{6,ind} = [];
    segments{7,ind} = [];
    if ~isempty(min_absdiff) && ~isempty(max_absdiff)
        xd1 = min_absdiff;
        xd2 = max_absdiff;
        % save all intermediate values:
%         segments{5,ind} = (xd1:xd2)';
%         segments{6,ind} = (speechSignal(xd1:xd2));
%         segments{7,ind} = (segments{2,ind}(xd1:xd2));
        % save only edges:
        segments{5,ind} = [xd1;xd2]';
        segments{6,ind} = [];
%        segments{7,ind} = [segments{2,ind}(xd1);segments{2,ind}(xd2)];
    end

end