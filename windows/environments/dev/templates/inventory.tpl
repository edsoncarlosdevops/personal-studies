---
all:
  children:
    windows_workstations:
      hosts:
%{ for i, ip in workstation_ips ~}
        WORKSTATION-${format("%02d", i + 1)}:
          ansible_host: ${ip}
%{ endfor ~}
