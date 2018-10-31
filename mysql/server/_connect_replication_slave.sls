{%- from "mysql/map.jinja" import server with context %}
{%- set master_status = salt['mine.get'](server.replication.master, 'mysql.get_master_status').get(server.replication.master, {}) %}

{%- set master_host = salt['mine.get'](server.replication.master, 'network.interfaces')[server.replication.master] %}

/tmp/get_slave_status:
  file.managed:
  - contents: {{ master_status }}

{%- set setup_replication_query = "CHANGE MASTER TO MASTER_HOST='" + server.replication.master_address + "', MASTER_USER='" + server.replication.user + "', MASTER_PASSWORD='" + server.replication.password + "', MASTER_LOG_FILE='" + master_status.get('File', 'mysql-bin.000001') + "', MASTER_LOG_POS=" + master_status.get('Position', '1')|string %}

{%- if server.ssl.enabled %}
  {%- set ssl_opts = ", MASTER_SSL=1, MASTER_SSL_CA='" + server.ssl.ca_file + "', MASTER_SSL_CERT='" + server.ssl.client_cert_file + "', MASTER_SSL_KEY='" + server.ssl.client_key_file + "'" %}
{%- else %}
  {%- set ssl_opts = ", MASTER_SSL=0" %}
{%- endif %}

{%- if salt['mysql.query'] is defined %}

{%- set setup_replication_result = salt['mysql.query']('mysql', setup_replication_query + ssl_opts + "; START SLAVE;") %}

{%- endif %}
