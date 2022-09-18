import nidaqmx
import matplotlib.pyplot as plt
import sys
import numpy as np

data_0 = list()
data_1 = list()

AIN_RECEIVED = "/Dev1/ai0"  # Analog signal corresponding to the received power
AIN_TAP = "/Dev1/ai1"  # Analog signal corresponding to the tap power
PFI_CLK = "/Dev1/pfi0"  # Trigger coming from the laser

for i in [1]:

    with nidaqmx.Task() as task:

        init_wav = 1520.0
        end_wav = 1580.0
        step_wav = 0.1993
        num_points = round(((end_wav - init_wav) / step_wav + 1))
        task.ai_channels.add_ai_voltage_chan(
            AIN_RECEIVED, min_val=0, max_val=2.0)
        task.ai_channels.add_ai_voltage_chan(AIN_TAP, min_val=0, max_val=2.0)

        task.timing.cfg_samp_clk_timing(
            500,
            source=PFI_CLK,
            active_edge=nidaqmx.constants.Edge.FALLING,
            samps_per_chan=num_points)

        print('acq started')
        sys.stdout.flush()
        task.start()
        task.wait_until_done(timeout=50)
        data = task.read(number_of_samples_per_channel=num_points)
        data_0.append(data[0])
        data_1.append(data[1])
        print(data)

plt.plot(np.linspace(init_wav, end_wav, num_points), data_0[0], 'o-')
#plt.plot(np.linspace(init_wav, end_wav, num_points), data_0[1], 'o-')
#plt.plot(np.linspace(init_wav, end_wav, num_points), data_0[2], 'o-')
#plt.plot(np.linspace(init_wav, end_wav, num_points), data_0[3], 'o-')
plt.plot(np.linspace(init_wav, end_wav, num_points), data_1[0], 'o-')
#plt.plot(np.linspace(init_wav, end_wav, num_points), data_1[1], 'o-')
#plt.plot(np.linspace(init_wav, end_wav, num_points), data_1[2], 'o-')
#plt.plot(np.linspace(init_wav, end_wav, num_points), data_1[3], 'o-')

plt.show()
