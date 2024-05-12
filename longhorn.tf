resource "kubectl_manifest" "longhorn_metrics" {
  count     = var.prometheus_monitoring ? 1 : 0
  yaml_body = <<YAML
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: longhorn-prometheus-servicemonitor
  namespace: longhorn-system
  labels:
    name: longhorn-prometheus-servicemonitor
spec:
  selector:
    matchLabels:
      app: longhorn-manager
  namespaceSelector:
    matchNames:
    - longhorn-system
  endpoints:
  - port: manager
YAML
}


resource "kubectl_manifest" "raid_disks" {
  yaml_body = <<YAML
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: raid-disks
  namespace: ${kubernetes_namespace.longhorn-system.metadata[0].name}
  labels:
    k8s-app: raid-disks
spec:
  selector:
    matchLabels:
      name: raid-disks
  template:
    metadata:
      labels:
        name: raid-disks
    spec:
      nodeSelector:
        kubernetes.io/hostname=seattle
      hostPID: true
      tolerations:
      - key: "" # FIXME
        operator: "Equal"
        value: "storage"
        effect: "NoSchedule"
      containers:
      - name: startup-script
        image: # FIXME
        securityContext:
          privileged: true
        env:
        - name: STARTUP_SCRIPT
          value: |
            set -o errexit
            set -o nounset
            set -o pipefail

            devices=()
            for ssd in /dev/disk/by-id/# FIXME *; do
              if [ -e "$${ssd}" ]; then
                devices+=("$${ssd}")
              fi
            done
            if [ "$${#devices[@]}" -eq 0 ]; then
              echo "No Local NVMe SSD disks found."
              exit 0
            fi

            seen_arrays=(/dev/md/*)
            device=$${seen_arrays[0]}
            echo "Setting RAID array with Local SSDs on device $${device}"
            if [ ! -e "$device" ]; then
              device="/dev/md/0"
              echo "y" | mdadm --create "$${device}" --level=0 --force --raid-devices=$${#devices[@]} "$${devices[@]}"
            fi

            if ! tune2fs -l "$${device}" ; then
              echo "Formatting '$${device}'"
              mkfs.ext4 -F "$${device}"
            fi

            mountpoint=/mnt/disks/raid/0
            mkdir -p "$${mountpoint}"
            echo "Mounting '$${device}' at '$${mountpoint}'"
            mount -o discard,defaults "$${device}" "$${mountpoint}"
            chmod a+w "$${mountpoint}"
YAML

}

resource "kubectl_manifest" "longhorn_priority_class" {
  yaml_body = <<YAML
apiVersion: scheduling.k8s.io/v1
kind: PriorityClass
metadata:
  name: custom-node-critical
value: 1000000000
globalDefault: false
description: "Custom PriorityClass for longhorn pods"
YAML
}

