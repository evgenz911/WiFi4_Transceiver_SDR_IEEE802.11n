clear;close all;clc;
Parameters_struct = Global_Parameters;

%% Button setting
figure('Name','RX','NumberTitle','off');
button = uicontrol; % Generate GUI button
set(button,'String','Stop !','Position',[1475 15 100 60]); % Add "Stop !" text
set(gcf,'Units','centimeters','position',[1 2 49 24]); % Set the postion of GUI
set(button,'Callback','setstate0_RX'); % Set the reaction of pushing button

%% Hardware Parameters
rx_object = sdrrx('AD936x',...
           'IPAddress',             Parameters_struct.IPAddress,...
           'CenterFrequency',       Parameters_struct.CenterFrequency,...
           'BasebandSampleRate',    Parameters_struct.Bandwidth,...
           'SamplesPerFrame',       3500,...
           'ChannelMapping',        [1 2]);

Ready_Time = 0;
scale = 1024;

%% Main
state = 1; % status Start
Run_time_number = 1;
while (state == 1)
    try
    
    [data_rx_raw, dataLength, lostSample] = step(rx_object);
    if Run_time_number > Ready_Time
        
        % ----- RX Raw -----%
        data_rx_scaled = double(data_rx_raw)./scale; % [3500x2]
        RX = data_rx_scaled.'; % [2x3500]
        
        % Demodulation
        [M_n,Threshold_graph,H_hat_time,RX_Payload_1_no_Equalizer,RX_Payload_2_no_Equalizer,RX_Payload_1_no_pilot,RX_Payload_2_no_pilot,BER] = OFDM_RX(RX,Parameters_struct);

        % RX Raw constellation
        subplot(2,4,1),plot(RX(1,:),'.');title('RX-Raw');axis([-1.5 1.5 -1.5 1.5]);axis square;
        subplot(2,4,2),plot(real(RX(1,:)));title('I');axis([1 3000 -1.5 1.5]);axis square;
        subplot(2,4,3),plot(imag(RX(1,:)));title('Q');axis([1 3000 -1.5 1.5]);axis square;
        
        % Welch Spectrum graph
        [Spectrum_waveform,Welch_Spectrum_frequency] = pwelch(RX(1,:),[],[],[],rx_object.BasebandSampleRate,'centered','power');
        subplot(2,4,4),plot(Welch_Spectrum_frequency,pow2db(Spectrum_waveform));
        title('Welch Power Spectral Density'); axis([-rx_object.BasebandSampleRate/2 rx_object.BasebandSampleRate/2 -100 -10]); axis square;
        
        drawnow;

        % Packet Detection plot
        subplot(2,4,5),plot(1:length(M_n),M_n,1:length(M_n),Threshold_graph); title('Packet Detection'); axis([1,length(M_n),0,1.2]); axis square;
        
        % Channel estimation graph
        subplot(2,4,6),plot(abs(H_hat_time(1,:)));
        hold on;
        subplot(2,4,6),plot(abs(H_hat_time(2,:)));
        subplot(2,4,6),plot(abs(H_hat_time(3,:)));
        subplot(2,4,6),plot(abs(H_hat_time(4,:)));
        hold off;
        title('Channel Estimation');
        legend('H11','H12','H21','H22');
        axis square;axis([1 64 0 5]);xlabel('Time');
        
        % Before Equalizer constellation
        subplot(2,4,7),plot(RX_Payload_1_no_Equalizer,'*');
        hold on
        subplot(2,4,7),plot(RX_Payload_2_no_Equalizer,'*');
        hold off
        title('Before Equalizer');axis([-8 8 -8 8]); axis square;
        
        % Demodulation constellation + BER
        subplot(2,4,8),plot(RX_Payload_1_no_pilot,'*');
        hold on
        subplot(2,4,8),plot(RX_Payload_2_no_pilot,'*');
        hold off
        title({'Demodulation';['BER = ',num2str(BER)]}); axis([-1.5 1.5 -1.5 1.5]); axis square;
        
        Run_time_number = Run_time_number+1;
    end
    
    if Run_time_number <= Ready_Time  % Ready !! REVIEW !!
        % disp('Ready');
    end
    Run_time_number = Run_time_number+1;
    
    catch ME
        fprintf(2,'Error occurred & Stop Hardware\n');
        fprintf(2,'Error message: %s\n', ME.message);
        fprintf(2,'%s\n', getReport(ME, 'extended'));

        release(rx_object);
        state=0;

    end
end

release(rx_object);
close all;
disp("The transmission has ended");