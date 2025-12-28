
classdef TicTacToeApp < handle
    
    properties (Access = private)
        fig
        grid
        buttons    % 3x3 array of uibuttons
        statusLabel
        resetBtn
        board
        currentMark
        gameActive
        vsAI
        ai
        aiMark
    end
    
    methods
        function obj = TicTacToeApp(vsAI, aiMark)
            if nargin < 1, vsAI = false; end
            if nargin < 2, aiMark = 'O'; end
            
            assert(islogical(vsAI), 'vsAI must be logical true/false.');
            assert(ischar(aiMark) && numel(aiMark)==1 && (aiMark=='X' || aiMark=='O'), ...
                   'aiMark must be ''X'' or ''O''.');

            % Initialize model/state
            obj.board = Board();
            obj.currentMark = 'X';
            obj.gameActive = true;
            obj.vsAI = vsAI;
            obj.aiMark = aiMark;
            if vsAI
                obj.ai = AIPlayer(aiMark);
            else
                obj.ai = [];
            end
            
            % Build UI
            obj.createUI();
            obj.updateStatus();
            
            % If AI starts, let it play first
            if obj.vsAI && obj.currentMark == obj.aiMark
                obj.aiMoveIfNeeded();
            end
        end
    end
    
    methods (Access = private)
        function createUI(obj)
            % If your MATLAB does not support uifigure/uigridlayout, tell me
            % and I will provide a legacy GUI alternative.
            obj.fig = uifigure('Name','TicTacToe', ...
                               'Position',[100 100 360 440], ...
                               'Resize','off');
            obj.grid = uigridlayout(obj.fig, [4 3], ...
                                    'RowHeight', {100,100,100,'fit'}, ...
                                    'ColumnWidth', {100,100,100}, ...
                                    'Padding', [10 10 10 10], ...
                                    'RowSpacing', 8, ...
                                    'ColumnSpacing', 8);
            
            % Create 3x3 buttons
            obj.buttons = gobjects(3,3);
            for r = 1:3
                for c = 1:3
                    btn = uibutton(obj.grid, 'push', ...
                        'Text',' ', ...
                        'FontSize', 28, ...
                        'FontWeight', 'bold');
                    btn.Layout.Row = r;
                    btn.Layout.Column = c;
                    btn.Tag = sprintf('r%dc%d', r, c);
                    btn.ButtonPushedFcn = @(src,evt) obj.onCellPressed(src);
                    obj.buttons(r,c) = btn;
                end
            end
            
            % Status label
            obj.statusLabel = uilabel(obj.grid, ...
                'Text', 'Player X turn', ...
                'FontSize', 16, ...
                'FontWeight', 'bold');
            obj.statusLabel.Layout.Row = 4;
            obj.statusLabel.Layout.Column = [1 2];
            
            % Reset button
            obj.resetBtn = uibutton(obj.grid, 'push', ...
                'Text', 'Reset', ...
                'FontSize', 14, ...
                'ButtonPushedFcn', @(src,evt) obj.resetGame());
            obj.resetBtn.Layout.Row = 4;
            obj.resetBtn.Layout.Column = 3;
        end
        
        function onCellPressed(obj, src)
            if ~obj.gameActive
                return;
            end
            [r, c] = obj.parseTag(src.Tag);
            
            % Ignore click if cell not empty
            if ~obj.board.isEmpty(r, c)
                return;
            end
            
            obj.applyMove(r, c, obj.currentMark);
            
            % After human move, if still active and AI's turn, let AI play
            obj.aiMoveIfNeeded();
        end
        
        function aiMoveIfNeeded(obj)
            if obj.vsAI && obj.gameActive && obj.currentMark == obj.aiMark
                drawnow; % let UI update
                move = obj.ai.chooseMove(obj.board);
                obj.applyMove(move(1), move(2), obj.currentMark);
            end
        end
        
        function applyMove(obj, r, c, mark)
            ok = obj.board.placeMark(r, c, mark);
            if ~ok
                return; % illegal, ignore
            end
            obj.buttons(r, c).Text = mark;
            obj.buttons(r, c).Enable = 'off';
            
            w = obj.board.getWinner();
            if w ~= ' '
                obj.gameActive = false;
                obj.statusLabel.Text = sprintf('Player %s wins! 🎉', w);
                obj.disableRemainingButtons();
                return;
            end
            
            if obj.board.isFull()
                obj.gameActive = false;
                obj.statusLabel.Text = 'Draw! 🤝';
                obj.disableRemainingButtons();
                return;
            end
            
            % Next turn
            obj.currentMark = obj.opponentOf(mark);
            obj.updateStatus();
        end
        
        function updateStatus(obj)
            if obj.gameActive
                who = obj.currentMark;
                if obj.vsAI && obj.currentMark == obj.aiMark
                    obj.statusLabel.Text = sprintf('AI (%s) thinking…', who);
                else
                    obj.statusLabel.Text = sprintf('Player %s turn', who);
                end
            end
        end
        
        function resetGame(obj)
            obj.board.reset();
            obj.currentMark = 'X';
            obj.gameActive = true;
            for r = 1:3
                for c = 1:3
                    btn = obj.buttons(r,c);
                    btn.Text = ' ';
                    btn.Enable = 'on';
                end
            end
            obj.updateStatus();
            
            % If AI is set to start as 'X', play immediately
            if obj.vsAI && obj.currentMark == obj.aiMark
                obj.aiMoveIfNeeded();
            end
        end
        
        function disableRemainingButtons(obj)
            for r = 1:3
                for c = 1:3
                    if obj.board.isEmpty(r, c)
                        obj.buttons(r, c).Enable = 'off';
                    end
                end
            end
        end
        
        function [r, c] = parseTag(~, tag)
            % Expect tag like 'r1c2'
            vals = sscanf(tag, 'r%dc%d');
            r = vals(1); c = vals(2);
        end
        
        function opp = opponentOf(~, mark)
            if mark == 'O'
                opp = 'X';
            else
                opp = 'O';
            end
        end
    end
end

