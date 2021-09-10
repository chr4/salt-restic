/usr/local/bin/restic-monit:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - source: salt://{{ tpldir }}/restic-monit.jinja
    - template: jinja
    - defaults:
      max_backup_age: {{ pillar['restic']['max_backup_age']|default(172800) }}
