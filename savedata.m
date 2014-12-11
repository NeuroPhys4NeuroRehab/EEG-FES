function savedata(s, refreshrate, timerange, streamname)
    if ~exist('arg_define','file')
        addpath(genpath(fileparts(mfilename('fullpath')))); end
    if ~exist('env_translatepath','file')
        lib = lsl_loadlib();
    else
        lib = lsl_loadlib(env_translatepath('dependencies:/liblsl-Matlab/bin'));
    end
    global B;
%    B(14,32,2);
    B = [];
    i = 1;
%     s = unique(find_streams);
    taken = evalin('base','whos(''lsl*'')');
    chunkname = genvarname(['lsl_' streamname '_chunk'],{taken.name});
    buffername = genvarname(['lsl_' streamname '_stream'],{taken.name});
    inlet = create_inlet();
    assignin('base', buffername, create_streambuffer(inlet.info()));
    j = timerange*refreshrate/4;
    th = timer('Period', 1.0/refreshrate,'ExecutionMode','fixedRate','TimerFcn',@(timerhandle, eventdata)on_timer,'StartDelay',0.1,'Tag',['lsl_' genvarname(streamname) '_timer']);

    screenid = max(Screen('Screens'));
    Screen('Preference', 'SkipSyncTests', 1);
    win = Screen('OpenWindow', screenid, 0);
    [w, h1] = Screen('WindowSize', win);
    Screen('TextFont',win, 'Times');
    Screen('TextSize',win, 50);
    
    Screen('DrawText', win, s, w/2.2, h1/3, [200, 200, 200, 200]);
    Screen('Flip', win);
    start(th);
    
    function B = on_timer	
        try
            if evalin('base',['exist(''' buffername ''',''var'')'])
                [chunkdata,timestamps] = inlet.pull_chunk();
                temp=2

                assignin('base',chunkname,chunkdata);
                evalin('base',['[' buffername '.smax,' buffername '.data(:,1+mod(' buffername '.smax:' buffername '.smax+size(' chunkname ',2)-1,' buffername '.pnts))] = deal(' buffername '.smax + size(' chunkname ',2),' chunkname ');']);
                stream = evalin('base',buffername);
                if i < j
                    if ~(isempty(chunkdata(1,:)))
                        B(:,:,i) = chunkdata;
                        i = i+1;
                    end
                else
                    assignin('base','data',B);
                    delete(th);
                    return;
                end
            else
                try 
                    disp(['Deleting timer ' get(th,'Tag') '.']);
                catch e
                    disp('Deleting timer.');
                end
                warning off MATLAB:timer:deleterunning
                delete(th);
            end
        catch e
            if isempty(findobj('Tag',['Fig' buffername]))
                disp('Figure was closed.');
            else
                disp('An error occurred during the stream viewer update: ');
                try
                    hlp_handleerror(e);
                catch
                    disp(e.message);
                end
            end
            warning off MATLAB:timer:deleterunning
            delete(th);
        end
    end
%     function names = find_streams
%         streams = lsl_resolve_all(lib,0.3);
%         names = cellfun(@(s)s.name(),streams ,'UniformOutput',false);
%         if isempty(names)
%             error('There is no stream visible on the network.'); end
%     end
    function inlet = create_inlet()
        result = {};
        disp(['Looking for a stream with name=' streamname ' ...']);
        while isempty(result)
            result = lsl_resolve_byprop(lib,'name',streamname); end
        disp('Opening an inlet...');
        inlet = lsl_inlet(result{1},[]);
    end
    function stream = create_streambuffer(info)
        stream.srate = info.nominal_srate();                                % sampling rate in Hz
        stream.chanlocs = struct('labels',derive_channel_labels(info));     % struct with per-channel meta-data
        stream.pnts = 32;                                                  % number of data points in the buffer
        stream.nbchan = info.channel_count();                               % number of channels in the buffer
        stream.trials = 1;                                                  % number of segments in the buffer (always 1)
        stream.data = zeros(stream.nbchan,stream.pnts,stream.trials);       % the circular buffer storage
        stream.smax = 0;                                                    % number of samples that have been written into the buffer so far (wrapping around)
    end
    function channels = derive_channel_labels(info)
        channels = {};
        ch = info.desc().child('channels').child('channel');
        while ~ch.empty()
            name = ch.child_value_n('label');
            if name
                channels{end+1} = name; end
            ch = ch.next_sibling_n('channel');
        end
        if length(channels) ~= info.channel_count()
            disp('The number of channels in the steam does not match the number of labeled channel records. Using numbered labels.');
            channels = cellfun(@(k)['Ch' num2str(k)],num2cell(1:info.channel_count(),1),'UniformOutput',false);
        end
    end
end