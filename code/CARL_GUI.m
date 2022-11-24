classdef CARL_GUI < handle

    % This class and the accompanying functions show the extracted words
    % and play the associated audio. Segments can be refined by selecting
    % areas in the plot. Previously selected areas will be shown in light
    % grey. 
    
    % In addition to the functionality of CARL_Labeling, this GUI also
    % allows the comparison between the originally presented word and the
    % transcript as well as the online coding. The accuracy of the online
    % coding can be saved in the output structure. NOTE: This GUI requires
    % a structure where trials and segments have been matched!
    
    % The input is as follows: 
    % 1. segments (voice data resulting from previous analysis)
    % 2. ind (i.e., trial number; if none is given, the last trial ...
    %       without an entered word is selected and presented)
    % 3. Fs (frequency as determined by the previous analysis)
    % 4. pdat (i.e., path directory)
    
    % The output structure looks as follows:
    % 1. amplitude
    % 2. sample points (continuous)
    % 3. length of audio segment (in s)
    % 4. word (as entered by user)
    % 5. user selected points (referencing the sample points in 2.)
    % 6. amplitudes (user selected interval)
    % 7. sample points (continuous; user selected interval)
    
    % 2015 Julian Kosciessa
    
    properties (Access = private)
        FigureHandle                % Handle to main figure window
        AxesHandles                 % Handles to each axes. Each channel is in one axis
        Analyzer                    % Object which manages all analyzers
        Fs                          % Sample time
        SelectorPatchHandle         % Highlighting the area which is selected
    end
    
    properties (SetAccess = public, GetAccess = public)
        ChannelHandles
        SelectorLines               % The lines used to select audio data in the editor
        AudioData                   % Audio data being edited
        heditbox
        hback
        hadvance
        hplay
        hstop
        autostart
        autow
        autoslash
        selectclip
        seclast
        inputname
        seperate
        shiftleft
        shiftright
        origWord
        audWord
        origRESP
        COR_Button
        FALSE_Button
        QUEST_Button
        infotext
        version
        ID
    end
    
    methods
        function this = CARL_GUI(varargin)                           % IMPORTANT: This needs to be changed to the function name!
            global ind pdat
            this.AudioData  = varargin{1};
            if isempty(varargin{2})
                if size(this.AudioData(:,1),1) > 3
                    ind = find(cellfun(@isempty,this.AudioData(4,:)), 1, 'first');
                else ind = 1;
                end;
            else ind        = varargin{2};
            end;
            this.Fs         = varargin{3};
            pdat            = varargin{4};
            this.ID         = varargin{5};
            this.version    = varargin{6};  % Which GUI? (Labeling/Checking)
            this.inputname  = inputname(1); % Inputname that is assigned to the workspace.
            createFigure(this);
        end
    end

    methods (Access = 'private')

        function [hObject, this] = createFigure(this)
            
            % This function is called first and initiates the figure.
            
            global ind player
            
            % determine the positions of the elements
            if strcmp(this.version, 'Labeling')
                pos.figure      = [160,150,1100,500];
                pos.axes        = [50,150,1000,300];
                pos.selectclip  = [50,75,100,30];
                pos.seperate    = [200,75,100,30];
                pos.hback       = [350,65,100,40];
                pos.hadvance    = [500,65,100,40];
                pos.hplay       = [650,50,100,55];
                pos.hstop       = [650,30,100,20];
                pos.heditbox    = [800,40,100,55];
                pos.shiftleft   = [350,30,100,30];
                pos.shiftright  = [500,30,100,30];
                pos.autostart   = [950,15,150,50];
                pos.autow       = [950,85,150,50];
                pos.autoslash   = [950,50,150,50];
                pos.seclast     = [10,0,300,50];
            elseif strcmp(this.version, 'Checking')
                pos.figure      = [0,0,1100,600];
                pos.axes        = [50,250,1000,300];
                pos.selectclip  = [50,175,100,30];
                pos.seperate    = [200,175,100,30];
                pos.hback       = [350,165,100,40];
                pos.hadvance    = [500,165,100,40];
                pos.hplay       = [650,150,100,55];
                pos.hstop       = [650,130,100,20];
                pos.heditbox    = [800,140,100,55];
                pos.shiftleft   = [350,130,100,30];
                pos.shiftright  = [500,130,100,30];
                pos.autostart   = [950,115,150,50];
                pos.autow       = [950,185,150,50];
                pos.autoslash   = [950,150,150,50];
                pos.seclast     = [10,100,300,50];
                pos.origWord    = [50,40,150,50];
                pos.audWord     = [200,40,150,50];
                pos.origRESP    = [350,40,200,50];
                pos.COR_Button  = [600,60,100,40];
                pos.FALSE_Button = [700,60,100,40];
                pos.QUEST_Button = [800,60,100,40];
                pos.infotext    = [600,30,300,20];
            else error('Please check your input. Labeling /Checking only.')
            end;
            
            this.AxesHandles = [];
            this.ChannelHandles = [];
            this.SelectorLines = [];
            this.SelectorPatchHandle = [];
            this.FigureHandle = figure(...
                'Visible','on',...
                'Position',pos.figure, ...
                'Menubar','none', ...
                'Toolbar','figure', ...
                'IntegerHandle', 'off', ...
                'Color',    get(0, 'defaultuicontrolbackgroundcolor'), ...
                'NumberTitle', 'off', ...
                'Name', 'Audio Editor', ...
                'WindowButtonUpFcn', @(src, event) figureButtonUpCallback(this), ...
                'CloseRequestFcn', @(src, event) figureCloseCallback(this));
            hObject = this.FigureHandle;
            movegui(this.FigureHandle,'center')
            
            % open axes to later plot audio file in
            this.AxesHandles = axes('Units','pixels','Position', pos.axes, 'Box', 'on', ...
                          'ButtonDownFcn', @(src, event) axesButtonDownCallback(this));
            set(this.AxesHandles,'HitTest','off')

            % Create a plot in the axes.

            currentdata = this.AudioData{1,ind}(1:end);
            % linearly rescale audio signal to lie between -1 and 1
            currentdata_res = (1--1)/(max(currentdata)-min(currentdata))*(currentdata-max(currentdata))+1;
            this.ChannelHandles = plot(this.AxesHandles, currentdata_res(1:end), 'k');
            xlim([0 max(this.AudioData{2,ind}(1:end)-this.AudioData{2,ind}(1))])
            set(gca,'XTickLabel', '' );                                             % labels would be in sample points
            if size(this.AudioData(:,ind),1) > 4 && ~isempty(this.AudioData{5,ind})
                patch([min(this.AudioData{5,ind}) min(this.AudioData{5,ind}) ...
                    max(this.AudioData{5,ind}) max(this.AudioData{5,ind})], ...
                    [-1 1 1 -1],[0.75 0.75 0.75], 'FaceAlpha', 0.5, 'EdgeColor', [0.25 0.25 0.25])
            end;
            set(this.ChannelHandles, 'ButtonDownFcn', @(src, event) axesButtonDownCallback(this));
            set(this.AxesHandles, 'ButtonDownFcn', @(src, event) axesButtonDownCallback(this));
            addSelectorTool(this);
            title(this.AxesHandles, ['Audio Segment Nr. ', num2str(ind), ' / ', ...
                num2str(size(this.AudioData,2))]);
            
            secsincelast = timeSinceLastSeg(this);
            player = audioplayer(this.AudioData{1,ind}(1:end), this.Fs); % initiate player
            
            % get orig. word, transcript and online code
            if strcmp(this.version, 'Checking')
                originalWord = origWordSeg(this); originalWord = strrep(originalWord,'''', '');
                audioWord = audioWordSeg(this); audioWord = strrep(audioWord,'''', '');
                originalResponse = origRespSeg(this); originalResponse = strrep(originalResponse,'''', '');
            end;
            
            % Construct the GUI components.
            this.selectclip = ...
                uicontrol(hObject, 'Style','edit',...
                'String', 'Trial #','Position', pos.selectclip, ...
                'Interruptible', 'off', 'BusyAction', 'cancel',... % NOTE: This callback may not interrupt the GUI processing stream. Any attempt will be discarded.
                'Callback', @(src, event) editbox_Callback(this));
            this.seperate   = ...
                uicontrol(hObject, 'Style', 'toggle', ...
                'String', 'Separate', 'Position', pos.seperate);
            this.hback      = ...
                uicontrol(hObject, 'Style','pushbutton',...
                'String','Last Clip','Position',pos.hback, ...
                'Interruptible', 'off', 'BusyAction', 'queue',...
                'Callback', @(src, event) backbutton_Callback(this, src, event));
            this.hadvance   = ...
                uicontrol(hObject, 'Style','pushbutton',...
                'String','Next Clip','Position',pos.hadvance, ...
                'Interruptible', 'off', 'BusyAction', 'queue',...
                'Callback', @(src, event) advancebutton_Callback(this, src, event));
            this.hplay      =  ...
                uicontrol(hObject, 'Style','pushbutton',...
                'String','Play','Position',pos.hplay, ...
                'Callback', @(src, event) playbutton_Callback(this, src, event));
            this.hstop      =  ...
                uicontrol(hObject, 'Style','pushbutton',...
                'String','Stop','Position',pos.hstop, ...
                'Callback', @(src, event) stopbutton_Callback(this, src, event));
            this.heditbox   = ...
                uicontrol(hObject, 'Style','edit',...
                'String','Word','Position',pos.heditbox, ...
                'Interruptible', 'off', 'BusyAction', 'queue',...
                'Callback', @(src, event) editbox_Callback(this, src, event));
            
            % shift segment in time
            
            this.shiftleft = ...
                uicontrol(hObject, 'Style','pushbutton',...
                'String','Shift -','Position',pos.shiftleft, ...
                'Callback', @(src, event) shiftLeft_Callback(this, src, event));
            
            this.shiftright = ...
                uicontrol(hObject, 'Style','pushbutton',...
                'String','Shift +','Position',pos.shiftright, ...
                'Callback', @(src, event) shiftRight_Callback(this, src, event));

            % radio buttons
            
            this.autostart  = ...
                uicontrol(hObject, 'Style', 'radiobutton', ...
                'String', 'AutoStart', 'Position', pos.autostart);
            this.autow      = ...
                uicontrol(hObject, 'Style', 'radiobutton', ...
                'String', 'Auto: w', 'Position', pos.autow);
            this.autoslash  = ...
                uicontrol(hObject, 'Style', 'radiobutton', ...
                'String', 'Auto: /', 'Position', pos.autoslash);
            
            % time indicator
            
            this.seclast    =  ...
                uicontrol(hObject, 'Style', 'text', ...
                'String',['Time since the last detected segment: ', ...
                sprintf('%.2f',secsincelast),' s'],'Position',pos.seclast);
            
            if strcmp(this.version, 'Labeling')
                
                align([this.selectclip, this.hback, this.hadvance, this.hplay, ...
                    this.heditbox, this.AxesHandles, this.autostart, this.autow, ...
                    this.autoslash, this.seclast], 'HorizontalAlignment','VerticalAlignment');
            
                % Change units to normalized so components resize automatically.
                set([this.FigureHandle,this.hback, this.hadvance, this.hplay, ...
                    this.heditbox, this.AxesHandles, this.autostart, this.autow, ...
                    this.autoslash, this.selectclip, this.seclast], ...
                    'Units','normalized');
                
            elseif strcmp(this.version, 'Checking')
                
                % add original word, response and buttons for correctness

                this.origWord   = ...
                    uicontrol(hObject, 'Style', 'text', 'FontSize', 12, ...
                    'String', originalWord, 'Position', pos.origWord);

                this.audWord  = ...
                    uicontrol(hObject, 'Style', 'text', 'FontSize', 12, ...
                    'String', audioWord, 'Position', pos.audWord);

                this.origRESP   = ...
                    uicontrol(hObject, 'Style', 'text', 'FontSize', 12,...
                    'FontWeight', 'bold', 'String', originalResponse, ...
                    'Position', pos.origRESP);

                this.COR_Button   = ...
                    uicontrol(hObject, 'Style', 'toggle', ...
                    'String', 'Correct', 'Position', pos.COR_Button, ...
                    'Callback', @(src, event) COR_Callback(this, src, event));

                this.FALSE_Button   = ...
                    uicontrol(hObject, 'Style', 'toggle', ...
                    'String', 'False', 'Position', pos.FALSE_Button, ...
                    'Callback', @(src, event) FALSE_Callback(this, src, event));

                this.QUEST_Button   = ...
                    uicontrol(hObject, 'Style', 'toggle', ...
                    'String', '?', 'Position', pos.QUEST_Button, ...
                    'Callback', @(src, event) QUEST_Callback(this, src, event));

                this.infotext = ...
                    uicontrol(hObject, 'Style', 'text', 'FontSize', 9, ...
                    'String', 'Accuracy of initial coding', 'Position', pos.infotext);

                align([this.selectclip, this.hback, this.hadvance, this.hplay, ...
                    this.heditbox, this.AxesHandles, this.autostart, this.autow, ...
                    this.autoslash, this.seclast, this.origWord, this.audWord, this.COR_Button ...
                    this.FALSE_Button, this.QUEST_Button, this.infotext], ...
                    'HorizontalAlignment','VerticalAlignment');
                
                % Change units to normalized so components resize automatically.
                set([this.FigureHandle,this.hback, this.hadvance, this.hplay, ...
                    this.heditbox, this.AxesHandles, this.autostart, this.autow, ...
                    this.autoslash, this.selectclip, this.seclast, this.origWord,...
                    this.audWord, this.COR_Button, this.FALSE_Button, ...
                    this.QUEST_Button, this.infotext], 'Units','normalized');
                % set activity of coding buttons
                setupCodingButtons(this);
                % set the color of the online response
                onlineRespColor(this);
                
            end;
            
            % Assign the GUI a name to appear in the window title.
            set(this.FigureHandle,'Name','Computer-Assisted Response Labeler (CARL)')
            % Move the GUI to the center of the screen.
            movegui(this.FigureHandle,'center')
            % Make the GUI visible.
            set(this.FigureHandle,'Visible','on');
            % Make the editbox active.
            uicontrol(this.heditbox)
            if size(this.AudioData(:,ind),1) > 3
                if ~isempty(this.AudioData{4,ind})
                    set(this.heditbox, 'String', this.AudioData{4,ind});
                else 
                    set(this.heditbox, 'String', '');
                end;
            end;
            
        end
        
    end % Private methods

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Callback Function Section %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods (Access = 'public', Hidden = true) % Callback methods
        
        function shiftLeft_Callback(this, ~, ~)                       % shift segment by X timepoints to the left
            global ind pdat
            % get current trial onset and offset
            tmp.onset = min(this.AudioData{2,ind});
            tmp.offset = max(this.AudioData{2,ind});
            % shift onset to the left by X timepoints
            shift = this.Fs*0.1; % shift by 0.1 s
            tmp.newonset = tmp.onset - shift;
            % if new onset overlaps with onset of previous trial, merge
            % with previous trial (WIP: it has to be recognized if trials are merged)
            if ind ~= 1
                if max(this.AudioData{2,ind-1}) >= tmp.newonset
                    % update segments structure
                    tmp.prevonset = min(this.AudioData{2,ind-1});
                    [x,~] = audioread([pdat.audioFile], ...
                        [tmp.prevonset tmp.offset], 'double'); % reload data
                    this.AudioData{1,ind-1} = mean(x,2);
                    this.AudioData{2,ind-1} = [tmp.prevonset:tmp.offset]';
                    this.AudioData{4,ind-1} = [];       % erase previous coding if available
                    this.AudioData{5,ind-1} = this.AudioData{5,ind} + (tmp.onset-tmp.prevonset);
                    this.AudioData(:,ind)   = [];       % delete now obsolete trial
                    
                    % save new structure
                    assignin('base', this.inputname, this.AudioData)

                    % update presentation with 'new' trial
                    ind = ind-1;
                    updatePlot(this);
                else 
                    % update segments structure
                    [x,~] = audioread([pdat.audioFile], ...
                        [tmp.newonset tmp.offset], 'double'); % reload data
                    this.AudioData{1,ind} = mean(x,2);
                    this.AudioData{2,ind} = [tmp.newonset:tmp.offset]';
                    this.AudioData{5,ind} = this.AudioData{5,ind} + (tmp.onset-tmp.newonset);
                    % update plot
                    updatePlot(this);
                end;
            end;            
        end;
        
        function shiftRight_Callback(this, ~, ~)                            % shift segment by X timepoints to the right
            global ind pdat
            % get current trial onset and offset
            tmp.onset = min(this.AudioData{2,ind});
            tmp.offset = max(this.AudioData{2,ind});
            % shift onset to the left by X timepoints
            shift = this.Fs*0.1; % shift by 0.1 s
            tmp.newoffset = tmp.offset + shift;
            % if new offset overlaps with onset of next trial, merge
            % with previous trial (WIP: it has to be recognized if trials are merged)
            if ind ~= size(this.AudioData,2)
                if tmp.newoffset >= min(this.AudioData{2,ind+1})
                    % update segments structure
                    tmp.nextoffset = max(this.AudioData{2,ind+1});
                    [x,~] = audioread([pdat.audioFile], ...
                        [tmp.onset tmp.nextoffset], 'double'); % reload data
                    this.AudioData{1,ind+1} = mean(x,2);
                    this.AudioData{2,ind+1} = [tmp.onset:tmp.nextoffset]';
                    this.AudioData{4,ind+1} = [];       % erase previous coding if available
                    this.AudioData{5,ind+1} = this.AudioData{5,ind};
                    this.AudioData(:,ind)   = [];       % delete now obsolete trial
                    
                    % save new structure
                    assignin('base', this.inputname, this.AudioData)

                    % update presentation with 'new' trial [note that due to the prior deletion, the trialnumber stays the same]
                    updatePlot(this);
                else 
                    % update segments structure
                    [x,~] = audioread([pdat.audioFile], ...
                        [tmp.onset tmp.newoffset], 'double'); % reload data
                    this.AudioData{1,ind} = mean(x,2);
                    this.AudioData{2,ind} = [tmp.onset:tmp.newoffset]';
                    % update plot
                    updatePlot(this);
                end;
            end;            
        end;
        
        function advancebutton_Callback(this, ~, ~)
            global ind
            stopbutton_Callback(this);
            if isempty(this.AudioData{4,ind})
                this = saveCurrentData(this);
            end;
            if ind == size(this.AudioData,2)
                disp('Starting from the beginning!')
                ind = 1;
            else
                ind = ind + 1;
            end;
            updatePlot(this);
        end

        function backbutton_Callback(this, ~, ~)
            global ind 
            stopbutton_Callback(this);
            if isempty(this.AudioData{4,ind})
                this = saveCurrentData(this);
            end;
            if ind == 1
                disp('First trial reached!');
            else
                ind = ind - 1;
            end;
            updatePlot(this);
        end

        function this = editbox_Callback(this, ~, ~)
            global ind 
            key = get(gcf,'CurrentKey');
            if strcmp(key,'return')
                stopbutton_Callback(this);
                this = saveCurrentData(this);
                if ~isempty(get(this.selectclip, 'String')) && ...
                        strcmp(get(this.selectclip, 'String'), 'Trial #') == 0
                    ind = str2double(get(this.selectclip, 'String'));
                    set(this.selectclip, 'String', 'Trial #');
                else
                    if ind == size(this.AudioData,2)
                        disp('Starting from the beginning!')
                        ind = 1;
                    else
                        ind = ind + 1;
                    end;
                end;
                updatePlot(this);
            end;
        end

        function playbutton_Callback(this, ~, ~)
            global ind player lineobj
            
            if strcmp(this.version, 'Checking') || get(this.autostart, 'Value')==1 && ~isempty(this.AudioData{5,ind})
                % sound(this.AudioData{1,ind}(1:end), this.Fs);
                tmp.begin = min(this.AudioData{5,ind});
                tmp.end = max(this.AudioData{5,ind});
                 % linearly rescale audio signal to lie between -1 and 1
                currentAudio = this.AudioData{1,ind}(tmp.begin:tmp.end);
                currentAudio_res = (1--1)/(max(currentAudio)-min(currentAudio))*(currentAudio-max(currentAudio))+1;
                player = audioplayer(currentAudio_res, this.Fs);
                play(player)
                lineobj = line([tmp.begin,tmp.begin],[-1,1],'color','r', 'linewidth', 1);
                lineAtBegin = 0;
                end_time = length(this.AudioData{1,ind}(tmp.begin:tmp.end))/this.Fs;
            else
                currentAudio = this.AudioData{1,ind}(1:end);
                currentAudio_res = (1--1)/(max(currentAudio)-min(currentAudio))*(currentAudio-max(currentAudio))+1;
                player = audioplayer(currentAudio_res, this.Fs);
                play(player)
                lineobj = line([0,0],[-1,1],'color','r', 'linewidth', 1); 
                lineAtBegin = 1;
                end_time = length(this.AudioData{1,ind})/this.Fs;
            end;
            tic                                                             % start Matlab timer
            t=toc;                                                          % get the time since the timer started
            while t<end_time && ishandle(lineobj)
                if lineAtBegin ~= 1
                    set(lineobj, 'xdata', (tmp.begin)+t*[this.Fs,this.Fs])                  % move line to the time indicated by t
                else set(lineobj, 'xdata', t*[this.Fs,this.Fs])
                end;
                drawnow expose;                                             % update figure
                % MATLAB2015 use: drawnow limitrate
                t=toc;                                                      % get current time for the next update
            end
            if ishandle(lineobj)
                delete(lineobj);
            end;
            drawnow;
        end
        
        function COR_Callback(this, ~, ~)
            global ind;
            % enter response in segments_matched
            this.AudioData{12,ind} = 'CORRECT';
            % save new structure
            assignin('base', this.inputname, this.AudioData)
            % deactivate other buttons 
            % (see http://undocumentedmatlab.com/blog/undocumented-button-highlighting)
            set(this.COR_Button, 'Value', 1);
            set(this.FALSE_Button, 'Value', 0);
            set(this.QUEST_Button, 'Value', 0);
            % advance to next trial
%             ind = ind+1;
%             updatePlot(this);
        end;
        
        function FALSE_Callback(this, ~, ~)
            global ind;
            % enter response in segments_matched
            this.AudioData{12,ind} = 'FALSE';
            % save new structure
            assignin('base', this.inputname, this.AudioData)
            % deactivate other buttons
            set(this.COR_Button, 'Value', 0);
            set(this.FALSE_Button, 'Value', 1);
            set(this.QUEST_Button, 'Value', 0);
            % advance to next trial
%             ind = ind+1;
%             updatePlot(this);
        end;
        
        function QUEST_Callback(this, ~, ~)
            global ind;
            % enter response in segments_matched
            this.AudioData{12,ind} = '?';
            % save new structure
            assignin('base', this.inputname, this.AudioData)
            % deactivate other buttons
            set(this.COR_Button, 'Value', 0);
            set(this.FALSE_Button, 'Value', 0);
            set(this.QUEST_Button, 'Value', 1);
            % advance to next trial
%             ind = ind+1;
%             updatePlot(this);
        end;
        
        function figureButtonUpCallback(this)                               % Stop selection drag
          %if get(this.seperate,'Value') == 0
              set(this.FigureHandle, 'WindowButtonMotionFcn', '');
              [xd1, xd2] = getSelectionSampleNumbers(this);
              if get(this.autostart, 'Value')==1
                    playbutton_Callback(this);
              end;
    %           data = getCurrentData(this, xd1(1), xd2(1));
    %           this.Analyzer.analyze(data, this.Fs);
          %end;
        end

        function addSelectorTool(this)
             % Add the selector lines and the gray selection highlight area.
              cbFcn = @(hObject, eventdata) selectButtonDownCallback(this, hObject);
              for i=1:length(this.AxesHandles)
                axes(this.AxesHandles);
                this.SelectorLines(1, i) = line([0 0], [-1 1], ...
                                                'ButtonDownFcn', cbFcn, ...
                                                'Parent', this.AxesHandles);
                this.SelectorLines(2, i) = line([0 0], [-1 1], ...
                                                'ButtonDownFcn', cbFcn, ...
                                                'Parent', this.AxesHandles);
                this.SelectorPatchHandle(i) = patch([0 0 0 0], [-1 1 1 -1], ...
                                          [1 0.5 0], 'FaceAlpha', 0.5, ...
                                          'EdgeColor', [1 0 0], ...
                                          'HitTest', 'off', ...
                                          'Parent', this.AxesHandles);
              end
        end

        function [xd1, xd2] = getSelectionSampleNumbers(this)
            % Return the points where the selector lines are.
            % The first point is always smaller.
            global ind
            xd1 = get(this.SelectorLines(1), 'XData');
            xd2 = get(this.SelectorLines(2), 'XData');
            if xd1(1) > xd2(1)                                              % Render xd1 smaller than xd2
                temp = xd1;
                xd1 = xd2;
                xd2 = temp;
            end
            if size(this.AudioData(:,ind),1) > 4
                this.AudioData{5,ind} = [];
            end;
            tmp.line1 = round(xd1(1));
            tmp.line2 = round(xd2(1));
            this.AudioData{5,ind} = [tmp.line1, tmp.line2];
            if tmp.line1 == 0
                tmp.line1 = 1;
            end;
            if tmp.line2 == size(this.AudioData{2,ind},1)
                tmp.line2 = size(this.AudioData{2,ind},1)-1;
            end;
            % save all values for the word:
            this.AudioData{5,ind} = [tmp.line1, tmp.line2];
            assignin('base', this.inputname, this.AudioData)
        end

        function axesButtonDownCallback(this)
            % Position both selection lines at the mouse click point
            global ind
            maxxd = size(this.AudioData{1,ind}(1:end), 1);
            cp = get(this.AxesHandles(1), 'CurrentPoint');
            if cp(1) > maxxd || cp(1) < 0
                return;
            end
            if get(this.seperate,'Value') == 0   
                  if strcmp(get(this.FigureHandle,'SelectionType'),'normal')
                    % Move selector lines to this point
                    set(this.SelectorLines, 'XData', [cp(1) cp(1)]);
                    set(this.SelectorPatchHandle, 'XData', [cp(1) cp(1) cp(1) cp(1)]);
                    hLine = this.SelectorLines(1,:);
                    set(this.FigureHandle, 'WindowButtonMotionFcn', ...
                        @(hobj, eventdata) selectLineDragCallback(this, hLine));
                  elseif strcmp(get(this.FigureHandle,'SelectionType'),'alt') % right click
                    xd1 = get(this.SelectorLines(1), 'XData');
                    xd2 = get(this.SelectorLines(2), 'XData');
                    % Find closest line and move that to this point
                    if abs(xd1(1)-cp(1)) < abs(xd2(1)-cp(1))
                      set(this.SelectorLines(1,:), 'XData', [cp(1) cp(1)]);
                      set(this.SelectorPatchHandle, 'XData', [cp(1) cp(1) xd2(1) xd2(1)]);
                    else
                      set(this.SelectorLines(2,:), 'XData', [cp(1) cp(1)]);
                      set(this.SelectorPatchHandle, 'XData', [xd1(1) xd1(1) cp(1) cp(1)]);
                    end
                  end
            else 
                disp(cp(1));
                % show seperation line
                yaxislims = get(gca,'YLim');
                line([cp(1) cp(1)], [min(yaxislims) max(yaxislims)], 'Color', [0 0 0]);
                clear yaxislims;

                % insert empty vector for newly seperated data
                temp.new        = cell(size(this.AudioData,1),1);
                indices_next    = round(cp(1)):size(this.AudioData{1,ind},1);
                temp.new{1}     = (this.AudioData{1,ind}(indices_next));
                temp.new{2}     = (this.AudioData{2,ind}(indices_next));
                
                this.AudioData  = [this.AudioData(:,1:ind), temp.new, ...
                    this.AudioData(:,ind+1:end)];
                
                % clear data that has been moved to new trial
                this.AudioData{1,ind}(indices_next) = [];
                this.AudioData{2,ind}(indices_next) = [];
                for ind_loop = 3: size(this.AudioData,1)
                    this.AudioData{ind_loop,ind} = [];
                end;
                
                % check whether next segment is placeholder, if so, delete
                % it (the placeholder is created during preprocessing, so 
                % this step is only useful for the editing of the files)
                
                if isempty(this.AudioData{1, ind+2})
                    this.AudioData(:,ind+2) = [];
                end;
                
                % save new structure
                assignin('base', this.inputname, this.AudioData)
                
                % update Plot
                updatePlot(this);
            end;
        end  

        % Enable dragging of selection lines at the mouse click point
        function selectButtonDownCallback(this, hObject)
          %if strcmp(get(this.FigureHandle,'SelectionType'),'normal')
            [r, c] = find(this.SelectorLines == hObject);
            hLine = this.SelectorLines(1,:);
            set(this.FigureHandle, 'WindowButtonMotionFcn', ...
                @(hObject, eventdata) selectLineDragCallback(this, hLine));
          %end
        end

        % Drag selection lines
        function selectLineDragCallback(this, hLine)
            global ind
            %if strcmp(get(this.FigureHandle,'SelectionType'),'normal')
                maxxd = size(this.AudioData{1,ind}(1:end), 1);
                cp = get(this.AxesHandles(1), 'CurrentPoint');
                if cp(1,1) > maxxd
                  cp(1,1) = maxxd;
                elseif cp(1,1) < 0
                  cp(1,1) = 0;
                end
                set(hLine, 'XData', [cp(1,1) cp(1,1)]);
                xd = zeros(1, 4);
                xd(1:2) = get(this.SelectorLines(1), 'XData');
                xd(3:4) = get(this.SelectorLines(2), 'XData');
                set(this.SelectorPatchHandle, 'XData', xd);
            %end
        end

        end % hidden methods

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%% Open Function Section %%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    methods (Access = 'public', Hidden = false)
        
        function stopbutton_Callback (~, ~, ~)
            global player lineobj
            stop(player);
            if isobject(lineobj)
                delete(lineobj);
            end;
            drawnow;
        end;
        
        function setupCodingButtons(this)
            global ind;
            set(this.COR_Button, 'Value', 0);
            set(this.FALSE_Button, 'Value', 0);
            set(this.QUEST_Button, 'Value', 0);
            if size(this.AudioData,1) > 11
                if strcmp(this.AudioData{12,ind}, 'CORRECT')
                    set(this.COR_Button, 'Value', 1);
                elseif strcmp(this.AudioData{12,ind}, 'FALSE')
                    set(this.FALSE_Button, 'Value', 1);
                elseif strcmp(this.AudioData{12,ind}, '?')
                    set(this.QUEST_Button, 'Value', 1);
                end;
            end;
        end;
        
        function updatePlot(this)
            global ind
            this = fill_editbox(this); % update word in editbox
            drawnow;
            if ind == 1
                secsincelast = 0;
            else
                secsincelast = timeSinceLastSeg(this);
            end;
            java.lang.System.gc(); % forced garbage collection
            if strcmp(this.version, 'Checking')
                setupCodingButtons(this); % set up shading for accuracy buttons
                originalWord = origWordSeg(this); % get the original word
                originalWord = strrep(originalWord,'''', ''); 
                audioWord = audioWordSeg(this);  % get the transcript
                audioWord = strrep(audioWord,'''', '');
                originalResponse = origRespSeg(this); % get the online coding
                originalResponse = strrep(originalResponse,'''', '');
                set(this.origWord, 'String', originalWord);
                set(this.audWord, 'String', audioWord);
                set(this.origRESP, 'String', originalResponse);
                onlineRespColor(this); % change the color of the online coding
            end;
            set(this.seclast, 'String', ...
                ['Time since the last detected segment: ', ...
                sprintf('%.2f',secsincelast),' s'])
            currentAudio = this.AudioData{1,ind}(1:end); % update the audio segment
            % linearly rescale audio signal to lie between -1 and 1
            currentAudio_res = (1--1)/(max(currentAudio)-min(currentAudio))*(currentAudio-max(currentAudio))+1;
            this.ChannelHandles = plot(this.AxesHandles, currentAudio_res, 'k');
            xlim([0 max(this.AudioData{2,ind}(1:end)-this.AudioData{2,ind}(1))]);
            set(gca,'XTickLabel', '' ); % hide labels which would be in sample points
            set(this.ChannelHandles, 'ButtonDownFcn', ...
                @(src, event) axesButtonDownCallback(this));
            set(this.AxesHandles, 'ButtonDownFcn', ...
                @(src, event) axesButtonDownCallback(this));
            addSelectorTool(this);
            title(this.AxesHandles, ['Audio Segment Nr. ', num2str(ind), ' / ', ...
                num2str(size(this.AudioData,2))]);
            % if information about word boundaries exists, display it:
            if size(this.AudioData(:,ind),1) > 4 && ~isempty(this.AudioData{5,ind})
                patch([min(this.AudioData{5,ind}) min(this.AudioData{5,ind}) ...
                    max(this.AudioData{5,ind}) max(this.AudioData{5,ind})], ...
                    [-1 1 1 -1],[0.75 0.75 0.75], ...
                    'FaceAlpha', 0.5, 'EdgeColor', [0.25 0.25 0.25])
            end;
            if get(this.autostart, 'Value')==1
                playbutton_Callback(this);
            end;
        end
        
        function secsincelast = timeSinceLastSeg(this)
            global ind
            if ind > 1
                secsincelast = (min(this.AudioData{2,ind})- ...
                    max(this.AudioData{2,ind-1}))./this.Fs;
            else secsincelast = 0;
            end;
        end
        
        function originalWord = origWordSeg(this)
            global ind
            originalWord = this.AudioData{10,ind};
        end;
        
        function audioWord = audioWordSeg(this)
            global ind
            audioWord = this.AudioData{4,ind};
        end;
        
        function originalResponse = origRespSeg(this)
            global ind
            originalResponse = this.AudioData{11,ind};
        end;
        
        function onlineRespColor(this)
            global ind
            tmp.answer = this.AudioData{11,ind};
            tmp.answer = strrep(tmp.answer, '''', '');
            if strcmp(tmp.answer, 'm')
                set(this.origRESP, 'ForegroundColor', [0 0 0]);
            elseif strcmp(tmp.answer, 'x')
                set(this.origRESP, 'ForegroundColor', [80 200 50]./255);
            elseif strcmp(tmp.answer, 's')
                set(this.origRESP, 'ForegroundColor', [232 62 62]./255);
            end;
        end;
        
        function this = saveCurrentData(this)
            global ind
            temp.text = get(this.heditbox, 'String');
            if ~strcmp(temp.text, this.AudioData{4,ind})
                this.AudioData{4,ind} = get(this.heditbox, 'String');
                assignin('base', this.inputname, this.AudioData);
            end;
            % NOTE: As data is saved often, it is imperative that the
            % strings are updated before a new trial is started. Otherwise
            % data will be overwritten. Therefore, the crucial callback
            % functions have been set not to interrupt the processing
            % stream.
        end;
        
        function this = fill_editbox(this)
            global ind
            if size(this.AudioData(:,ind),1) > 3
                if ~isempty(this.AudioData{4,ind})
                    % get existing string
                    set(this.heditbox, 'String', this.AudioData{4,ind});
                else % enter values due to active pushbutton
                    if get(this.autow, 'Value') == 1
                        set(this.heditbox, 'String', 'w');
                    elseif get(this.autoslash, 'Value') == 1
                        set(this.heditbox, 'String', '/');
                    else
                        set(this.heditbox, 'String', '');
                    end;
                end;
            end;
            drawnow;
        end
        
        function delete(this)
            set(this.FigureHandle,  'closerequestfcn', '');                 % remove the closerequestfcn from the figure, this prevents an
                                                                            % infinite loop with the following delete command
            delete(this.FigureHandle);                                      % delete the figure
            this.FigureHandle = [];                                         % clear out the pointer to the figure - prevents memory leaks
        end
        
        function figureCloseCallback(this)
            delete(this);                                                   % close GUI
        end
    end

end