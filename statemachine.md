# Logging state machine

The pysical logger is a 3x3 numerical keypad, with following buttons:
```
789
456
123
```

Once state machine reaches the last state, a message is logged including current GPS coordinates and GPS timestamp.

The state machine:

## Left coumn - metadata

### 7 - Reset from any state
7 resets to initial state if preeceded by another number. If no preceeding number, it logs "reset" so that in post processing I can decide to delete previous entry

### 4 - Generic flag
4 sets a generic flag, it means an unusual situation that I'm logging separately

### 1 - Bike path quality
1 means issue with bike route, signage or pavement

## Right column - Emitting vehicle

### 6 - Personal vehicle
66 - unnecessarily large vehicle
63 - personal vehicle in need of repair
62 - antique
61 - personal vehicle idling

### 9 - Commercial vehicle
99 - truck
98 - bus
93 - truck in need of repair
92 - bus in need of repair
91 - commercial vehicle idling

### 3 - Available

## Middle column - Environment

### 8 - Traffic
8 is traffic jam

### 5 - Clean baseline
5 is a clean baseline (no traffic)

### 2 - Available

# Implementation

To support background processing, the screen is set to 0% brightness and fully black color, to conserve power but still accept input

At any input, the screen brightness is restored, and the current state machine is visible. It stays visible for a few seconds

Input 7, since it does nothing, it shows the initial scren of the state machine

