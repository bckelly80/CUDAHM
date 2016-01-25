import numpy as np
from matplotlib.pyplot import *

execfile("rc_settings.py")

performance_iter_vs_time_data_10000_with_fl=np.loadtxt('performance_iter_vs_time_data_10000_with_fl.dat',delimiter=' ',usecols=(0,1))
performance_iter_vs_time_data_100000_with_fl=np.loadtxt('performance_iter_vs_time_data_100000_with_fl.dat',delimiter=' ',usecols=(0,1))
performance_iter_vs_time_data_300000_with_fl=np.loadtxt('performance_iter_vs_time_data_300000_with_fl.dat',delimiter=' ',usecols=(0,1))

fig = figure()

ax = fig.add_subplot(1,1,1, xlim=[0, 1010000], ylim=[0, 60]) # one row, one column, first plot
ax.scatter(performance_iter_vs_time_data_10000_with_fl[:,0], performance_iter_vs_time_data_10000_with_fl[:,1], color ='b', marker = "o", s = 15, label = '10000 obj')
ax.plot(performance_iter_vs_time_data_10000_with_fl[:,0], performance_iter_vs_time_data_10000_with_fl[:,1], 'b--')
ax.scatter(performance_iter_vs_time_data_100000_with_fl[:,0], performance_iter_vs_time_data_100000_with_fl[:,1], color ='g', marker = "o", s = 15, label = '100000 obj')
ax.plot(performance_iter_vs_time_data_100000_with_fl[:,0], performance_iter_vs_time_data_100000_with_fl[:,1], 'g--')
ax.scatter(performance_iter_vs_time_data_300000_with_fl[:,0], performance_iter_vs_time_data_300000_with_fl[:,1], color ='r', marker = "o", s = 15, label = '300000 obj')
ax.plot(performance_iter_vs_time_data_300000_with_fl[:,0], performance_iter_vs_time_data_300000_with_fl[:,1], 'r--')

ax.set_xlabel('Iteration numbers')
ax.set_ylabel('Elapsed time (min)')
ax.legend(loc=2)

savefig('performance_iter_vs_time.pdf', format='pdf')

performance_obj_vs_time_data_10000_with_fl=np.loadtxt('performance_obj_vs_time_data_10000_with_fl.dat',delimiter=' ',usecols=(0,1))
performance_obj_vs_time_data_100000_with_fl=np.loadtxt('performance_obj_vs_time_data_100000_with_fl.dat',delimiter=' ',usecols=(0,1))
performance_obj_vs_time_data_200000_with_fl=np.loadtxt('performance_obj_vs_time_data_200000_with_fl.dat',delimiter=' ',usecols=(0,1))
performance_obj_vs_time_data_500000_with_fl=np.loadtxt('performance_obj_vs_time_data_500000_with_fl.dat',delimiter=' ',usecols=(0,1))
performance_obj_vs_time_data_1000000_with_fl=np.loadtxt('performance_obj_vs_time_data_1000000_with_fl.dat',delimiter=' ',usecols=(0,1))

fig = figure()

ax = fig.add_subplot(1,1,1, xlim=[0, 303000], ylim=[0, 60]) # one row, one column, first plot
ax.scatter(performance_obj_vs_time_data_10000_with_fl[:,0], performance_obj_vs_time_data_10000_with_fl[:,1], color = 'b', marker = "o", s = 15, label = '10000 iter')
ax.plot(performance_obj_vs_time_data_10000_with_fl[:,0], performance_obj_vs_time_data_10000_with_fl[:,1], 'b--')
ax.scatter(performance_obj_vs_time_data_100000_with_fl[:,0], performance_obj_vs_time_data_100000_with_fl[:,1], color = 'g', marker = "o", s = 15, label = '100000 iter')
ax.plot(performance_obj_vs_time_data_100000_with_fl[:,0], performance_obj_vs_time_data_100000_with_fl[:,1], 'g--')
ax.scatter(performance_obj_vs_time_data_200000_with_fl[:,0], performance_obj_vs_time_data_200000_with_fl[:,1], color = 'r', marker = "o", s = 15, label = '200000 iter')
ax.plot(performance_obj_vs_time_data_200000_with_fl[:,0], performance_obj_vs_time_data_200000_with_fl[:,1], 'r--')
ax.scatter(performance_obj_vs_time_data_500000_with_fl[:,0], performance_obj_vs_time_data_500000_with_fl[:,1], color = 'y', marker = "o", s = 15, label = '500000 iter')
ax.plot(performance_obj_vs_time_data_500000_with_fl[:,0], performance_obj_vs_time_data_500000_with_fl[:,1], 'y--')
ax.scatter(performance_obj_vs_time_data_1000000_with_fl[:,0], performance_obj_vs_time_data_1000000_with_fl[:,1], color = 'm', marker = "o", s = 15, label = '1000000 iter')
ax.plot(performance_obj_vs_time_data_1000000_with_fl[:,0], performance_obj_vs_time_data_1000000_with_fl[:,1], 'm--')

ax.set_xlabel('Object numbers')
ax.set_ylabel('Elapsed time (min)')
ax.legend(loc=0)

savefig('performance_obj_vs_time.pdf', format='pdf')