# -*- coding: utf-8 -*-
# vim: ft=sls
{% from "lvm/map.jinja" import lvm with context %}
{% from "lvm/templates/macros.jinja" import getopts with context %}
{% from "lvm/templates/macros.jinja" import getlist with context %}

{%- if lvm.lv and "create" in lvm.lv and lvm.lv.create is mapping %}
  {% for lv, lvdata in lvm.lv.create.items() %}

    {%- if lvdata and 'snapshot' in lvdata and lvdata['snapshot'] == True %}
      {# workaround https://github.com/saltstack/salt/issues/48808 #}

lvm_lv_create_{{ lv }}:
  cmd.run:
    - name: |
        lvcreate --yes {{- getopts(lvdata) }} \
                 --name {{ lvdata['vgname'] }}/{{ lv }} \
                 --snapshot {{ lvdata['sourcelv'] }} {{- getlist(lvdata['devices']) if 'devices' in lvdata else '' }}
    - unless: lvdisplay {{ lvdata['vgname'] }}/{{ lv }} 2>/dev/null
    - onlyif: lvdisplay {{ lvdata['vgname'] }}/{{ lvdata['sourcelv'] }} 2>/dev/null
    #force??

    {%- else %}

       {%- if lvm.kmodules %}
## load kernel module if needed ##
lvm_lv_create_{{ lv }}_kernel_modules:
  kmod.present:
    - names: {{ lvm.kmodules|json  }}
    - onlyif: {{ 'thinvolume' in lvdata or 'thinpool' in lvdata }}

       {%- endif %}

lvm_lv_create_{{ lv }}:
  lvm.lv_present:
    - name: {{ lv }}
    - vgname: {{ lvdata['vgname'] }}
    {{ '- devices: ' ~ lvdata['devices'] if 'devices' in lvdata else '' }}
    {{ '- size: ' ~ lvdata['size'] if 'size' in lvdata else '' }}
    {{ '- pv: ' ~ lvdata['pv'] if 'pv' in lvdata else '' }}
    {{ '- force: ' ~ lvdata['force'] if 'force' in lvdata else '' }}
    {{ '- thinvolume: ' ~ lvdata['thinvolume'] if 'thinvolume' in lvdata else '' }}
    {{ '- thinpool: ' ~ lvdata['thinpool'] if 'thinpool' in lvdata else '' }}
    {{ getopts(lvdata, True) }}

    {%- endif %}
    - unless: lvdisplay {{ lv }} 2>/dev/null || lvdisplay {{ lvdata['vgname'] }}/{{ lv }} 2>/dev/null
  {%- endfor %}
{%- else %}

lvm_lv_create_nothing_to_do:
  test.show_notification:
    - text: |
        No "lv.create" pillar data supplied {{ lvm }} - nothing to do!

{%- endif %}
