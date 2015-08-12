%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% This is the codes for Empirical Mode Decomposition Trading algorithm -- Matlab Version
% Power by Zhuoxiong Zhao @ SCUT
% Contact : zhuoxiong.zhao@gmail.com
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%



% You can download the data from Wind
% clear,clc,close;
% w= windmatlab;
% % test the connection
% isconnected(w)
% % SanJuHuanBao
% begintime='20100427';
% endtime=today;
% wdata= w.wsd('300072.SZ','close',begintime,endtime,'Priceadj','CP','tradingcalendar','NIB');
% save('SJHB_data.mat', 'wdata');


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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

% to cal the R_mean
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

%% plot the data
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
