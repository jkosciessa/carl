function Limits = detection_new_14_12_03 (x, fs, t)

    % Window length and step (in seconds):
    win = 0.050;
    step = 0.050;

    %%%%%%%%%%%%%%%%%%%%%%%%%%%
    %  THRESHOLD ESTIMATION
    %%%%%%%%%%%%%%%%%%%%%%%%%%%

    Weight = 5; % used in the threshold estimation method

    % Compute short-time energy and spectral centroid of the signal:
    Eor = ShortTimeEnergy(x, win*fs, step*fs);
    Cor = SpectralCentroid(x, win*fs, step*fs, fs);

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
flags = Flags1; % & Flags2;

    if (t == 1) % plot results:
        clf;
        subplot(3,1,1); plot(Eor, 'g'); hold on; plot(E, 'c'); legend({'Short time energy (original)', 'Short time energy (filtered)'});
        L = line([0 length(E)],[T_E T_E]); set(L,'Color',[0 0 0]); set(L, 'LineWidth', 2);
        axis([0 length(Eor) min(Eor) max(Eor)]);

        subplot(3,1,2); plot(Cor, 'g'); hold on; plot(C, 'c'); legend({'Spectral Centroid (original)', 'Spectral Centroid (filtered)'});    
        L = line([0 length(C)],[T_C T_C]); set(L,'Color',[0 0 0]); set(L, 'LineWidth', 2);   
        axis([0 length(Cor) min(Cor) max(Cor)]);
    end


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

end