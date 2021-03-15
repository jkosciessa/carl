function segments = jk_autodetectonoffset(segments,ind)

    diff_seg = diff(segments{1,ind});
    absdiff_seg = abs(diff_seg);
    
    
%     % filter signal with debauchies2 filter
%     wname = 'db2'; lev = 8;
%     tree = wpdec(absdiff_seg,lev,wname);
%     det1 = wpcoef(tree,2014);
%     sigma = median(abs(det1))/0.6745;
%     alpha = 1.8;
%     thr = wpbmpen(tree,sigma,alpha);
%     keepapp = 1;
%     xd = wpdencmp(tree,'s','nobest',thr,keepapp); 
% 
%     plot(absdiff_seg)
%     hold on; plot(xd, 'r')
    
    a = 1;
    sampling_factor = round(size(segments{1,ind},1)/100);
    b = 1/(sampling_factor)*ones((sampling_factor),1);
    dataOut = filter(b,a,absdiff_seg);
    dataOut = downsample(dataOut, sampling_factor);
    % plot(dataOut)
    % plot(abs(diff(dataOut)))
%     threshold = mean(abs(diff(dataOut(2:round(2+(size(diff(dataOut),1)/10)))))+ ...
%         abs(diff(dataOut(round(end-(size(diff(dataOut),1)/10)):end)))) + ...
%         std(abs(diff(dataOut(2:round(2+(size(diff(dataOut),1)/10)))))+ ...
%         abs(diff(dataOut(round(end-(size(diff(dataOut),1)/10)):end))));
    threshold = 2*mean(abs(diff(dataOut(2:round(2+(size(diff(dataOut),1)/10)))))+ ...
        abs(diff(dataOut(round(end-(size(diff(dataOut),1)/10)):end))));
    % threshold = mean(abs(diff(dataOut)))-std(abs(diff(dataOut));
    select_points = abs(diff(dataOut)) > threshold;
    select_points_upsampled = upsample(select_points, sampling_factor);
    select_points_upsampled(1:10) = 0;

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
    
    % plot(absdiff_seg)
    % hold on;
    % plot(0.01*select_points_upsampled,'r')

    % %% plot absolute difference
    % 
    % plot(absdiff_seg)
    % hold on; line([min_absdiff min_absdiff], [0 max(absdiff_seg)], 'Color',[1 0 0]);
    % hold on; line([max_absdiff max_absdiff], [0 max(absdiff_seg)], 'Color',[1 0 0]);
    % 
    % %% plot original
    % 
    % plot(segments{1,ind})
    % hold on; line([min_absdiff min_absdiff], ...
    %     [-max(segments{1,ind}) max(segments{1,ind})], 'Color',[1 0 0]);
    % hold on; line([max_absdiff max_absdiff], ...
    %     [-max(segments{1,ind}) max(segments{1,ind})], 'Color',[1 0 0]);

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