restic:
  pkg.installed: []

# Deploy SSH keys
{% if pillar['restic']['ssh'] is defined %}
/root/.ssh:
  file.directory:
    - user: root
    - group: root
    - mode: 755

# Append server to ssh_known_hosts
{% if pillar['restic']['ssh']['known_hosts'] is defined %}
ssh-keyscan {{ pillar['restic']['ssh']['known_hosts'] }} >> /etc/ssh/ssh_known_hosts:
  cmd.run:
    - unless: grep -q {{ pillar['restic']['ssh']['known_hosts'] }} /etc/ssh/ssh_known_hosts
{% endif %}

{% for filename in pillar['restic']['ssh']['keys'].keys() %}
/root/.ssh/{{ filename }}:
  file.managed:
    - user: root
    - group: root
    - mode: 600
    - contents_pillar: restic:ssh:keys:{{ filename }}
{% endfor %}
{% endif %}

# Deploy scripts
/usr/local/bin/restic-exec:
  file.managed:
    - user: root
    - group: root
    - mode: 700
    - source: salt://{{ tpldir }}/restic-exec.jinja
    - template: jinja
    - defaults:
      aws_access_key_id: {{ pillar['restic']['aws_access_key_id']|default() }}
      aws_secret_access_key: {{ pillar['restic']['aws_secret_access_key']|default() }}
      password: {{ pillar['restic']['password'] }}
      repository: {{ pillar['restic']['repository'] }}
      cache_dir: {{ pillar['restic']['cache_dir']|default('/root/.cache/restic') }}

/usr/local/bin/restic-take-backup:
  file.managed:
    - user: root
    - group: root
    - mode: 755
    - source: salt://{{ tpldir }}/restic-take-backup.jinja
    - template: jinja
    - defaults:
      keep: {{ pillar['restic']['keep']|default({}) }}
      directories: {{ salt['pillar.get']('restic:directories', ['/etc', '/root']) }}
      exec_pre: {{ pillar['restic']['exec_pre']|default([]) }}
      exec_post: {{ pillar['restic']['exec_post']|default([]) }}
      verify: {{ pillar['restic']['verify']|default(true) }}

# Install systemd timer and service
/lib/systemd/system/restic.service:
  file.managed:
    - source: salt://{{ tpldir }}/restic.service.jinja
    - template: jinja
    - defaults:
      nice: {{ pillar['restic']['nice']|default('10') }}
      io_scheduling_class: {{ pillar['restic']['io_scheduling_class']|default('2') }}
      io_scheduling_priority: {{ pillar['restic']['io_scheduling_priority']|default('7') }}
    - user: root
    - group: root
    - mode: 644
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: /lib/systemd/system/restic.service

restic.timer:
  service.running:
    - enable: true
    - watch:
      - file: /lib/systemd/system/restic.timer
    - require:
      - file: /lib/systemd/system/restic.timer
      - cmd: systemctl daemon-reload
  file.managed:
    - name: /lib/systemd/system/restic.timer
    - source: salt://{{ tpldir }}/restic.timer.jinja
    - template: jinja
    - defaults:
      # Escape on_calendar, as e.g. 23:00 is parsed as 1380 otherwise
      on_calendar: "{{ pillar['restic']['on_calendar']|default('02:00') }}"
    - user: root
    - group: root
    - mode: 644
  cmd.run:
    - name: systemctl daemon-reload
    - onchanges:
      - file: /lib/systemd/system/restic.timer
