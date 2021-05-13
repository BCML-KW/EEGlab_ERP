clc
clear all
addpath('D:\2021바디프랜드\eeglab_current\eeglab2020_0')
addpath('D:\2021바디프랜드\eeglab_current\eeglab2020_0\plugins\ERPLAB8.10\functions')
addpath('D:\2021바디프랜드\eeglab_current\eeglab2020_0\plugins\ERPLAB8.10\pop_functions')
addpath('D:\2021바디프랜드\eeglab_current\eeglab2020_0\plugins\ERPLAB8.10\GUIs')
addpath('D:\2021바디프랜드\eeglab_current\eeglab2020_0\plugins\ERPLAB8.10\images')
savepath = 'D:\2021바디프랜드\data\0_Real_experiment\1_EEG\ERP\';

X=dir(['D:\2021바디프랜드\1_data\0_Real_experiment\1_EEG\*.mat']);
EVENTLIST_path = 'F:\2021바디프랜드\';
ALLERP=[];
do_Task = 'Stroop';
do_Session = '5';
do_sub = '201';
        eeglab nogui;

for i = 1:size(X,1)
    PATH = [X(i).folder '\'];
    name = X(i).name;
    load([PATH name]);
    Sub = name(end-8:end-6);
    Session = name(end-4);
    Task = name(1:end-10);
    if all([Task(1:2)] == [do_Task(1:2)]) && Session == do_Session %&& all(Sub==do_sub)
        BDF = ['D:\2021바디프랜드\1_data\0_Real_experiment\Binlister_' Task '.txt'];
        eeg = Y';
        eog = eeg(end-2,:)-eeg(end-1,:);
        eeg(end-2,:) = eog;
        eeg(end-1,:)=[];       
%         heog = eeg(end-2);
%         veog = eeg(end-1);

        % start
        % [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;

        
        % import
        EEG = pop_importdata('setname', [name(1:12)], 'data', 'eeg' ,  'dataformat', ['array'], 'nbchan', [16] ,'srate', [512] );
        % set 17th channel as event
        EEG = pop_chanevent( EEG, 16, 'edge', ['leading']);
        %% arrange channel location
%             chanlocs = struct('labels', { 'Fp1' 'Fp2' 'F3' 'Fz' 'F4' 'FC5' 'FC1' 'FC2' 'FC6' 'T7' 'C3' 'Cz' 'C4' 'T8'});
%             pop_chanedit( chanlocs );
%         EEG = pop_editset( EEG, 'chanlocs', ['D:\2021바디프랜드\1_data\0_Real_experiment\Chanlocs_0408.ced']);
EEG = pop_editset( EEG, 'chanlocs', ['D:\2021바디프랜드\w_o_EOG.ced']);
        EEG = eeg_checkset( EEG );
        %% Preprocessing
        % CAR
%         EEG = pop_reref(EEG,[], 'exclude', [15]);   EEG = eeg_checkset( EEG );
EEG = pop_reref(EEG,[]);   EEG = eeg_checkset( EEG );
        % Bandpass filter [0.5 30]
        EEG = pop_eegfiltnew(EEG, 'locutoff', 1, 'hicutoff', 25, 'plotfreqz',0); EEG = eeg_checkset( EEG );
        %EEG = pop_eegfiltnew(EEG,0.5,25,[],0,[],0); EEG = eeg_checkset( EEG );
        % Downsampling (512Hz)
        % EEG = pop_resample(EEG,512);    EEG = eeg_checkset( EEG );
        % ICA
        EEG = pop_autobsseog( EEG, [], [], 'sobi', {'eigratio', [1000000]}, 'eog_fd', {'range',[]}); EEG = eeg_checkset( EEG );

%         EEG = pop_autobsseog(EEG,[288], [288] ,'sobi',{'eigratio',[1000000]},'eog_fd',{'range',[2 8]});
%         EEG = pop_autobssemg( EEG, [11.52], [11.52], 'sobi', {'eigratio', [1000000]}, 'emg_psd', {'ratio', [10],'fs', [1000],'femg', [15],'estimator',spectrum.welch({'Hamming'}, 500),'range', [0  12]});
        %% Epoching & baseline correction
%         EEG = pop_epoch( EEG, {  '1'  '2'  }, [-0.2 0.8],  'newname', 'BDF file resampled epochs', 'epochinfo', 'yes', 'valuelim', [-75 75]);
        
        EEG = pop_rmbase( EEG, [EEG.times(1) 0] ,[]);
        EEG = eeg_checkset( EEG );
        
        %% linear detrend
%         for i = 1:EEG.trials
%             EEG.data(:,:,i) = detrend(EEG.data(:,:,i)')';
%         end
%         EEG = pop_rmbase( EEG, [EEG.times(1) 0] ,[]);
        EEG = eeg_checkset( EEG );
        %% Bin EventList & Save ERP
        % create event list
        [EEG EVENTLIST] = creaeventlist(EEG);
        % BINLISTER
        [EEG EEG.EVENTLIST binOfBins isparsenum]  = binlister(EEG, BDF, {'no'}, {'no'}, [], [], 1);
        
        %% extract bin-based epochs
        EEG = pop_epochbin(EEG, [-300 600], 'pre'); % Epoch 이벤트 다 담지 못함. => 수정 필요

        %% Artifact detection in epoched data - Moving window peak to peak threshold
         EEG  = pop_artmwppth( EEG , 'Channel',  1:14, 'Flag',  1, 'Threshold', 500, 'Twindow', [ -298 598], 'Windowsize', 200, 'Windowstep',  100 );
        %    [EEG EVENTLIST] = creaeventlist(EEG);
        
        %     % Reject incorrect epochs
        %     reject_epoch = zeros(1,size(EEG.epoch,2 ));
        %     for j=1:size(EEG.EVENTLIST.eventinfo,2)-2
        %         code = {EEG.EVENTLIST.eventinfo.code};
        %         epoch= {EEG.EVENTLIST.eventinfo.bepoch};
        %         if (cell2mat(code(j))==1 && cell2mat(code(j+2))==5)||(cell2mat(code(j))==2 && cell2mat(code(j+2))==5)
        %             jj = cell2mat(epoch(j));
        %             if jj==0; break;   end;
        %             reject_epoch(jj)=1;
        %         end
        %     end
        
        %   EEG = pop_rejepoch( EEG, reject_epoch ,0);
        
        %% Compute average
        ERP = pop_averager( EEG , 'Compute', 'ERP', 'Criterion', 'good', 'ExcludeBoundary', 'on', 'SEM', 'on');
        
        % save ERP
        %pop_savemyerp( ERP, 'erpname', FILE(1:end-4), 'filename', [FILE(1:end-4) '_erp.erp'], 'filepath', PATH, 'gui', 'none', 'overwriteatmenu', 'on', 'Warning', 'on');
        
        %% plot ERP waveform
        gcf = pop_ploterps(ERP, [1:(ERP.nbin)], [1:(ERP.nchan)] );
        %     saveas(gcf ,[X(i).folder(end-8:end) '_' FILE(1:end-4) '_erp.png'])
        ALLERP = [ALLERP ERP];
        G_ERP = pop_gaverager( ALLERP , 'Erpsets',1:size(ALLERP,2), 'Criterion',100, 'SEM',...
            'on', 'Warning', 'on', 'Weighted', 'on' );
    end
end
%close all;
g_gc = pop_ploterps(G_ERP, [1:(G_ERP.nbin)], [1:(G_ERP.nchan)] );
% saveas(g_gc,[ 'F:\2021바디프랜드\data\210308\GRD_' FILE(1:end-4) '_erp.png'])


% %% Raw data >> EOG Removal(BSS Auto Removal) 
% 
% [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
% EEG = pop_loadbv('E:\2021_E-prime_ERP\CHR\', 'Vis1.vhdr', [], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 
% EEG = pop_loadbv('E:\2021_E-prime_ERP\CHR\', 'Vis2.vhdr', [], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
% EEG = pop_loadbv('E:\2021_E-prime_ERP\CHR\', 'Vis3.vhdr', [], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 
% EEG = pop_loadbv('E:\2021_E-prime_ERP\CHR\', 'Vis4.vhdr', [], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'gui','off'); 
% EEG = pop_loadbv('E:\2021_E-prime_ERP\CHR\', 'Vis5.vhdr', [], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'gui','off'); 
% EEG = eeg_checkset( EEG );
% EEG = pop_mergeset( ALLEEG, [1  2  3  4  5], 0);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'gui','off'); 
% EEG=pop_chanedit(EEG, 'lookup','C:\\Users\\IHAN\\Desktop\\sad\\eeglab14_1_2b\\plugins\\dipfit2.3\\standard_BESA\\standard-10-5-cap385.elp');
% [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
% % bandpass filtering [1~30Hz]
% EEG = pop_eegfiltnew(EEG, 1,30,3300,0,[],0); 
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 6,'gui','off'); 
% EEG = eeg_checkset( EEG );
% % Common Average Reference
% EEG = pop_reref( EEG, []);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 7,'gui','off'); 
% EEG = eeg_checkset( EEG );
% % Auto Artifact Removal Using BSS(blind source separation) SOBI algorithm
% EEG = pop_autobsseog( EEG, [288], [288], 'sobi', {'eigratio', [1000000]}, 'eog_fd', {'range',[2  8]});
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 8,'gui','off'); 
% % epoching 
% EEG = pop_epoch( EEG, {  'S  1'  }, [-0.3           1], 'newname', 'Merged datasets epochs', 'epochinfo', 'yes');
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 9,'gui','off'); 
% EEG = eeg_checkset( EEG );
% % baseline correction 
% EEG = pop_rmbase( EEG, [-300    0]);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 10,'gui','off'); 
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 11,'retrieve',9,'study',0); 
% EEG = eeg_checkset( EEG );
% 
% %% Raw data >> EMG Removal(BSS Auto Removal) 
% 
% [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
% EEG = pop_loadbv('E:\2021_E-prime_ERP\YDJ\', 'Vis1.vhdr', [], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 0,'gui','off'); 
% EEG = pop_loadbv('E:\2021_E-prime_ERP\YDJ\', 'Vis2.vhdr', [], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 1,'gui','off'); 
% EEG = pop_loadbv('E:\2021_E-prime_ERP\YDJ\', 'Vis3.vhdr', [], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 2,'gui','off'); 
% EEG = pop_loadbv('E:\2021_E-prime_ERP\YDJ\', 'Vis4.vhdr', [], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 3,'gui','off'); 
% EEG = pop_loadbv('E:\2021_E-prime_ERP\YDJ\', 'Vis5.vhdr', [], [1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24]);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 4,'gui','off'); 
% EEG = eeg_checkset( EEG );
% EEG = pop_mergeset( ALLEEG, [1  2  3  4  5], 0);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 5,'gui','off');  
% EEG=pop_chanedit(EEG, 'lookup','C:\\Users\\IHAN\\Desktop\\sad\\eeglab14_1_2b\\plugins\\dipfit2.3\\standard_BESA\\standard-10-5-cap385.elp');
% [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
% EEG = pop_eegfiltnew(EEG, 1,30,3300,0,[],0); %filtering--------------------
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 6,'gui','off'); 
% EEG = eeg_checkset( EEG );
% EEG = pop_reref( EEG, []);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 7,'gui','off'); 
% EEG = eeg_checkset( EEG );
% EEG = pop_autobssemg( EEG, [11.52], [11.52], 'sobi', {'eigratio', [1000000]}, 'emg_psd', {'ratio', [10],'fs', [1000],'femg', [15],'estimator',spectrum.welch({'Hamming'}, 500),'range', [0  12]});
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 8,'gui','off'); 
% EEG = pop_epoch( EEG, {  'S  1'  }, [-0.3           1], 'newname', 'Merged datasets epochs', 'epochinfo', 'yes');
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 9,'gui','off'); 
% EEG = eeg_checkset( EEG );
% EEG = pop_rmbase( EEG, [-300    0]);
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 10,'gui','off'); 
% [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 11,'retrieve',9,'study',0); 
% EEG = eeg_checkset( EEG );
% 
 %% Raw data >> EOG Removal(BSS Auto Removal) >> EMG Removal(BSS Auto Removal)
 clc
    clear
    % start
    % [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    [ALLEEG EEG CURRENTSET ALLCOM] = eeglab;
    savepath = 'D:\2021바디프랜드\data\210323_stroop\adjusted_data\';
X=dir(['D:\2021바디프랜드\data\210323_stroop\20*.mat']);

    for i = [1 4 5]
        EEG=[];
        PATH = [X(i).folder '\'];
        name = X(i).name;
        load([PATH name]);
        eeg = Y';
        
        % import
        EEG = pop_importdata('setname', [name(1:11)], 'data', 'eeg' ,  'dataformat', ['array'], 'nbchan', [17] ,'srate', [1200] );
        % set 17th channel as event
        EEG = pop_chanevent( EEG, 17, 'edge', ['leading']);
        %% arrange channel location
        %     chanlocs = struct('labels', { 'Fp1' 'Fp2' 'F7' 'F3' 'Fz' 'F4' 'F8' 'FC5' 'FC1' 'FC2' 'FC6' 'T7' 'C3' 'Cz' 'C4' 'T8' });
        %     pop_chanedit( chanlocs );
        EEG = pop_editset( EEG, 'chanlocs', ['D:\2021바디프랜드\0324_loc.ced']);
        EEG = eeg_checkset( EEG );
        
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, i,'gui','off');
        EEG = eeg_checkset( EEG );
        
        %EEG = pop_mergeset( ALLEEG, 1:size(X,1), 0);
        
        [ALLEEG EEG] = eeg_store(ALLEEG, EEG, CURRENTSET);
        EEG = pop_eegfiltnew(EEG, 1,30,3300,0,[],0); %filtering--------------------
        EEG = pop_resample(EEG,512);    EEG = eeg_checkset( EEG );
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 6,'gui','off');
        EEG = eeg_checkset( EEG );
        EEG = pop_reref( EEG, []);
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 7,'gui','off');
        EEG = eeg_checkset( EEG );
        EEG = pop_autobsseog( EEG, [288], [288], 'sobi', {'eigratio', [1000000]}, 'eog_fd', {'range',[2  8]});
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 8,'gui','off');
        EEG = pop_autobssemg( EEG, [11.52], [11.52], 'sobi', {'eigratio', [1000000]}, 'emg_psd', {'ratio', [10],'fs', [1000],'femg', [15],'estimator',spectrum.welch({'Hamming'}, 500),'range', [0  12]});
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 9,'gui','off');
            [EEG EVENTLIST] = creaeventlist(EEG);
  %     % Reject incorrect epochs
     reject_epoch = zeros(1,size(EEG.epoch,2 ));
     for j=1:size(EVENTLIST.eventinfo,2)-2
         code = {EVENTLIST.eventinfo.code};
         epoch= {EVENTLIST.eventinfo.bepoch};
         if (cell2mat(code(j))==1 && cell2mat(code(j+2))==5)||(cell2mat(code(j))==2 && cell2mat(code(j+2))==5)
             jj = cell2mat(epoch(j));
             if jj==0; break;   end;
             reject_epoch(jj)=1;
         end
     end
    
    EEG = pop_rejepoch( EEG, reject_epoch ,0);
    
    cor=[];
    for k = 1:size(code,2)-2
        if cell2mat(code(k))==1 && cell2mat(code(k+2))==4
            cor=[cor 4];
        elseif cell2mat(code(k))==1&& cell2mat(code(k+2))==5
            cor=[cor 5];
        end
    end
        
        EEG1 = pop_epoch( EEG, {  '1'  }, [-0.5           1],  'epochinfo', 'yes');
        EEG1 = pop_rmbase( EEG1, [-300    0]);
        [EEG1 EVENTLIST1] = creaeventlist(EEG1);

        data = EEG1.data;
        data = data(:,:,find(cor==4));
        
        
        save([savepath, 'Stroop-' name(1:3) '_cong.mat'], 'data');
        
        cor=[];
        for k = 1:size(code,2)-2
            if cell2mat(code(k))==2 && cell2mat(code(k+2))==4
                cor=[cor 4];
            elseif cell2mat(code(k))==2&& cell2mat(code(k+2))==5
                cor=[cor 5];
            end
        end
        
        EEG2 = pop_epoch( EEG, {  '2'  }, [-0.5           1], 'newname', 'Merged datasets epochs', 'epochinfo', 'yes');
        EEG2 = pop_rmbase( EEG2, [-300    0]);
        data = EEG2.data;
        data= data(:,:,find(cor==4));
        save([savepath, 'Stroop-' name(1:3) '_incong.mat'], 'data');
        
        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 10,'gui','off');
        EEG = eeg_checkset( EEG );

        [ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, 11,'gui','off');
        EEG = eeg_checkset( EEG );
        %save([savepath, 'Stroop-' name(1:3) '.mat'], 'EEG');
    end
