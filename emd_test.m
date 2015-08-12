% clear,clc,close;
% w= windmatlab;
% % test the connection
% isconnected(w)
% % SanJuHuanBao
% begintime='20100427';
% endtime=today;
% wdata= w.wsd('300072.SZ','close',begintime,endtime,'Priceadj','CP','tradingcalendar','NIB');
% save('SJHB_data.mat', 'wdata');
% 
% %% emd process
% load('SJHB_data.mat');
% [IMF,ORT,NB_ITERATIONS] = emd(wdata);
% 
% 
% IMF_new = cell(10,1);
% IMF_data = zeros(100,1);
% for i = 1:20:1300
%     IMF_new{(i+19)/20} = emd(wdata(i:(i+19)));
%     IMF_data(i:(i+19)) = IMF_new{(i+19)/20}(size(IMF_new{(i+19)/20},1), :);
% end
% 
% subplot(3,1,1);
% plot(wdata(1:1300));
% subplot(3,1,2);
% plot(IMF(size(IMF, 1),1:1300));
% subplot(3,1,3);
% plot(IMF_data);
% 
% %% for CFE data
% w = windmatlab;
% codes = 'IF00.CFE';
% fields = 'open,high,low,close';
% begintime = '2011-01-01';
% endtime = now;
% [ wdata_cfe, ~, ~, times, ~, ~ ] = w.wsi(codes,fields,begintime,endtime,'BarSize','1');
% save('CFE_data.mat', 'wdata_cfe','times');
% 
% 
% load('CFE_data.mat');
% 
% wdata_cfe_IMF = emd(wdata_cfe(:,4)','MAXMODES',4);
% 
% IMF_new = cell(315,1);
% IMF_data = zeros(6300,1);
% for i = 1:20:6300
%     IMF_new{(i+19)/20} = emd(wdata_cfe(i:(i+19)));
%     IMF_data(i:(i+19)) = IMF_new{(i+19)/20}(size(IMF_new{(i+19)/20},1), :);
% end
% 
% subplot(3,1,1);
% plot(1:6300,wdata_cfe(1:6300,4));
% set(gca, 'XTick', 1:6300);
% set(gca, 'XTickLabel', datestr(times));
% subplot(3,1,2);
% plot(wdata_cfe_IMF(size(wdata_cfe_IMF, 1),1:6300));
% set(gca, 'XTickLabel', datestr(times));
% subplot(3,1,3);
% plot(IMF_data);
% set(gca, 'XTickLabel', datestr(times));
% 
% 
% %% for process
% start_27_select_vec = times<datenum('28-Jul-2015');
% start_27_ori = wdata_cfe(1:(find(start_27_select_vec==0,1)-1),4)';
% start_27_IMF = wdata_cfe_IMF( 5, 1:(find(start_27_select_vec==0,1)-1));
% now_28_ori = wdata_cfe((find(start_27_select_vec==0,1):size(start_27_select_vec, 1)),4)';
% now41_28_ori = wdata_cfe((find(start_27_select_vec==0,1):(find(start_27_select_vec==0,1)+14)),4)';
% now41_28_IMF = emd(now41_28_ori,'MAXMODES',4);
% % cal the R
% R_mean = log(std(start_27_ori-start_27_IMF)/std(start_27_IMF));
% R_now = log(std(now41_28_ori-now41_28_IMF(size(now41_28_IMF, 1), :))/std(now41_28_IMF(size(now41_28_IMF, 1), :)));
% % open a position
% position = 0;
% if R_now < R_mean
%     signal = 1;
% end
% 
% % more or empty
% signal = 1;
% if now41_28_ori(15)<now41_28_ori(1)
%     signal = -1;
% end
% % judge when to close the position
% remain_28_ori = wdata_cfe(((find(start_27_select_vec==0,1)+15):(find(start_27_select_vec==0,1)+89)),4)';
% close_poition = 75;
% for i = 1:75
%     if (now41_28_ori(15)-remain_28_ori(i))/now41_28_ori(15)>0.006;
%         close_poition = i;
%     end
% end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% for IFOO.mat data
clear all, close all, clc;
load('IF00.mat');

all_data = IF00_data(:, 4)*300;
single_date = unique(IF00_date_num);
single_date_sum = zeros(size(single_date));
for i = 1:size(single_date, 1)
    single_date_sum(i) = sum(IF00_date_num==single_date(i));
end
devide_date = 20111230;
%% EMD & R for all every days
all_IMF = cell(size(single_date));
R_all = zeros(size(single_date));
for i = 1:size(single_date, 1)
    this_day_first_index = find(IF00_date_num==single_date(i),1,'first');
    all_IMF{i} = emd(all_data(this_day_first_index:(this_day_first_index+40)),'MAXMODES',4);
    R_all(i) = log(std(all_data(this_day_first_index:(this_day_first_index+40))-all_IMF{i}(size(all_IMF{i}, 1),:)')/std(all_IMF{i}(size(all_IMF{i}, 1), :)));
end

%% training samples 
last_index = find(IF00_date_num==devide_date,1,'last');
devide_index = find(single_date==devide_date);

% % to cal the R_mean
R_mean = mean(R_all(1:devide_index));

%% test samples
test_data = IF00_data((last_index+1):size(IF00_data, 1), 4)*300;


devide_index = 0;
% to save each point
% each column 1:in;2:out;3:meney;4:max downtown; 5:signal; 6:yield
trade = zeros(size(single_date, 1)-devide_index, 6);
trade_sum = 0;
win_count = 0;
short_count = 0;
long_count = 0;
for i = (devide_index+1):size(single_date, 1)
    i
    this_day = single_date(i);
    this_day_first_index = find(IF00_date_num==this_day,1,'first');
    this_day_last_index = find(IF00_date_num==this_day,1,'last');

    R_this_day = R_all(i);
    % R_mean = mean(R_all(i-400:i-1));
    if R_this_day<R_mean
        trade(i-devide_index, 1) = this_day_first_index+40;
        trade_sum = trade_sum+1;
    end
    
    if all_data(this_day_first_index+40) >= all_data(this_day_first_index)
        signal = 1;
    else
        signal = -1;
    end
    trade(i-devide_index, 5) = signal;
    % stop loss
    for j = (this_day_first_index+41):this_day_last_index
        F1 = all_data(this_day_first_index+40);
        F2 = all_data(j);
        if signal==1 && (F2*0.9999-F1*1.0001)/(F1*1.0001)<-0.006
            trade(i-devide_index, 6) = (F2*0.9999-F1*1.0001)/(F1*1.0001);
            trade(i-devide_index, 2) = j;
            break;
        elseif signal==-1 && (F1*0.9999-F2*1.0001)/(F1*1.0001)<-0.006
            trade(i-devide_index, 6) = (F1*0.9999-F2*1.0001)/(F1*1.0001);
            trade(i-devide_index, 2) = j;
            break;
        end
    end
    if trade(i-devide_index, 2) == 0
        trade(i-devide_index, 2) = this_day_last_index-1;
    end
    % cal the profit
    if i == devide_index+1
        % the first
        if trade(i-devide_index, 1) == 0
            trade(i-devide_index, 3) = 1000000;
            trade(i-devide_index, 6) = 0;
        elseif signal == 1
            trade(i-devide_index, 6) = (all_data(trade(i-devide_index, 2))*(1-0.0001))/(all_data(trade(i-devide_index, 1))*(1+0.0001))-1;
            trade(i-devide_index, 3) = 1000000*(trade(i-devide_index, 6)+1);
        else
            trade(i-devide_index, 6) = (all_data(trade(i-devide_index, 1))*(1-0.0001)-all_data(trade(i-devide_index, 2))*(1+0.0001))/(all_data(trade(i-devide_index, 1))*(1+0.0001));
            trade(i-devide_index, 3) = 1000000*(1+trade(i-devide_index, 6));
        end
    else
        % the next
        if trade(i-devide_index, 1) == 0
            trade(i-devide_index, 3) = trade(i-devide_index-1, 3);
            trade(i-devide_index, 6) = 0;
        elseif signal == 1
            trade(i-devide_index, 6) = (all_data(trade(i-devide_index, 2))*(1-0.0001))/(all_data(trade(i-devide_index, 1))*(1+0.0001))-1;
            trade(i-devide_index, 3) = trade(i-devide_index-1, 3)*(trade(i-devide_index, 6)+1);
        else
            trade(i-devide_index, 6) = (all_data(trade(i-devide_index, 1))*(1-0.0001)-all_data(trade(i-devide_index, 2))*(1+0.0001))/(all_data(trade(i-devide_index, 1))*(1+0.0001));
            trade(i-devide_index, 3) = trade(i-devide_index-1, 3)*(1+trade(i-devide_index, 6));
        end        
    end
    if trade(i-devide_index, 6)>0
        win_count = win_count+1;
    end
    if trade(i-devide_index, 1) ~= 0 && signal == 1
        long_count = long_count+1;
    elseif trade(i-devide_index, 1) ~= 0 && signal == -1
        short_count = short_count+1;
    end
end
subplot(3,1,1)
plot(trade(:,3));
title('Total Assets');
set(gca,'xtick',1:size(trade,1));
set(gca, 'XTickLabel',num2str(single_date));
%% cal the max downtown
for i = 1:size(trade, 1)
    max_data = max(trade(1:i, 3));
    trade(i, 4) = trade(i, 3)/max_data-1;
end
subplot(3,1,2)
plot(trade(:,4));
set(gca,'xtick',1:size(trade,1));
set(gca, 'XTickLabel',num2str(single_date));
date_num = size(single_date, 1)-devide_index;
title('Max Downtown');
year_profit=((trade(size(trade, 1), 3)-1000000)/1000000)/date_num*250;


%% plot one day data
specific_date = 20131121;
this_day_first_index = find(IF00_date_num==specific_date,1,'first');
this_day_last_index = find(IF00_date_num==specific_date,1,'last');
this_day_data = all_data(this_day_first_index:this_day_last_index);
this_day_time = IF00_time_num(this_day_first_index:this_day_last_index);
subplot(3,1,3)
plot(this_day_data);
set(gca,'xtick',1:size(this_day_time,1));
set(gca, 'XTickLabel',num2str(this_day_time));
title(num2str(specific_date));
win_rate = win_count/trade_sum;
% display the parameter
trade_sum
year_profit
win_rate
long_count
short_count