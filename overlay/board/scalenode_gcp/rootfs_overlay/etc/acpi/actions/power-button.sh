result=$(curl "http://metadata.google.internal/computeMetadata/v1/instance/preempted" -H "Metadata-Flavor: Google")
exit_code=$?
logger "VM shutting down! Checking if an instance was preempted: $result (exit code: $exit_code)"

/sbin/poweroff
