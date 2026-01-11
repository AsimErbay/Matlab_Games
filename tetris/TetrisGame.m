
classdef TetrisGame < handle
    properties
        board   Board
        cur     Tetromino
        next    Tetromino
        timerObj
        tick = 0.5           
        fig
        ax
        im
        isRunning = false
        gameOver = false
        score = 0
    end

    methods
        function this = TetrisGame(h, w)
            if nargin < 1, h = 20; end
            if nargin < 2, w = 10; end
            this.board = Board(h, w);
            this.next  = Tetromino.random();

            this.makeFigure();
            this.spawn();
            this.render();
        end

        function makeFigure(this)
            this.fig = figure('Name','Tetris OOP (Basic)','NumberTitle','off',...
                              'KeyPressFcn',@(src,evt) this.onKey(evt),...
                              'CloseRequestFcn',@(src,evt) this.onClose(src));
            this.ax = axes('Parent', this.fig);
            this.im = imagesc(this.ax, this.board.grid);
            axis(this.ax,'equal','off');

            
            cmap = [0.1 0.1 0.1; ... % background
                    0   1   1;   ... % I - cyan
                    1   1   0;   ... % O - yellow
                    0.6 0   1;   ... % T - purple
                    0   1   0;   ... % S - green
                    1   0   0;   ... % Z - red
                    0   0   1;   ... % J - blue
                    1   0.5 0];      % L - orange
            colormap(this.ax, cmap);
            caxis(this.ax, [0 7]);
            title(this.ax, sprintf('Score: %d', this.score), 'FontWeight','bold');
        end

        function start(this)
            if this.isRunning, return; end
            this.timerObj = timer('ExecutionMode','fixedSpacing', ...
                                  'Period', this.tick, ...
                                  'TimerFcn', @(~,~) this.tickDown());
            start(this.timerObj);
            this.isRunning = true;
        end

        function stop(this)
            if this.isRunning && ~isempty(this.timerObj) && isvalid(this.timerObj)
                stop(this.timerObj); delete(this.timerObj);
            end
            this.isRunning = false;
        end

        function onClose(this, src)
            this.stop();
            if isvalid(src), delete(src); end
        end

        function spawn(this)
            this.cur = this.next;
            this.cur.rotIndex = 1;

            % Center at top based on current rotation width
            mask = this.cur.rotations{this.cur.rotIndex};
            startCol = floor((this.board.width - size(mask,2))/2) + 1;
            this.cur.pos = [1, startCol];

            this.next = Tetromino.random();

            if ~this.board.isValid(this.cur, this.cur.pos, this.cur.rotIndex)
                this.gameOver = true;
                this.stop();
                title(this.ax, sprintf('Game Over! Score: %d  (Press R to restart)', this.score), ...
                      'Color',[1 0.2 0.2], 'FontWeight','bold');
            end
        end

        function tickDown(this)
            if this.gameOver, return; end
            this.tryMove([1, 0]); 
        end

        function ok = tryMove(this, dpos)
            newPos = this.cur.pos + dpos;
            if this.board.isValid(this.cur, newPos, this.cur.rotIndex)
                this.cur.pos = newPos;
                this.render();
                ok = true;
            else
                if all(dpos == [1, 0])
                    this.board.lock(this.cur);
                    cleared = this.board.clearFullLines();
                    if cleared > 0
                        this.score = this.score + 100 * (cleared^2);
                        title(this.ax, sprintf('Score: %d', this.score));
                    end
                    this.spawn();
                    this.render();
                end
                ok = false;
            end
        end

        function ok = tryRotate(this, dir)
            newIdx = this.cur.rotatedIndex(dir);
            pos = this.cur.pos;
            kicks = [ 0  0;
                      0 -1; 0  1;
                      0 -2; 0  2;
                      1  0; -1 0 ];

            ok = false;
            for k = 1:size(kicks,1)
                testPos = pos + kicks(k,:);
                if this.board.isValid(this.cur, testPos, newIdx)
                    this.cur.rotIndex = newIdx;
                    this.cur.pos = testPos;
                    ok = true; break;
                end
            end
            if ok, this.render(); end
        end

        function hardDrop(this)
            while this.tryMove([1, 0]), end
        end

        function render(this)
            scene = this.board.grid;
            if ~this.gameOver
                cells = this.cur.getCells();
                in = cells(:,1) >= 1 & cells(:,1) <= this.board.height & ...
                     cells(:,2) >= 1 & cells(:,2) <= this.board.width;
                cells = cells(in,:);
                idx = sub2ind(size(scene), cells(:,1), cells(:,2));
                scene(idx) = this.cur.id;
            end
            set(this.im, 'CData', scene);
            drawnow limitrate;
        end

        function onKey(this, evt)
            if this.gameOver
                if strcmpi(evt.Key, 'r'), this.reset(); end
                return;
            end

            switch evt.Key
                case 'leftarrow'
                    this.tryMove([0, -1]);
                case 'rightarrow'
                    this.tryMove([0,  1]);
                case 'downarrow'
                    this.tryMove([1,  0]);
                case 'uparrow'
                    this.tryRotate(1);
                case 'x'
                    this.tryRotate(1);
                case 'z'
                    this.tryRotate(-1);
                case 'space'
                    this.hardDrop();
                case 'p'
                    if this.isRunning, this.stop(); else, this.start(); end
                case 'r'
                    this.reset();
            end
        end

        function reset(this)
            this.stop();
            this.board.reset();
            this.score = 0;
            this.gameOver = false;
            title(this.ax, sprintf('Score: %d', this.score), 'Color',[0 0 0], 'FontWeight','bold');
            this.next = Tetromino.random();
            this.spawn();
            this.render();
            this.start();
        end
    end
end
