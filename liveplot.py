# python_live_plot.py
# taken from a webpage 2022

import pandas as pd
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation

plt.style.use('fivethirtyeight')

x_values = []
y_values = []



def animate(i):
    data = pd.read_csv('flightlog_f9_west.csv')
    x_values = data['time']
    y_values = data['gheight']
    plt.cla()
    plt.plot(x_values, y_values)
    plt.xlabel('time [s]')
    plt.ylabel('Ground Height [m]')
    plt.title('Flight Info')
    plt.gcf().autofmt_xdate()
    plt.tight_layout()

ani = FuncAnimation(plt.gcf(), animate, 5000)

plt.tight_layout()
plt.show()