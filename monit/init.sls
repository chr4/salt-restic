/usr/local/bin/restic-monit:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - source: salt://{{ tpldir }}/restic-monit.jinja
    - template: jinja
    - defaults:
      aws_access_key_id: {{ pillar['restic']['aws_access_key_id']|default() }}
      aws_secret_access_key: {{ pillar['restic']['aws_secret_access_key']|default() }}
      password: {{ pillar['restic']['password'] }}
      repository: {{ pillar['restic']['repository'] }}
      cache_dir: {{ pillar['restic']['cache_dir']|default('/root/.cache/restic') }}
      max_backup_age: {{ pillar['restic']['max_backup_age']|default(172800) }}
