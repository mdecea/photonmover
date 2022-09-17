import sys
import struct
import matplotlib.pyplot as pyplot
import time
import matplotlib.animation as animation
import math
import numpy as np
import photonmover.instruments.Temperature_controllers.Lakeshore331S as Lakeshore331S
import photonmover.instruments.Pressure_sensors.KJLKPDR900 as KJLKPDR900


# This script plots temperature and pressure of the cryo chamber. It also logs the data in the specified file.
MIN_TO_PLOT = 30  # Min to plot on the graphs
REFRESH_RATE = 2000  # In miliseconds
PRESSURE_SKIP = 1  # Getting pressure takes an awfully long time, so we will only ask for it every X cycles.
LOG_FILE = 'cryo_log.txt'  # Name of the log file

x_axis_min_width = 5  # The minimum width of the time axis


class CryoHub:
    """ Class that will sets up the GUI for showing the relevant variables"""

    def __init__(self, fig, gen, min_to_plot=60):

        self.start_idx = 0
        self.t = []

        # Two graphs, one for temperature and one for pressure
        self.rad_shield_temp = []
        self.cold_head_temp = []
        self.pressure = []

        self.fig = fig
        self.gen = gen
        self.min_to_plot = min_to_plot
        self.t_start = None

        self.temp_text = pyplot.figtext(.87, 0.85 - 0.1, '', fontsize=15, color='white')
        self.press_text = pyplot.figtext(.87, 0.85 - 0.55, '', fontsize=15, color='white')

        fig.patch.set_facecolor('black')

        self.ax1 = self.fig.add_subplot(2, 1, 1, facecolor='black')
        self.ax2 = self.fig.add_subplot(2, 1, 2, facecolor='black')

        pyplot.subplots_adjust(left=0.08, bottom=0.10, right=0.85, top=0.95, wspace=0.05, hspace=0.05)

        self.rs_line = self.ax1.plot([0], [0], 'r-', animated=False, label='Rad. shield')[0]
        self.ch_line = self.ax1.plot([0], [0], 'w-', animated=False, label='Cold head')[0]
        self.ax1.legend()
        self.p_line = self.ax2.plot([0], [0], 'w-', animated=False)[0]

        self.format_axis(self.ax1, 'yellow', 'Time [min]', True, 'green', 'Temperature [K]', True)
        self.format_axis(self.ax2, 'yellow', 'Time [min]', True, 'red', 'Pressure [torr]', True)
        self.ax2.set_yscale('symlog')

    def format_axis(self, ax, xcolor, xlabel, xticklabels, ycolor, ylabel, yticklabels):
        ax.spines['bottom'].set_color(xcolor)
        ax.spines['top'].set_color(xcolor)
        ax.spines['right'].set_color(ycolor)
        ax.spines['left'].set_color(ycolor)
        ax.xaxis.set_tick_params(labelcolor=xcolor, color=xcolor)
        ax.yaxis.set_tick_params(labelcolor=ycolor, color=ycolor)
        ax.set_ylim(0, 1)
        ax.set_xlim(0, x_axis_min_width)
        ax.set_xlabel(xlabel, color=xcolor)
        ax.set_ylabel(ylabel, color=ycolor)
        if not xticklabels:
            ax.set_xticklabels([])
        if not yticklabels:
            ax.set_yticklabels([])

    def animate(self, data):

        new_t = (time.time() - self.t_start) / 60  # This is in minutes
        new_temp_rad_shield = data[0]
        new_temp_cold_head = data[1]
        new_pressure = data[2]

        self.t.append(new_t)
        self.rad_shield_temp.append(new_temp_rad_shield)
        self.cold_head_temp.append(new_temp_cold_head)
        if new_pressure < 1e5:
            self.pressure.append(new_pressure)
        else:
            self.pressure.append(self.pressure[-1])

        # Change axis if necessary
        rs_max = max(self.rad_shield_temp)
        rs_min = min(self.rad_shield_temp)
        ch_max = max(self.cold_head_temp)
        ch_min = min(self.cold_head_temp)
        ax1_max = max(rs_max, ch_max)
        ax1_min = min(rs_min, ch_min)
        self.ax1.set_ylim(ax1_min - abs(ax1_min * 0.1), ax1_max + abs(ax1_max * 0.1))

        p_max = max(self.pressure)
        p_min = min(self.pressure)
        self.ax2.set_ylim(p_min - abs(p_min * 0.1), p_max + abs(p_max * 0.1))

        t_max = new_t
        t_cutoff = t_max - self.min_to_plot

        if t_max < self.min_to_plot:
            x_lim = max(x_axis_min_width, t_max)
        else:
            x_lim = max(t_max, self.min_to_plot)
        self.ax1.set_xlim(max(t_cutoff, 0), x_lim)
        self.ax2.set_xlim(max(t_cutoff, 0), x_lim)

        while self.t[0] < t_cutoff:
            self.t.pop(0)
            self.rad_shield_temp.pop(0)
            self.cold_head_temp.pop(0)
            self.pressure.pop(0)

        self.rs_line.set_xdata(self.t)
        self.rs_line.set_ydata(self.rad_shield_temp)
        self.ch_line.set_xdata(self.t)
        self.ch_line.set_ydata(self.cold_head_temp)
        self.p_line.set_xdata(self.t)
        self.p_line.set_ydata(self.pressure)

        self.temp_text.set_text("C.H: %.2f K \nR.S: %.2f K" % (new_temp_cold_head, new_temp_rad_shield))
        if new_pressure<1e5:
            self.press_text.set_text("%.2e Torr" % new_pressure)
        else:
            self.press_text.set_text("Press. read error")

        return [self.rs_line, self.ch_line, self.p_line]

    def start_animation(self):
        self.t_start = time.time()

        # Start the animation
        anim = animation.FuncAnimation(self.fig, self.animate, self.gen, interval=REFRESH_RATE, blit=False)
        pyplot.show()


