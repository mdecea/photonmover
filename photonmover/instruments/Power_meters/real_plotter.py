import matplotlib.pyplot as p
import matplotlib.animation as animation
import time


# This class plots in real time the power measured by a power meter

class RealPlotter:

    def __init__(self, fig, gen, seconds_to_plot=60):

        self.start_idx = 0
        self.t = []
        self.y1 = []
        self.y1_lim = []
        self.y2 = []
        self.y2_lim = []
        self.y3 = []
        self.y3_lim = []
        self.y4 = []
        self.y4_lim = []
        self.fig = fig
        self.gen = gen
        self.seconds_to_plot = seconds_to_plot
        self.t_start = None

        self.curr_pow_text = []
        for i in range(4):
            self.curr_pow_text.append(
                p.figtext(.87, 0.85 - (0.85 / 4) * i, '', fontsize=15, color='white'))

        fig.patch.set_facecolor('black')

        self.ax1 = self.fig.add_subplot(4, 1, 1, facecolor='black')
        self.ax2 = self.fig.add_subplot(4, 1, 2, facecolor='black')
        self.ax3 = self.fig.add_subplot(4, 1, 3, facecolor='black')
        self.ax4 = self.fig.add_subplot(4, 1, 4, facecolor='black')

        p.subplots_adjust(
            left=0.08,
            bottom=0.10,
            right=0.85,
            top=0.95,
            wspace=0.05,
            hspace=0.05)

        self.line1 = self.ax1.plot([0], [0], 'w-', animated=False)[0]
        self.line2 = self.ax2.plot([0], [0], 'w-', animated=False)[0]
        self.line3 = self.ax3.plot([0], [0], 'w-', animated=False)[0]
        self.line4 = self.ax4.plot([0], [0], 'w-', animated=False)[0]

        self.format_axis(
            self.ax1,
            'yellow',
            '',
            False,
            'green',
            'Channel 1',
            True)
        self.format_axis(
            self.ax2,
            'yellow',
            '',
            False,
            'red',
            'Channel 2',
            True)
        self.format_axis(
            self.ax3,
            'yellow',
            '',
            False,
            'cyan',
            'Channel 3',
            True)
        self.format_axis(
            self.ax4,
            'yellow',
            'Time [s]',
            True,
            'magenta',
            'Channel 4',
            True)

    def format_axis(
            self,
            ax,
            xcolor,
            xlabel,
            xticklabels,
            ycolor,
            ylabel,
            yticklabels):
        ax.spines['bottom'].set_color(xcolor)
        ax.spines['top'].set_color(xcolor)
        ax.spines['right'].set_color(ycolor)
        ax.spines['left'].set_color(ycolor)
        ax.xaxis.set_tick_params(labelcolor=xcolor, color=xcolor)
        ax.yaxis.set_tick_params(labelcolor=ycolor, color=ycolor)
        ax.set_ylim(0, 1)
        ax.set_xlim(0, self.seconds_to_plot)
        ax.set_xlabel(xlabel, color=xcolor)
        ax.set_ylabel(ylabel, color=ycolor)
        if not xticklabels:
            ax.set_xticklabels([])
        if not yticklabels:
            ax.set_yticklabels([])

    def animate(self, data):

        new_t = time.time() - self.t_start
        new_y1 = data[0]
        new_y2 = data[1]
        new_y3 = data[2]
        new_y4 = data[3]

        self.t.append(new_t)
        self.y1.append(new_y1)
        self.y2.append(new_y2)
        self.y3.append(new_y3)
        self.y4.append(new_y4)

        # if new_y1 < self.ax1.get_ylim()[0]:
        # self.ax1.set_ylim(new_y1 - abs(new_y1 * 0.1), self.ax1.get_ylim()[1])
        # elif new_y1 > self.ax1.get_ylim()[1]:
        # self.ax1.set_ylim(self.ax1.get_ylim()[0], new_y1 + abs(new_y1 * 0.1))

        y1_max = max(self.y1)
        y1_min = min(self.y1)
        self.ax1.set_ylim(y1_min - abs(y1_min * 0.1),
                          y1_max + abs(y1_max * 0.1))

        # if new_y2 < self.ax2.get_ylim()[0]:
        # self.ax2.set_ylim(new_y2 - abs(new_y2 * 0.1), self.ax2.get_ylim()[1])
        # elif new_y2 > self.ax2.get_ylim()[1]:
        # self.ax2.set_ylim(self.ax2.get_ylim()[0], new_y2 + abs(new_y2 * 0.1))

        y2_max = max(self.y2)
        y2_min = min(self.y2)
        self.ax2.set_ylim(y2_min - abs(y2_min * 0.1),
                          y2_max + abs(y2_max * 0.1))

        # if new_y3 < self.ax3.get_ylim()[0]:
        # self.ax3.set_ylim(new_y3 - abs(new_y3 * 0.1), self.ax3.get_ylim()[1])
        # elif new_y3 > self.ax3.get_ylim()[1]:
        # self.ax3.set_ylim(self.ax3.get_ylim()[0], new_y3 + abs(new_y3 * 0.1))

        y3_max = max(self.y3)
        y3_min = min(self.y3)
        self.ax3.set_ylim(y3_min - abs(y3_min * 0.1),
                          y3_max + abs(y3_max * 0.1))

        # if new_y4 < self.ax4.get_ylim()[0]:
        # self.ax4.set_ylim(new_y4 - abs(new_y4 * 0.1), self.ax4.get_ylim()[1])
        # elif new_y4 > self.ax4.get_ylim()[1]:
        # self.ax4.set_ylim(self.ax4.get_ylim()[0], new_y4 + abs(new_y4 * 0.1))

        y4_max = max(self.y4)
        y4_min = min(self.y4)
        self.ax4.set_ylim(y4_min - abs(y4_min * 0.1),
                          y4_max + abs(y4_max * 0.1))

        t_max = new_t
        t_cutoff = t_max - self.seconds_to_plot

        self.ax1.set_xlim(max(t_cutoff, 0), max(t_max, self.seconds_to_plot))
        self.ax2.set_xlim(max(t_cutoff, 0), max(t_max, self.seconds_to_plot))
        self.ax3.set_xlim(max(t_cutoff, 0), max(t_max, self.seconds_to_plot))
        self.ax4.set_xlim(max(t_cutoff, 0), max(t_max, self.seconds_to_plot))

        while self.t[0] < t_cutoff:
            self.t.pop(0)
            self.y1.pop(0)
            self.y2.pop(0)
            self.y3.pop(0)
            self.y4.pop(0)

        self.line1.set_xdata(self.t)
        self.line1.set_ydata(self.y1)
        self.line2.set_xdata(self.t)
        self.line2.set_ydata(self.y2)
        self.line3.set_xdata(self.t)
        self.line3.set_ydata(self.y3)
        self.line4.set_xdata(self.t)
        self.line4.set_ydata(self.y4)

        self.curr_pow_text[0].set_text("%.3f dBm" % (new_y1))
        self.curr_pow_text[1].set_text("%.3f dBm" % (new_y2))
        self.curr_pow_text[2].set_text("%.3f dBm" % (new_y3))
        self.curr_pow_text[3].set_text("%.3f dBm" % (new_y4))

        return [self.line1, self.line2, self.line3, self.line4]

    def start_animation(self):
        self.t_start = time.time()

        # Start the animation
        anim = animation.FuncAnimation(
            self.fig, self.animate, self.gen, interval=1, blit=False)
        p.show()
