function progress_rel = jk_progresscheck (segments)

    temp.vec = [];
    for ind = 1: size(segments,2)
        temp.vec = [temp.vec isempty(segments{4,ind})];
    end;
    progress_rel = (1-(sum(temp.vec)./size(temp.vec,2)))*100;
    progress_abs = sum(temp.vec == 0);
    disp(['', sprintf('%0.2f', progress_rel),'% (', num2str(progress_abs),...
        ' Trials) have been labeled!']);
end