def return_status():
    while True:
        yield (get_status())


def get_status():
    global num_cycles, prev_p, ps, tec

    if num_cycles == PRESSURE_SKIP:
        p = ps.get_pressure()
        num_cycles = 0
        prev_p = p
    else:
        p = prev_p
        num_cycles = num_cycles + 1

    temps = tec.get_temperature()
    time_tuple = time.localtime()
    with open(LOG_FILE, 'a+') as f:
        f.write("%d#%d#%d %d#%d#%d       |      %.2f             |     %.2f            |    %.2e      \n"
                % (time_tuple[0],
                  time_tuple[1],
                  time_tuple[2],
                  time_tuple[3],
                  time_tuple[4],
                  time_tuple[5],
                  temps[0],
                  temps[1],
                  p))
    # p = 0
    return [temps[0], temps[1], p]


# Connect and initialize instruments
ps = KJLKPDR900.KJLKPDR900()
ps.initialize()
tec = Lakeshore331S.Lakeshore331S()
tec.initialize()
time.sleep(1)

cooldown_id = input('Enter cooldown ID for the log:')

prev_p = 0
num_cycles = PRESSURE_SKIP

with open(LOG_FILE, 'a+') as f:
    time_tuple = time.localtime()
    f.write("------------------------------------------------------------------------\n")
    f.write("Starting new cryo hub execution. Date is %d#%d#%d %d#%d#%d\n " % (time_tuple[0],
                                                                          time_tuple[1],
                                                                          time_tuple[2],
                                                                          time_tuple[3],
                                                                          time_tuple[4],
                                                                          time_tuple[5]))
    f.write("ID %s \n" % cooldown_id)
    f.write("   Time                     Rad shield (K)           Cold head (K)               Pressure (Torr)\n")
    f.write("   ----                    ----------------         ---------------             -----------------\n")


# Start plotting
fig1 = pyplot.figure(figsize=(12, 6))
blah = CryoHub(fig1, return_status(), MIN_TO_PLOT)
blah.start_animation()
