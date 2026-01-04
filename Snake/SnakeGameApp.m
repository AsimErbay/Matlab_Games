
classdef SnakeGameApp < handle
    %SNAKEGAMEAPP UI + kontrol: uifigure/uiaxes, timer, skor, hız, pause.
    
    properties (Access = private)
        fig
        grid
        ax
        img          % imagesc handle
        statusLbl
        scoreLbl
        startBtn
        resetBtn
        speedSlider
        wrapCheck
        timerObj
        period
        model        % SnakeModel
        paused
        cmap         % renk haritası
    end
    
    methods
        function obj = SnakeGameApp(gridSize, speedFPS, wrapWalls)
            if nargin < 1, gridSize = [20 20]; end
            if nargin < 2, speedFPS = 7; end  % saniyede 7 tik
            if nargin < 3, wrapWalls = false; end
            
            obj.period = max(0.03, 1/max(1, speedFPS)); % güvenli alt sınır
            obj.paused = true;
            
            obj.model = SnakeModel(gridSize, wrapWalls);
            obj.buildUI();
            obj.setupTimer();
            obj.redraw(true);
            obj.updateUITexts();
        end
        
        function delete(obj)
            % Güvenli kapatma
            try
                if ~isempty(obj.timerObj) && isvalid(obj.timerObj)
                    stop(obj.timerObj);
                    delete(obj.timerObj);
                end
            catch, end
            try
                if ~isempty(obj.fig) && isvalid(obj.fig)
                    delete(obj.fig);
                end
            catch, end
        end
    end
    
    methods (Access = private)
        function buildUI(obj)
            gs = obj.model.getGridSize();
            px = 24; % hücre başına piksel tahmini
            w = gs(2)*px; h = gs(1)*px;
            sideW = 220;
            
            obj.fig = uifigure('Name','Snake (OOP MATLAB)', ...
                               'Position',[100 100 w+sideW+40 max(h+40,360)], ...
                               'Resize','off');
            obj.fig.CloseRequestFcn = @(src,evt) obj.onClose();
            obj.fig.KeyPressFcn     = @(src,evt) obj.onKey(evt);
            
            obj.grid = uigridlayout(obj.fig, [1 2], ...
                'ColumnWidth', {w+20, sideW}, ...
                'RowHeight', {'1x'}, ...
                'ColumnSpacing', 10, 'Padding', [10 10 10 10]);
            
            % Oyun alanı
            obj.ax = uiaxes(obj.grid);
            obj.ax.Layout.Row = 1; obj.ax.Layout.Column = 1;
            obj.ax.XTick = []; obj.ax.YTick = [];
            obj.ax.XColor = 'none'; obj.ax.YColor = 'none';
            obj.ax.Visible = 'on';
            obj.ax.Box = 'on';
            obj.ax.DataAspectRatio = [1 1 1];
            hold(obj.ax, 'on');
            G = obj.model.getGrid();
            obj.img = imagesc(obj.ax, G);
            axis(obj.ax, 'image'); 
            % Eski sürümlerle uyum: InvertYDir yerine YDir='reverse'
            obj.ax.YDir = 'reverse';
            
            % Renkler: 0 boş, 1 head, 2 body, 3 food
            obj.cmap = [
                1.00 1.00 1.00  % boş - beyaz
                0.10 0.60 0.10  % head - koyu yeşil
                0.20 0.85 0.20  % body - açık yeşil
                0.90 0.20 0.20  % food - kırmızı
            ];
            colormap(obj.ax, obj.cmap);
            caxis(obj.ax, [0 3]);
            
            % Sağ panel
            right = uipanel(obj.grid, 'Title','Kontroller','FontWeight','bold');
            right.Layout.Column = 2; right.Layout.Row = 1;
            gl = uigridlayout(right, [8 1], ...
                'RowHeight', {'fit','fit','fit','fit','fit','fit','fit','1x'}, ...
                'Padding',[10 10 10 10], 'RowSpacing', 8);
            
            obj.statusLbl = uilabel(gl, 'Text','Hazır', 'FontSize', 14, 'FontWeight','bold');
            obj.scoreLbl  = uilabel(gl, 'Text','Skor: 0', 'FontSize', 14);
            
            obj.startBtn = uibutton(gl, 'push', 'Text','Başlat', ...
                'ButtonPushedFcn', @(s,e) obj.toggleStart());
            obj.resetBtn = uibutton(gl, 'push', 'Text','Sıfırla', ...
                'ButtonPushedFcn', @(s,e) obj.resetGame());
            
            uilabel(gl, 'Text','Hız (FPS)', 'FontSize', 12);
            obj.speedSlider = uislider(gl, 'Limits',[2 20], 'Value', 1/obj.period, ...
                'MajorTicks', 2:2:20, ...
                'ValueChangingFcn', @(s,e) obj.onSpeedChanging(e), ...
                'ValueChangedFcn',  @(s,e) obj.onSpeedChanged());
            
            obj.wrapCheck = uicheckbox(gl, 'Text','Duvarlardan sar (wrap)', ...
                'Value', false, 'ValueChangedFcn', @(s,e) obj.onWrapChanged());
            
            uilabel(gl, 'Text', sprintf(['Klavye:\n' ...
                '← → ↑ ↓ : yön\n' ...
                'Space   : duraklat/devam\n' ...
                'R       : sıfırla']), ...
                'FontName','monospaced');
        end
        
        function setupTimer(obj)
            obj.timerObj = timer( ...
                'ExecutionMode','fixedSpacing', ...
                'Period', obj.period, ...
                'TimerFcn', @(~,~) obj.onTick(), ...
                'ErrorFcn', @(~,e) disp(getReport(e.Data)));
        end
        
        function onTick(obj)
            ev = obj.model.step();
            obj.redraw(false);
            obj.updateUITexts();
            if ev.gameOver
                obj.paused = true;
                obj.statusLbl.Text = 'Oyun bitti! 😵';
                try, stop(obj.timerObj); catch, end
                obj.startBtn.Text = 'Başlat';
            elseif ev.ateFood
                % Skor güncellemesi updateUITexts ile oluyor
            end
        end
        
        function redraw(obj, resetAxes)
            if nargin < 2, resetAxes = false; end
            G = obj.model.getGrid();
            if isvalid(obj.img)
                set(obj.img, 'CData', G);
            else
                obj.img = imagesc(obj.ax, G);
            end
            if resetAxes
                axis(obj.ax, 'image'); 
                % Eski sürümlerle uyum: InvertYDir yerine YDir='reverse'
                obj.ax.YDir = 'reverse';
                colormap(obj.ax, obj.cmap); caxis(obj.ax, [0 3]);
            end
            drawnow limitrate;
        end
        
        function updateUITexts(obj)
            obj.scoreLbl.Text = sprintf('Skor: %d', obj.model.getScore());
            if obj.model.isAlive()
                if obj.paused
                    obj.statusLbl.Text = 'Duraklatıldı ⏸️';
                else
                    obj.statusLbl.Text = 'Oyun sürüyor ▶️';
                end
            else
                obj.statusLbl.Text = 'Oyun bitti! 😵';
            end
        end
        
        function toggleStart(obj)
            if obj.paused
                obj.paused = false;
                try, start(obj.timerObj); catch, end
                obj.startBtn.Text = 'Duraklat';
                obj.updateUITexts();
            else
                obj.paused = true;
                try, stop(obj.timerObj); catch, end
                obj.startBtn.Text = 'Başlat';
                obj.updateUITexts();
            end
        end
        
        function resetGame(obj)
            try, stop(obj.timerObj); catch, end
            obj.model.reset();
            obj.paused = true;
            obj.startBtn.Text = 'Başlat';
            obj.redraw(true);
            obj.updateUITexts();
        end
        
        function onSpeedChanging(obj, e)
            % Slider sürüklenirken canlı ayarla
            fps = max(2, min(20, e.Value));
            obj.period = max(0.03, 1/fps);
            if ~isempty(obj.timerObj) && isvalid(obj.timerObj)
                wasRunning = strcmp(obj.timerObj.Running, 'on');
                try, stop(obj.timerObj); catch, end
                obj.timerObj.Period = obj.period;

                    if wasRunning && ~obj.paused
                        try, start(obj.timerObj); catch, end
                    end

            end
        end
        
        function onSpeedChanged(obj)
            % No-op; anlık ayarlıyoruz.
        end
        
        function onWrapChanged(obj)
            gs = obj.model.getGridSize();
            wrap = obj.wrapCheck.Value;
            wasRunning = ~obj.paused;
            obj.paused = true; obj.startBtn.Text = 'Başlat';
            try, stop(obj.timerObj); catch, end
            obj.model = SnakeModel(gs, wrap);
            obj.redraw(true);
            obj.updateUITexts();
            if wasRunning
                obj.toggleStart();
            end
        end
        
        function onKey(obj, evt)
            % UIFigure KeyPress: evt.Key -> 'uparrow','downarrow','leftarrow','rightarrow','space','r',...
            switch evt.Key
                case 'uparrow',    obj.model.changeDirection('up');
                case 'downarrow',  obj.model.changeDirection('down');
                case 'leftarrow',  obj.model.changeDirection('left');
                case 'rightarrow', obj.model.changeDirection('right');
                case 'space'
                    obj.toggleStart();
                case 'r'
                    obj.resetGame();
            end
        end
        
        function onClose(obj)
            % Figure kapatılırken timer temizliği
            try, stop(obj.timerObj); catch, end
            try, delete(obj.timerObj); catch, end
            delete(obj.fig);
        end
    end
end
