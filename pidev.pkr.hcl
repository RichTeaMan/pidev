locals {
  username  = "pidev"
  password  = "pidev"
  full_name = "pidev"
  hostname  = "pidev"

  ssid            = vault("/secret/data/access", "ssid")
  wifi_passphrase = vault("/secret/data/access", "wifi_passphrase")

  ssh            = vault("/secret/data/access", "ssh")
  ssh_pub        = vault("/secret/data/access", "ssh_pub")
  gpg            = vault("/secret/data/access", "gpg")
  git_email      = vault("/secret/data/access", "git_email")
  git_name       = vault("/secret/data/access", "git_name")
  git_signingkey = vault("/secret/data/access", "git_signingkey")
}

source "arm" "pidev" {
  file_urls         = ["https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-05-28/2021-05-07-raspios-buster-armhf-lite.zip"]
  file_checksum_url = "https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2021-05-28/2021-05-07-raspios-buster-armhf-lite.zip.sha256"

  file_checksum_type    = "sha256"
  file_target_extension = "zip"

  image_build_method = "resize"
  image_chroot_env   = ["PATH=/usr/local/bin:/usr/local/sbin:/usr/bin:/usr/sbin:/bin:/sbin"]
  image_partitions {
    filesystem   = "vfat"
    mountpoint   = "/boot"
    name         = "boot"
    size         = "256M"
    start_sector = "8192"
    type         = "c"
  }
  image_partitions {
    filesystem   = "ext4"
    mountpoint   = "/"
    name         = "root"
    size         = "0"
    start_sector = "532480"
    type         = "83"
  }
  image_path                   = "pidev.img"
  image_size                   = "28G"
  image_type                   = "dos"
  qemu_binary_destination_path = "/usr/bin/qemu-arm-static"
  qemu_binary_source_path      = "/usr/bin/qemu-arm-static"
}

build {
  sources = ["source.arm.pidev"]

  provisioner "shell" {
    inline = [
      # nodejs sources
      "curl -fsSL https://deb.nodesource.com/setup_current.x | bash -",

      "apt-get update",
      "apt-get upgrade -y",
      "apt-get install -y pigpio python-pigpio python3-pigpio nodejs make gcc g++ vim gnupg2 git"
    ]
  }
  provisioner "shell" {
    inline = [
      "adduser ${local.username} --disabled-password --gecos \"${local.full_name}\"",
      "adduser ${local.username} sudo",
      "echo \"${local.username}:${local.password}\" | chpasswd",
    ]
  }
  provisioner "file" {
    source      = "pidev-image-resources/"
    destination = "/tmp/"
  }
  provisioner "shell" {
    inline = [
      "sed -i 's/SSID/${local.ssid}/g' /tmp/wpa_supplicant.conf",
      "sed -i 's/WIFI_PASSPHRASE/${local.wifi_passphrase}/g' /tmp/wpa_supplicant.conf",
      "mv /tmp/wpa_supplicant.conf /etc/wpa_supplicant/wpa_supplicant.conf",
      "mv /tmp/dhcpcd.conf /etc/dhcpcd.conf",
      "echo ${local.hostname} > /etc/hostname",
      "echo \"127.0.0.1   ${local.hostname}\" >> /etc/hosts",

      "cp /tmp/rc.local /etc/rc.local",
      "systemctl enable ssh"
    ]
  }
  provisioner "shell" {
    inline = [
      "echo \"${local.ssh}\" | base64 -d > /tmp/id_ed25519",
      "echo \"${local.ssh_pub}\" | base64 -d > /tmp/id_ed25519.pub",

      "mkdir /home/${local.username}/.ssh",
      "mv /tmp/id_ed25519 /home/${local.username}/.ssh/.",
      "cp /tmp/id_ed25519.pub /home/${local.username}/.ssh/.",
      "mv /tmp/id_ed25519.pub /home/${local.username}/.ssh/authorized_keys",

      "chmod 700 /home/${local.username}/.ssh",
      "chmod 600 /home/${local.username}/.ssh/id_ed25519",
      "chmod 644 /home/${local.username}/.ssh/id_ed25519.pub",
      "chmod 600 /home/${local.username}/.ssh/authorized_keys",

      "chown ${local.username}:${local.username} /home/${local.username}/ -R",

      "echo \"${local.gpg}\" | base64 -d > /tmp/github-gpg.key",

      <<EOF
      su -l ${local.username} -c '
      gpg2 --import --batch /tmp/github-gpg.key &&
      git config --global user.name "${local.git_name}" &&
      git config --global user.email "${local.git_email}" &&
      git config --global gpg.program gpg2 &&
      git config --global user.signingkey ${local.git_signingkey} &&
      git config --global commit.gpgsign true &&
      git config --global core.editor vim &&
      echo "export GPG_TTY=\"\$(tty)\"" > ~/.bashrc'
      EOF
      ,
      "cat /home/${local.username}/.bashrc"
    ]
  }
}
