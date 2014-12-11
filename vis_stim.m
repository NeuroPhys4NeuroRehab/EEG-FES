function [stm, ctmrelax, ctmgo, ctmrest, rtm, list] = vis_stim(varargin)
    opts = arg_define(varargin, ...
        arg({'streamname','StreamName'},'Emotiv EPOC',[],'LSL stream that should be displayed.'), ...
        arg({'refreshrate','Refreshrate'},16,[],'Refresh rate for display.'), ...
        arg({'timerange','TimeRange'},120,[],'Time Range for a single observation'), ...
        arg({'stc','RelaxedTrialCount'},3,[],'No. of Relaxed Observations to be recorded'), ...
        arg({'ctc','ContinuousTrialCount'},5,[],'No. of Continuous Loops of Observations to be recorded'), ...
        arg({'rtc','RandomTrialCount'},10,[],'No. of Random Observations to be recorded'));
    if isempty(varargin)
        opts = arg_guidialog;    
        if isempty(opts)
            return; 
        end % -> user clicked cancel
    end
    ttc = opts.stc + 3*opts.ctc + opts.rtc;
    for i = 1 : opts.stc 
        savedata('relax', opts.refreshrate, opts.timerange, opts.streamname);
        stm(:,:,i) = read(data);
    end
    
    
%     for i = 1 : opts.ctc
%         ctmrelax(:,:,i) = savedata('relax', opts.refreshrate, opts.timerange, opts.streamname);
%         ctmgo(:,:,i) = savedata('go', opts.refreshrate, opts.timerange, opts.streamname);
%         ctmrest(:,:,i) = savedata('rest', opts.refreshrate, opts.timerange, opts.streamname);
%     end


%     for i = 1 : opts.rtc
%         a = ceil(3*rand(1));
%         if (a == 1) 
%             s = 'relax';
%         elseif (a == 2) 
%             s = 'go';
%         else 
%             s = 'rest';
%         end
%         rtm(:,:,i) = savedata(s, opts.refreshrate, opts.timerange, opts.streamname);
%         list(i) = s;
%     end
end
   
 