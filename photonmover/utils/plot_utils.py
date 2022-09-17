import numpy as np
import matplotlib.axes

import pyqtgraph as pg

# List of colors for when we plot multiple lines in the same plot
COLOR_LIST = [(255, 0, 0), # r
              (0, 255, 0), # g
              (0, 0, 255), # b
              (255, 255, 255), # w
              (255, 140, 0), ] # orange


def filter_nans(x_data, y_data):
    """
    Filters the nans in x_data and y_data.
    """

    # Filter nans because if there is one, then the plot does not show anything
    inds = np.argwhere(np.isnan(x_data))
    x_data = np.delete(x_data, inds)
    y_data = np.delete(y_data, inds)
    inds = np.argwhere(np.isnan(y_data))
    x_data = np.delete(x_data, inds)
    y_data = np.delete(y_data, inds)

    return x_data, y_data


def plot_graph(x_data, y_data, canvas_handle, xlabel=None, ylabel=None, title=None, legend=None):
    """
    Plots the data given the parameters above. The main purpose of this function is to figure out
    if we want to plot this in a matplotlib figure or a PyQt widget, and act accordingly
    """

    y_data = np.array(y_data)

    if isinstance(canvas_handle, matplotlib.axes.Axes):
        # Matplotlib axis

        if len(np.shape(y_data)) > 1:
            # There is more than one y_data line
            for l in range(np.shape(y_data)[0]):
                canvas_handle.plot(x_data, y_data[l, :], linewidth=3)
        else:
            canvas_handle.plot(x_data, y_data, 'k', linewidth=3)

        if xlabel is not None:
            canvas_handle.set_xlabel(xlabel, fontsize=20)
        if ylabel is not None:
            canvas_handle.set_ylabel(ylabel, fontsize=20)
        if title is not None:
            canvas_handle.set_title(title, fontsize=20)    
        if legend is not None:
            canvas_handle.legend(legend)

    else:
        # PyQtGraph widget

        # addLegend has to be called before plot commands (if exists)
        if legend is not None:
            canvas_handle.addLegend()

        canvas_handle.clear()

        if len(np.shape(y_data)) > 1:
            # There is more than one y_data line
            for i in range(np.shape(y_data)[0]):
                pen = pg.mkPen(color=COLOR_LIST[i], width=5)
                x_dat, y_dat = filter_nans(x_data, y_data[i, :])

                if legend is not None:
                    canvas_handle.plot(x_dat, y_dat, name=legend[i], pen=pen)
                else:
                    canvas_handle.plot(x_dat, y_dat, pen=pen)


        else:
            pen = pg.mkPen(color=COLOR_LIST[0], width=3)
            # Remove nans, because if not the PyQtWidge shows nothing
            x_data, y_data = filter_nans(x_data, y_data)
            canvas_handle.plot(x_data, y_data, pen=pen)


        if xlabel is not None:
            canvas_handle.setLabel('bottom', text=xlabel)
        if ylabel is not None:
            canvas_handle.setLabel('left', text=ylabel)

        if title is not None:
            canvas_handle.setTitle(title, size='20pt')
        else:
            canvas_handle.setTitle('', size='20pt')