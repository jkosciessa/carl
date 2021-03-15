function [segments, Fs] = CARL_getVoiceSegments_150911(pdat, info)

    segments            = [];
    tmp.info            = audioinfo([pdat.dataCon, info.ID,'.wav']);
    tmp.size            = tmp.info.TotalSamples;
    Fs                  = tmp.info.SampleRate;
    chunkSegment        = Fs*20;                                            % specify chunk size
    tmp.loopAmount      = round(tmp.size/chunkSegment);
    tmp.previousEnd     = NaN;

    for ind = 0: tmp.loopAmount-1                                               % load audio file in chunks
        tmp.locBeg = ind*chunkSegment+1;
        if ind == tmp.loopAmount-1
            tmp.locEnd = tmp.size;
        else
            tmp.locEnd = ind*chunkSegment + chunkSegment;
        end;
        [x,Fs] = audioread([pdat.dataCon,info.ID,'.wav'], [tmp.locBeg tmp.locEnd]);      % load chunk
        [segments, Fs] = CARL_detectVoiced_141203(x, Fs, tmp, segments);
        clear x;
        tmp.previousEnd = max(segments{2,size(segments,2)});
    end;
    
end