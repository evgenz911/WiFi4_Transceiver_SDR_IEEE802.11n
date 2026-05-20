function [TX_signal_jam, TX_signal_jam_2] = make_TX_jam(TX_signal, TX_signal_2, relAmp, f_jam)
    
    Parameters_struct = Global_Parameters;
    
    s1 = (TX_signal.');
    s2 = (TX_signal_2.');
    
    max_sig = max(abs(fft(s1)));

    N1 = length(s1);
    N2 = length(s2);
    
    % Variables
    SNRdB  = 13;
    phi0   = 2*pi*rand;
    
    % Time
    t1 = (0:N1-1) * Parameters_struct.Ts;
    t2 = (0:N2-1) * Parameters_struct.Ts;
    
    % Relative ampltiude normalization
    s1n = s1 / rms(s1);
    s2n = s2 / rms(s2);
    
    % Complex AWGN with SNR referenced to payload signal power 
    % Ps1 = mean(abs(s1n).^2);
    % Ps2 = mean(abs(s2n).^2);
    % 
    % Pn1 = Ps1 / 10^(SNRdB/10);
    % Pn2 = Ps2 / 10^(SNRdB/10);
    % 
    % w1 = sqrt(Pn1/2) * (randn(1,N1) + 1j*randn(1,N1));
    % w2 = sqrt(Pn2/2) * (randn(1,N2) + 1j*randn(1,N2));
    
    % Harmonic noise
    %A1 = relAmp * rms(s1n);   % т.к. s1n уже rms=1, это ~= relAmp
    %A2 = relAmp * rms(s2n);

    j1 = relAmp*exp(1j*(2*pi*f_jam*t1 + phi0));
    j2 = relAmp*exp(1j*(2*pi*f_jam*t2 + phi0));
    
    % Final jammed signals
    TX_signal_jam   = s1 + j1;
    TX_signal_jam_2 = s2 + j2;
    
    TX_signal_jam = TX_signal_jam.';
    TX_signal_jam_2 = TX_signal_jam_2.';

    save('TX_signal_jam.mat',   'TX_signal_jam',   'SNRdB','relAmp','f_jam','phi0');
    save('TX_signal_jam_2.mat', 'TX_signal_jam_2', 'SNRdB','relAmp','f_jam','phi0');
end