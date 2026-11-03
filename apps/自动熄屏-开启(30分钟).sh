#!/bin/sh
# Enable a repeating 30-minute input idle timer. Returns to Apps immediately.
# Touch/normal keys restore brightness; downloads and network remain running.
exec /usr/bin/nds-screen-off --start --idle-minutes 30
