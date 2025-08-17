Docker container for building FujiNet software, including firmware, libraries, applications.

[Available on Docker hub](https://hub.docker.com/repository/docker/fozztexx/defoogi):

  `docker pull fozztexx/defoogi`

Compilers included:

  * cc65
  * cmoc
  * open watcom

To use:

  * cd into the directory with the FujiNet software you want to build
  * prefix your build commands with `defoogi`:
    * `defoogi make`
