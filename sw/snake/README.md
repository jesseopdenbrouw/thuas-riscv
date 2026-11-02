# snake

Implementation of the good old snake game

## Description

This is an implementation of the snake game. The default screen size
is 24 lines by 80 columns. The initial delay between steps is 250 ms
and will be decremented by 2 every time the snake takes food. This
game uses ANSI control sequences. Make sure the terminal emulation
software supports these. Tested with PuTTY and `screen` on Linux.

Keys:

* `w` - move up
* `a` - move left
* `d` - move right
* `s` - move down
* `^R` - redraw screen

You can not reverse the direction, only forward or to the left or
right of the moving direction.

## Status

Works on the board.

