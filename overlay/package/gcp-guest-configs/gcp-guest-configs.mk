GCP_GUEST_CONFIGS_VERSION = 20221110.00 
GCP_GUEST_CONFIGS_SOURCE = $(GCP_GUEST_CONFIGS_VERSION).tar.gz
GCP_GUEST_CONFIGS_SITE = https://github.com/GoogleCloudPlatform/guest-configs/archive/refs/tags

define GCP_GUEST_CONFIGS_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/src/lib/udev/rules.d/65-gce-disk-naming.rules \
		$(TARGET_DIR)/etc/udev/rules.d/01-gce-disk-naming.rules
	$(INSTALL) -D -m 0755 $(GCP_GUEST_CONFIGS_PKGDIR)/gcp_nvme_id.sh $(TARGET_DIR)/usr/local/bin/gcp_nvme_id.sh
endef

$(eval $(generic-package))
