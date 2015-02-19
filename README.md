qubes-overlay
=============

A [Portage] (https://wiki.gentoo.org/wiki/Portage) overlay for
[Qubes] (https://qubes-os.org) (PV)HVM ebuilds.


Status
------

Inter-VM file copying works, even with grsecurity and pax fully
enabled.

All other functions are currently untested.

The kernel module ('u2mfn') ebuild requires USE=-sandbox. A static
kernel can be used by adding u2mfn/ to the kernel build manually.
