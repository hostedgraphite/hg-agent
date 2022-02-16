collectors = ['cpu',
              'diskspace',
              'diskusage',
              'files',
              'loadavg',
              'memory',
              'network',
              'sockstat',
              'vmstat',
              'mongodb']

collector_path = '/hg-agent.venv/share/diamond/collectors/%s/%s.py'
collector_srcs = [collector_path % (c, c) for c in collectors]

# Add local / custom collectors
collector_srcs.append('/hg-agent/collectors/self/self.py')

analysis_paths = (['/hg-agent/hg_agent_switch'] + collector_srcs)

a = Analysis(analysis_paths,
             pathex=[],
             binaries=None,
             datas=[
                 # supervisor expects to find its version.txt, so we have to copy explicitly.
                 ('/hg-agent.venv/lib/python3/site-packages/supervisor/version.txt', 'supervisor'),

                 # the jinja2 template for hg-agent-periodic
                 ('/hg-agent.venv/lib/python3/site-packages/hg_agent_periodic/templates', 'hg_agent_periodic/templates')
             ],
             hiddenimports=['diamond.handler.archive',
                            'diamond.handler.hostedgraphite',
                            'diamond.handler.queue'],
             hookspath=[],
             runtime_hooks=[],
             excludes=[],
             win_no_prefer_redirects=False,
             win_private_assemblies=False,
             cipher=None)

pyz = PYZ(a.pure, a.zipped_data, cipher=None)

exe = EXE(pyz,
          a.scripts,
          exclude_binaries=True,
          name='binary',
          debug=False,
          strip=True,
          upx=True,
          console=True)

coll = COLLECT(exe,
               a.binaries,
               a.zipfiles,
               a.datas,
               strip=True,
               upx=True,
               name='package')
