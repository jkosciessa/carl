function segments = CARL_auto_detect_on_offset(speechSignal, Fs, ind, segments, threshold)

% This function determines the on-and offset of a single speech sample as
% created by the main function. To determine the on- and offset, the
% short-time energy is used, downsampled and low-pass-filtered.
    
    if nargin < 5, threshold = 1; end

    % conduct Short-Time Energy calculation
    
    win = 0.01;
    step = 0.01;
    windows_num = 5;

    Eor = ShortTimeEnergy(speechSignal', win*Fs, step*Fs);
    Cor = SpectralCentroid(speechSignal', win*Fs, step*Fs, Fs);

    % Apply median filtering in the feature sequences
    E = medfilt1(Eor, windows_num);
    C = medfilt1(Cor, windows_num);
    
    dataOut = C.*E;
    X_wintime = 1:win*Fs:numel(speechSignal); X_wintime = X_wintime(1:end-1);
    dataOut = interp1(X_wintime,dataOut,1:numel(speechSignal));
    % get minimum and maximum values
    idx_onset = find(dataOut > threshold*nanmean([dataOut]), 1, 'first'); 
    idx_offset = find(dataOut > threshold*nanmean([dataOut]), 1, 'last');

    %% save result in segments-structure
    
    segments{1,ind} = speechSignal';
    segments{2,ind} = segments{2,ind};
    if isempty(segments{2,ind})
        segments{2,ind} = [1:numel(speechSignal)]';
    end
    segments{3,ind} = numel(speechSignal)/Fs;
    segments{4,ind} = '';
    segments{5,ind} = [];
    if ~isempty(idx_onset) && ~isempty(idx_offset)
        xd1 = idx_onset;
        xd2 = idx_offset;
        % save only edges:
        segments{5,ind} = [xd1;xd2]';
    end

end