function Hardware_TX
    clearvars; close all; clc;

    Parameters_struct = Global_Parameters;

    % Hardware Parameters
    % tx_object = sdrtx('AD936x', ...
    %            'IPAddress',            Parameters_struct.IPAddress, ...
    %            'CenterFrequency',      Parameters_struct.CenterFrequency, ...
    %            'BasebandSampleRate',   Parameters_struct.Bandwidth, ...
    %            'Gain',                 0, ...
    %            'ChannelMapping',       [1,2]);

    % UI & Button setup
    command_window = figure('Name', 'TX', 'NumberTitle', 'off', 'Units', 'normalized', ...
                            'Position',[0.4 0.4 0.3 0.4], ...
                            'MenuBar','none', ...
                            'CloseRequestFcn', @onClose);
    
    statement_text = uicontrol(command_window, 'Style', 'text', 'Units', 'normalized', ...
                                    'Position',[0.1 0.65 0.8 0.2], ...
                                    'String', 'Stopped', ...
                                    'FontSize', 20,'HorizontalAlignment', 'center', ...
                                    'BackgroundColor',[0.9 0.9 0.9]);
    
    uicontrol(command_window, 'Style', 'pushbutton',...
                       'Units','normalized','Position', [0.5 0.2 0.4 0.3],...
                       'String', 'START', 'Callback', @onToggle);
                
    modeMenu = uicontrol(command_window, 'Style','popupmenu', ...
                        'Units','normalized', 'Position',[0.1 0.5 0.8 0.12], ...
                        'String', {'transmitRepeat','step'}, ...
                        'Value', 1, ...
                        'Callback', @onModeChange);

    jamModeSwitch = uicontrol(command_window, 'Style', 'pushbutton',...
                       'Units','normalized','Position', [0.12 0.3 0.22 0.12],...
                       'String', 'Jam Off', 'Callback', @onJamToggle);

    jamSlider1Value = uicontrol(command_window, 'Style', 'text', ...
                        'Units', 'normalized', 'Position', [0.05 0.18 0.4 0.04], ...
                        'String', 'Relative amplitude: 1.00', 'HorizontalAlignment', 'center', ...
                        'Visible','off');

    jamSlider1 = uicontrol(command_window, 'Style', 'slider', ...
                        'Units', 'normalized', 'Position', [0.12 0.22 0.22 0.05], ...
                        'Min', 0, 'Max', 5, 'Value', 1.00, ...
                        'Callback', @(src,~)onJamSliderChange(src, jamSlider1Value, 'Relative amplitude'), ...
                        'Visible','off');

    jamSlider2Value = uicontrol(command_window, 'Style', 'text', ...
                        'Units', 'normalized', 'Position', [0.05 0.03 0.4 0.04], ...
                        'String', 'Central Frequency: 1000', 'HorizontalAlignment', 'center', ...
                        'Visible','off');

    jamSlider2 = uicontrol(command_window, 'Style', 'slider', ...
                        'Units', 'normalized', 'Position', [0.12 0.07 0.22 0.05], ...
                        'Min', 0, 'Max', 10000, 'Value', 1000, ...
                        'Callback', @(src,~)onJamSliderChange(src, jamSlider2Value, 'Central Frequency'), ...
                        'Visible','off');
                        
    stepButton = uicontrol(command_window, 'Style','pushbutton', ...
                           'Units','normalized', 'Position',[0.5 0.05 0.4 0.12], ...
                           'String','STEP', 'Callback', @onStep, ...
                           'Visible','off', 'Enable','off');
    
    txMode = 'transmitRepeat';
    isTxOn = false;
    isJamOn = false;

    % TX data files (without extension)
    tx1File = 'TX_signal';
    tx2File = 'TX_signal_2';

    % Will be (re)loaded on every START
    TX_Frame = [];
    
    % Callback functions
    
    function onModeChange(src, ~)
        if isTxOn
            items = get(src,'String');
            set(src,'Value', find(strcmp(items, txMode), 1, 'first'));
            return;
        end

        items = get(src,'String');
        txMode = items{get(src,'Value')};
        
        if strcmp(txMode, 'transmitRepeat')
            if isgraphics(stepButton), set(stepButton,'Visible','off'); end

        elseif strcmp(txMode, 'step')
            if isgraphics(stepButton), set(stepButton,'Visible','on'); end
        end
    end
    
    function onToggle(src,~)
        %START
        if ~isTxOn
            isTxOn = true;

            % (Re)load TX data on every START
            try
                TX_Frame = buildTxFrame();
            catch ME
                isTxOn = false;
                if isgraphics(statement_text), set(statement_text,'String',"TX load error: " + string(ME.message)); end
                if isgraphics(src),            set(src,'String','START'); end
                if isgraphics(modeMenu),       set(modeMenu,'Enable','on'); end
                if strcmp(txMode, 'step') && isgraphics(stepButton), set(stepButton,'Enable','off'); end
                return;
            end
            
            % Jam Mode turn off
            set(jamModeSwitch, 'Enable', 'off');

            % Jam Sliders turn off
            if isJamOn
                set(jamSlider1, 'Enable', 'off');
                set(jamSlider2, 'Enable', 'off');
            end
            % Mode menu turn off
            if isgraphics(src),         set(src,'String','STOP'); end
            if isgraphics(modeMenu),    set(modeMenu,'Enable','off'); end
            
            % TransmitRepeat mode
            if strcmp(txMode,'transmitRepeat')
                if isgraphics(statement_text), set(statement_text,'String','Transmitting: transmitRepeat'); end
                transmitRepeat(tx_object, TX_Frame);
                return;

            else
            % Step mode
                if isgraphics(statement_text),  set(statement_text,'String','Step mode: press STEP'); end
                if isgraphics(stepButton),      set(stepButton, 'Enable', 'on'); end
            end
        
        %STOP
        else
            isTxOn = false;
    
            if exist('tx_object','var')
                release(tx_object);
            end

            % Jam Mode turn on
            set(jamModeSwitch, 'Enable', 'on');

            % Jam sliders turn on 
            if isJamOn
                set(jamSlider1, 'Enable', 'on');
                set(jamSlider2, 'Enable', 'on');
            end

            % Status change
            if isgraphics(src),             set(src,'String','START'); end
            if isgraphics(statement_text),  set(statement_text,'String','Stopped'); end
            if isgraphics(modeMenu),        set(modeMenu,'Enable','on'); end
            
            % Step button turn off
            if strcmp(txMode, 'step')
                if isgraphics(stepButton),  set(stepButton,'Enable','off'); end
            end
        end
    end
    
    function onStep(~,~)
        if ~isTxOn || ~strcmp(txMode,'step')
            return;
        end
        step(tx_object, TX_Frame);
    end

    function onClose(src,~)
        isTxOn = false;
        if exist('tx_object','var')
            release(tx_object);
        end
        if isgraphics(src), delete(src); end
    end

    function TX_Frame_local = buildTxFrame()

        % TX mat files existence check
        if ~(exist('TX_signal.mat','file')==2 && exist('TX_signal_2.mat','file')==2)
            run('OFDM_TX.m');
        end

        s1 = load(tx1File, "TX_signal");
        s2 = load(tx2File, "TX_signal_2");

        TX_Hardware = repmat(s1.TX_signal.',4,1);      % Transmit Data must be >= 4096
        TX_Hardware_2 = repmat(s2.TX_signal_2.',4,1); 

        if isJamOn
            amp = get(jamSlider1, 'Value');
            central_freq = get(jamSlider2, 'Value'); 
            [TX_Hardware,TX_Hardware_2] = make_TX_jam(TX_Hardware, TX_Hardware_2, amp, central_freq); 
        end

        TX_Frame_local = [TX_Hardware, TX_Hardware_2];
    end

    function onJamToggle(src, ~)
        if ~isJamOn
            isJamOn = true;
            set(src,'String','Jam On');
            set(jamSlider1Value, 'Visible', 'on');
            set(jamSlider1, 'Visible', 'on');
            set(jamSlider2Value, 'Visible', 'on');
            set(jamSlider2, 'Visible', 'on');
        else
            isJamOn = false;
            set(src,'String','Jam off');
            set(jamSlider1Value, 'Visible', 'off');
            set(jamSlider1, 'Visible', 'off');
            set(jamSlider2Value, 'Visible', 'off');
            set(jamSlider2, 'Visible', 'off');
        end
    end

    function onJamSliderChange(src, valueText, label)
        if ~isgraphics(src) || ~isgraphics(valueText)
            return;
        end
        set(valueText, 'String', sprintf('%s: %.2f', label, get(src, 'Value')));
    end
end