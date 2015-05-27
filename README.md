qubes-overlay
=============

A [Portage] (https://wiki.gentoo.org/wiki/Portage) overlay for
[Qubes] (https://qubes-os.org) (PV)HVM ebuilds.


Status
------

Inter-VM file copying, qubes-gui, qvm-run, qubes-desktop-run, and
init scripts work, even with grsecurity, pax, and selinux mcs/strict
fully enabled.

Note however that some of PaX's features don't currently work in
PVHVMs, and cannot ever work in fully PV domains.

All other functions are currently untested.

The kernel module ('u2mfn') ebuild requires USE=-sandbox. A static
kernel can be used by adding u2mfn/ to the kernel build manually.

To use Gentoo as a PV template, you must run
qubes-prepare-volatile-img.sh on root.img.


Progress
--------

Given that interest in a Qubes overlay among people with access to a web
search engine is 0, I'm not motivated to stage or push local changes.

In the case that anyone ever mentions this overlay, that might change.

(Perhaps).
