
classdef Board < handle
    properties
        height
        width
        grid
    end

    methods
        function this = Board(h, w)
            if nargin < 1, h = 20; end
            if nargin < 2, w = 10; end
            this.height = h;
            this.width  = w;
            this.grid   = zeros(h, w, 'uint8');
        end

        function tf = isInside(this, cells)
            tf = all(cells(:,1) >= 1 & cells(:,1) <= this.height & ...
                     cells(:,2) >= 1 & cells(:,2) <= this.width);
        end

        function tf = isFree(this, cells)
            idx = sub2ind(size(this.grid), cells(:,1), cells(:,2));
            tf = all(this.grid(idx) == 0);
        end

        function tf = isValid(this, piece, pos, rotIndex)
            cells = piece.getCells(pos, rotIndex);
            tf = this.isInside(cells) && this.isFree(cells);
        end

        function lock(this, piece)
            cells = piece.getCells();
            idx = sub2ind(size(this.grid), cells(:,1), cells(:,2));
            this.grid(idx) = piece.id;
        end

        function nCleared = clearFullLines(this)
            full = all(this.grid ~= 0, 2);
            nCleared = sum(full);
            if nCleared > 0
                newGrid = zeros(size(this.grid), 'uint8');
                rowsToKeep = this.grid(~full, :);
                newGrid(end-size(rowsToKeep,1)+1:end, :) = rowsToKeep;
                this.grid = newGrid;
            end
        end

        function reset(this)
            this.grid(:) = 0;
        end
    end
end
