function segments = jk_autodetectonoffset_14_11_05_old(segments,ind) 

speechSignal = segments{1,ind};
%     diff_seg = diff(speechSignal);
    
    % A hamming window is chosen
    winLen = round(size(segments{1,ind},1)/800)+1;
    winOverlap = round(size(segments{1,ind},1)/800);
    wHamm = hamming(winLen);

    % Framing and windowing the signal without for loops.
    sigFramed = buffer(speechSignal, winLen, winOverlap, 'nodelay');
    sigWindowed = diag(sparse(wHamm)) * sigFramed;

    % Short-Time Energy calculation
    energyST = sum(sigWindowed.^2,1);

%     % Time in seconds, for the graphs
%     t = [0:length(speechSignal)-1]/Fs;
% 
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
    sampling_factor = round(size(segments{1,ind},1)/100);
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
    if match_diff(end)
        match_diff(size(match_diff,2)) = 0;
        match_diff(size(match_diff,2)+1) = 1;
    end;
    select_points_upsampled(detected_points(match_diff)) = 0;
%     select_points_upsampled(detected_points([0 diff(detected_points)]> ...
%         5*sampling_factor)) = 0;
    
    min_absdiff = find(select_points_upsampled == 1, 1, 'first'); 
    if min_absdiff - 2*sampling_factor  > 0 
        min_absdiff = min_absdiff - sampling_factor;
    end;
    max_absdiff = find(select_points_upsampled == 1, 1, 'last');
    if max_absdiff + 2*sampling_factor < size(segments{1,ind},1)
        max_absdiff = max_absdiff + 2*sampling_factor;
    end;

    % sound(segments{1,ind}(min_absdiff:max_absdiff), Fs);
    
    % %% plot all detected points
    
%     plot(speechSignal)
%     plot(energyST)
%     hold on;
%     plot(0.1*select_points_upsampled,'r')


    %% save result in segments-structure

    segments{5,ind} = [];
    segments{6,ind} = [];
    segments{7,ind} = [];
    if ~isempty(min_absdiff) && ~isempty(max_absdiff)
        xd1 = min_absdiff;
        xd2 = max_absdiff;
        segments{5,ind} = (xd1:xd2)';
        segments{6,ind} = (segments{1,ind}(xd1:xd2));
        segments{7,ind} = (segments{2,ind}(xd1:xd2));
    end
    
end