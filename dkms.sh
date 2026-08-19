#!/bin/bash

src_dir='/usr/src/snd_hda_macbookpro-0.2'
module_name='snd-hda-codec-cs8409'
dkms_name='snd_hda_macbookpro/0.2'
var_dkms_dir='/var/lib/dkms/snd_hda_macbookpro'
cur_dir=$(cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd)

while getopts :ru arg
do
    case "${arg}" in
        r) dkms_remove=true;;
        u) dkms_remove=true;;
    esac
done

if [[ $dkms_remove = true ]]; then
    dkms remove "$dkms_name" --all || true
    [[ -e $src_dir ]] && rm -f "$src_dir" && echo "removed $src_dir"
    exit 0
fi

pushd "$cur_dir" > /dev/null

# Older copies of this project and the AUR package used a different DKMS name/version.
for old in snd-hda-macbookpro/0.1 snd_hda_macbookpro/0.1; do
    if dkms status -m "${old%/*}" 2>/dev/null | grep -q .; then
        echo "Removing conflicting DKMS module $old"
        dkms remove "$old" --all || true
    fi
done

[[ -L /usr/src/snd-hda-macbookpro-0.1 ]] && rm -f /usr/src/snd-hda-macbookpro-0.1
[[ -L /usr/src/snd_hda_macbookpro-0.1 ]] && rm -f /usr/src/snd_hda_macbookpro-0.1
[[ -d /usr/src/snd-hda-macbookpro-0.1 ]] && rm -rf /usr/src/snd-hda-macbookpro-0.1
[[ -e /var/lib/dkms/snd-hda-macbookpro ]] && rm -rf /var/lib/dkms/snd-hda-macbookpro

ln -sfn "$cur_dir" "$src_dir"

installed=0
for build in /lib/modules/*/build; do
    [ -e "$build/Makefile" ] || continue
    kernel=$(basename "$(dirname "$build")")
    echo
    echo "DKMS install for kernel $kernel"
    dkms install -c dkms.conf --force -m snd_hda_macbookpro -v 0.2 -k "$kernel"
    installed=1
done

if [ "$installed" -eq 0 ]; then
    echo "No kernel build trees found under /lib/modules/*/build"
    echo "Install matching headers, for example:"
    echo "  sudo pacman -S linux-headers linux-lts-headers"
    exit 1
fi

popd > /dev/null
