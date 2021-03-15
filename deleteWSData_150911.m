a = dir('Y:\MERLIN\D_Analysis\A_AudioLabeling\E_DataProcessed\');
a = {a.name};

emptyCells = cellfun(@isempty,strfind(a,'_ws_'));
list = {a{find(emptyCells == 0)}}';

for ind = 1:length(list)
    path = ['Y:\MERLIN\D_Analysis\A_AudioLabeling\E_DataProcessed\', ...
        list{ind,1}];
    delete(path);
end;