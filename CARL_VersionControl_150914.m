function [segments, info] = CARL_VersionControl_150914(segments, info, Fs)

    info.missingTimeWordonset = [];
    for wordTrial = 1:size(segments,2)
        if ~isempty(segments{7,wordTrial})
            segments{8,wordTrial} = segments{7,wordTrial}(1,1) ;
            if wordTrial > 1 && ~isempty(segments{7,wordTrial-1})
                segments{9,wordTrial} = (segments{7,wordTrial}(1,1) - ...
                   segments{7,wordTrial-1}(1,end))/Fs;
            end;
        else info.missingTimeWordonset = [info.missingTimeWordonset, wordTrial];
        end;
    end;

end