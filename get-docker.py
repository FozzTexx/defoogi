#!/usr/bin/env python3
import argparse
import requests
import csv
import os
import subprocess

OS_RELEASE = "/etc/os-release"
DOCKER_REPO_URL = "https://download.docker.com/linux"
DISTRO_INFO = "/usr/share/distro-info"
DOCKER_KEYRING_PATH = "/etc/apt/keyrings/docker.asc"
DOCKER_APT_LIST = "/etc/apt/sources.list.d/docker.list"

NETWORK_MANAGER_CONF = "/etc/NetworkManager/dnsmasq.d/docker-bridge.conf"

def build_argparser():
  parser = argparse.ArgumentParser(formatter_class=argparse.ArgumentDefaultsHelpFormatter)
  parser.add_argument("--flag", action="store_true", help="flag to do something")
  return parser

def load_os_release():
  data = {}
  try:
    with open(OS_RELEASE, "r") as f:
      for line in f:
        line = line.strip()
        if not line or line.startswith('#'):
          continue
        if '=' in line:
          key, value = line.split('=', 1)
          key = key.strip()
          value = value.strip()

          # Remove quotes from the value if they exist
          if len(value) > 1 and (value.startswith('"') and value.endswith('"') or \
                                 value.startswith("'") and value.endswith("'")):
            value = value[1:-1]

          data[key] = value

  except FileNotFoundError:
    return None
  return data

def check_distro_url(distro):
  distro_url = f"{DOCKER_REPO_URL}/{distro}"
  try:
    response = requests.head(distro_url, timeout=5)
    return response.status_code != 404
  except requests.exceptions.RequestException:
    pass
  return false

def remap_codename(distro, alt_distro, version):
  distro = distro.lower()
  alt_distro = alt_distro.lower()

  # is version a number? Then skip opening alt_distro .csv
  try:
    vnum = int(version)
  except ValueError:
    with open(os.path.join(DISTR_INFO, distro) + ".csv", "r") as f:
      distro_info = list(csv.reader(f))
    for row in distro_info[1:]:
      if row[2] == alt_distro:
        vnum = int(row[0])
        break

  # FIXME - is there a way to not have to maintain a list of distro names here?
  if distro == "devuan" and alt_distro == "debian":
    vnum += 7

  with open(os.path.join(DISTRO_INFO, alt_distro) + ".csv", "r") as f:
    distro_info = list(csv.reader(f))
  for row in distro_info[1:]:
    rnum = float(row[0])
    if rnum > vnum:
      break
    last_codename = row[2]

  return last_codename

def find_distro():
  dist_dict = load_os_release()
  distro = dist_dict['ID']
  alt_distro = dist_dict['ID_LIKE']
  codename = dist_dict['VERSION_CODENAME']
  if not check_distro_url(distro):
    # Docker isn't aware of our distro, can we use ID_LIKE instead?
    if not check_distro_url(alt_distro):
      raise ValueError("Unknown distro", distro, alt_distr)
    codename = remap_codename(distro, alt_distro, dist_dict.get('VERSION_ID', codename))
    distro = alt_distro

  print("Found distro:", distro, codename)
  return distro, codename

def write_file_as_root(path, contents):
  if not isinstance(contents, str):
    contents = contents.decode("utf-8")
  if contents[-1] != "\n":
    contents = contents + "\n"
  cmd = ["sudo", "tee", path]
  result = subprocess.run(cmd, input=contents, check=True, capture_output=True, text=True)
  return

def main():
  args = build_argparser().parse_args()

  # FIXME - is docker already installed?

  distro, codename = find_distro()
  result = subprocess.run(['dpkg', '--print-architecture'], capture_output=True,
                          text=True, check=True)
  pkg_arch = result.stdout.strip()

  # Add docker repo
  apt_repo = f"deb [arch={pkg_arch} signed-by=/etc/apt/keyrings/docker.asc]" \
    f" {DOCKER_REPO_URL}/{distro} {codename} stable"
  write_file_as_root(DOCKER_APT_LIST, apt_repo)

  docker_key_url = f"{DOCKER_REPO_URL}/{distro}/gpg"
  print(docker_key_url)

  # Add docker repo GPG keyring
  response = requests.get(docker_key_url, timeout=10)
  response.raise_for_status()
  write_file_as_root(DOCKER_KEYRING_PATH, response.content)

  cmd = ["sudo", "apt-get", "update"]
  subprocess.run(cmd, check=True)

  cmd = ["sudo", "apt-get", "install", "-y", "docker-ce", "docker-compose-plugin"]
  subprocess.run(cmd, check=True)

  # Add user to docker group
  cmd = ["sudo", "usermod", "-a", "-G", "docker",
         os.environ.get("SUDO_USER") or os.environ.get("USER")]
  subprocess.run(cmd, check=True)

  # If user was added to docker group tell them they need to log out and back in
  result = subprocess.run(["groups", ], capture_output=True, text=True, check=True)
  group_list = result.stdout.strip()
  if not "docker" in group_list:
    print()
    print("####################")
    print()
    print("You need to log out and back in so that your")
    print("user will be part of the docker group.")
    print()
    print("####################")
    print()

  return

if __name__ == "__main__":
  exit(main() or 0)
