echo
echo "this requires docker and docker buildx packages"
echo
echo "on arch: pacman -S docker docker-buildx"
echo
echo "on other, https://docs.docker.com/build/buildkit/"
echo
echo
echo "building via sudo"
echo

cat <<EOF > build_sudo_tmp.sh
CONTAINER=llvm_18_build_env_base

echo "using default builder"
docker buildx use default

if [[ \$? == 0 ]] ; then echo "building base image..." ; docker buildx build --output type=docker -t \$CONTAINER . ; else false; fi  # building an image for x86_64 and aarch64
if [[ \$? == 1 ]] ; then exit 1 ; fi

if [[ \$(docker container ls -a | grep -q "\$CONTAINER" ; echo \$?) == 0 ]]
    then
        echo "stopping existing base container"
        docker container stop \$CONTAINER
        echo "removing existing base container"
        docker container rm \$CONTAINER
    else
        true
fi

if [[ \$? == 0 ]] ; then echo "creating base container" ; docker container create --init --interactive --tty --tmpfs /tmp --ulimit nofile=262144:262144 --name \$CONTAINER \$CONTAINER ; else false; fi
if [[ \$? == 0 ]] ; then echo "starting base container"; docker container start \$CONTAINER ; else false; fi

if [[ \$? == 0 ]] ; then echo "creating user" ; echo "username: build" ; echo "password: build" ; docker container exec -it \$CONTAINER bash -i -c "useradd -ms /bin/bash build -p build" ; else false; fi
if [[ \$? == 0 ]] ; then docker container exec -it \$CONTAINER bash -i -c "echo \"build ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/build" ; else false; fi

if [[ \$? == 0 ]]
    then
        echo "saving base container to image..."
        docker container commit \$CONTAINER \$CONTAINER
    else
        false
fi

if [[ \$? == 0 ]]
    then
        echo "stopping existing base container"
        docker container stop \$CONTAINER
        echo "removing existing base container"
        docker container rm \$CONTAINER
    else
        false
fi
if [[ \$? == 0 ]] ; then echo "creating base container" ; docker container create --user build --workdir /home/build --init --interactive --tty --tmpfs /tmp --ulimit nofile=262144:262144 --name \$CONTAINER \$CONTAINER ; else false; fi
if [[ \$? == 0 ]] ; then echo "starting base container"; docker container start \$CONTAINER ; else false; fi

if [[ \$? == 0 ]] ; then docker container exec -it \$CONTAINER bash -i -c "sudo pacman -Sy --noconfirm --needed git" ; else false; fi
if [[ \$? == 0 ]] ; then docker container exec -it \$CONTAINER bash -i -c "git clone https://aur.archlinux.org/yay.git" ; else false; fi
if [[ \$? == 0 ]] ; then docker container exec -it \$CONTAINER bash -i -c "cd yay ; makepkg --noconfirm --syncdeps --rmdeps --install --clean"; else false; fi
if [[ \$? == 0 ]] ; then docker container exec -it \$CONTAINER bash -i -c "rm -rf yay" ; else false; fi
echo "sudo docker container exec -it \$CONTAINER bash -i" >> run.sh
EOF

chmod +x build_sudo_tmp.sh

if [[ -e run.sh ]]
    then
        rm run.sh
fi
touch run.sh
chmod +x run.sh

sudo ./build_sudo_tmp.sh

rm build_sudo_tmp.sh
