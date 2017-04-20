'''
A Diamond collector that aggregates resource usage of each process belonging to
the `hg-agent` user.
'''

import diamond.collector
import psutil


def get_usage_for_username(username):
    '''Fetch CPU and memory usage totals for `username`.
    Returns:
        {'user':   total user time in seconds,
         'system': total system time in seconds,
         'res':    total resident memory in bytes,
         'virt':   total virtual memory in bytes,
         'shr':    total shared memory in bytes}
    '''
    cpu_times = []
    memory_info = []
    for process in psutil.process_iter():
        with process.oneshot():
            if process.username() == username:
                cpu_times.append(process.cpu_times())
                memory_info.append(process.memory_info())
    return {'user': sum([c.user for c in cpu_times]),
            'system': sum([c.system for c in cpu_times]),
            'res': sum([m.rss for m in memory_info]),
            'virt': sum([m.vms for m in memory_info]),
            'shr': sum([m.shared for m in memory_info])}


class SelfCollector(diamond.collector.Collector):

    def get_default_config(self):
        """
        Returns the default collector settings
        """
        config = super(SelfCollector, self).get_default_config()
        config.update({
            'path': 'self'
        })
        return config


    def collect(self):
        '''
        Locate processes running as user `hg-agent` & publish total resources.
        '''
        try:
            usage = get_usage_for_username('hg-agent')
        except psutil.Error as e:
            self.log.error('Fetching process information: %s', e)
            return

        for field in ['user', 'system']:
            self.publish(field, usage[field], precision=2)

        for field in ['res', 'virt', 'shr']:
            self.publish(field, usage[field])
