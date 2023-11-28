# syntax=docker/dockerfile:1
FROM archlinux:base-devel
COPY overlay /
CMD bash -i