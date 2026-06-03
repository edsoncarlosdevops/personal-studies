---
all:
  children:
    windows_workstations:
      hosts:
%{ for i, ip in workstation_ips ~}
        WORKSTATION-${format("%02d", i + 1)}:
          ansible_host: ${ip}
%{ endfor ~}
      vars:
        ansible_user: .\Administrator
        ansible_password: ${admin_password}
        ansible_connection: winrm
        ansible_winrm_server_cert_validation: ignore
        ansible_winrm_transport: basic
