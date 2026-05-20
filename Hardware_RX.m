function Hardware_RX
    clearvars; close all; clc;

    % Parameters
    Parameters_struct = Global_Parameters;
    isRunning = true;
    debugMode = false;
    RX_numb = true;
    DelayAfterFrame_s = 0; % seconds; delay before reading each SDR frame
    scale = 1024;
    record = false;
    BER_log = [];

    % Figure and button setup
    figure('Name','RX','NumberTitle','off', ...
           'CloseRequestFcn', @onClose, ...
           'Units', 'normalized', ...
           'Position', [0.05 0.08 0.92 0.86]);

    uicontrol('String', 'Record', ...
              'Units', 'normalized', ...
              'Position', [0.86 0.01 0.13 0.07], ...
              'Callback', @onRecord);

    % Hardware Parameters
    if ~debugMode
        if exist('RX.mat','file') == 2        
            rx_object = sdrrx('AD936x',...
                          'IPAddress',             Parameters_struct.IPAddress,...
                          'CenterFrequency',       Parameters_struct.CenterFrequency,...
                          'BasebandSampleRate',    Parameters_struct.Bandwidth,...
                          'SamplesPerFrame',       3500,...
                          'ChannelMapping',        [1 2]);
        end
    end

    while isRunning
        
        
        % Receiving data from SDR or file (in debug mode)
        try
            if ~debugMode
                [data_rx_raw, ~, ~] = step(rx_object);
                data_rx_scaled = double(data_rx_raw)./scale; % [3500x2]
                RX = data_rx_scaled.'; % [2x3500] Scale data
            else
                if RX_numb
                    load('RX.mat', 'RX');
                    RX_numb = false;
                else
                    load('RX2.mat', 'RX');
                    RX_numb = true;
                end
            end

            % Demodulation
            [M_n,Threshold_graph,H_hat_time,RX_Payload_1_no_Equalizer,RX_Payload_2_no_Equalizer, ...
            RX_Payload_1_no_pilot,RX_Payload_2_no_pilot,BER] = OFDM_RX(RX,Parameters_struct);

        catch ME
            fprintf(2,'Error occurred & Stop Hardware\n');
            fprintf(2,'Error message: %s\n', ME.message);
            fprintf(2,'%s\n', getReport(ME, 'extended'));
            release(rx_object);
        end

        if record, BER_log(end + 1) = BER; end
        
        % RX Raw constellation
        subplot(2,4,1),plot(RX(1,:),'.'); title('RX-Raw');
        axis([-1.5 1.5 -1.5 1.5]); axis square;

        subplot(2,4,2),plot(real(RX(1,:))); title('I'); 
        axis([1 3000 -1.5 1.5]); axis square;

        subplot(2,4,3),plot(imag(RX(1,:))); title('Q');
        axis([1 3000 -1.5 1.5]); axis square;
        
        % Welch Spectrum graph
        [Spectrum_waveform,Welch_Spectrum_frequency] = pwelch(RX(1,:),[],[],[],Parameters_struct.Bandwidth,'centered','power');
        subplot(2,4,4),plot(Welch_Spectrum_frequency,pow2db(Spectrum_waveform)); title('Welch Power Spectral Density'); 
        axis([-Parameters_struct.Bandwidth/2 Parameters_struct.Bandwidth/2 -100 -10]); axis square;
        
        drawnow;

        % Packet Detection plot
        subplot(2,4,5),plot(1:length(M_n),M_n,1:length(M_n),Threshold_graph); 
        title('Packet Detection'); axis([1,length(M_n),0,1.2]); axis square;
        
        % Channel estimation graph
        subplot(2,4,6),plot(abs(H_hat_time(1,:)));
        hold on;
        subplot(2,4,6),plot(abs(H_hat_time(2,:)));
        subplot(2,4,6),plot(abs(H_hat_time(3,:)));
        subplot(2,4,6),plot(abs(H_hat_time(4,:)));
        hold off;
        title('Channel Estimation');
        legend('H11','H12','H21','H22');
        axis square; axis([1 64 0 5]); xlabel('Time');
        
        % Before Equalizer constellation
        subplot(2,4,7),plot(RX_Payload_1_no_Equalizer,'*');
        hold on
        subplot(2,4,7),plot(RX_Payload_2_no_Equalizer,'*');
        hold off
        title('Before Equalizer');
        axis([-8 8 -8 8]); axis square;
        
        % Demodulation constellation + BER
        subplot(2,4,8),plot(RX_Payload_1_no_pilot,'*');
        hold on
        subplot(2,4,8),plot(RX_Payload_2_no_pilot,'*');
        hold off
        title({'Demodulation';['BER = ',num2str(BER)]}); 
        axis([-1.5 1.5 -1.5 1.5]); axis square;
        
        if DelayAfterFrame_s > 0
            pause(DelayAfterFrame_s);
        end

    end

    function onClose(src,~)
        isRunning = false;
        if exist('BER_log','var'),      save("BER_data", "BER_log"); end
        if exist('tx_object','var'),    release(rx_object); end
        if isgraphics(src),             delete(src); end
    end
    
    function onRecord(src,~)
        if ~record
            record = true;
            set(src, 'String', 'stop Record');
        else
            record = false;
            save("BER_data", "BER_log");
            set(src, 'String', 'Record');
        end
    end
end