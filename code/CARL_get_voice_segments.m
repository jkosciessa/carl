function [segments, Fs] = CARL_get_voice_segments(filename, chunk_s, distance_s)

% filename: filename of the .wav file (incl. extension)
% chunk_s: duration of chunk in seconds
% distance_s: min. distance between chunks in seconds

    segments            = [];
    tmp.info            = audioinfo([filename]);
    tmp.size            = tmp.info.TotalSamples;
    Fs                  = tmp.info.SampleRate;
    chunkSegment        = Fs*chunk_s;                                       % specify chunk size
    tmp.loopAmount      = round(tmp.size/chunkSegment);
    tmp.previousEnd     = NaN;

    for ind = 0: tmp.loopAmount-1                                          	% load audio file in chunks
        tmp.locBeg = ind*chunkSegment+1;
        if ind == tmp.loopAmount-1
            tmp.locEnd = tmp.size;
        else
            tmp.locEnd = ind*chunkSegment + chunkSegment;
        end
        [x,Fs] = audioread([filename], [tmp.locBeg tmp.locEnd], 'double');            % load chunk
        x = mean(x,2);
        [segments, Fs] = CARL_detect_voiced(x, Fs, tmp, segments, distance_s);
        clear x;
        tmp.previousEnd = max(segments{2,size(segments,2)});
    end
    
end