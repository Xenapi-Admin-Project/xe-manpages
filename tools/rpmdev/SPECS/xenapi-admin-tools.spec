Summary: Xenapi Admin Tools RPM
Name: xenapi-admin-tools
Version: 1.0
Release: 1
License: GPL
Group: Administrative Tools
Source: xenapi-admin-tools.tar.gz
Buildroot: /var/tmp/%{name}-buildroot

Requires: bash
Requires: xapi-xe
Provides: /root/bin/lsvms
Provides: /root/bin/dfsr
Provides: /root/bin/lssr
Provides: /root/bin/lshosts
Provides: /root/bin/lsnetworks
Provides: /root/bin/lsvdis
Provides: /root/bin/lstemplates
Provides: /root/bin/mktemplate
Provides: /root/bin/rmtemplate
Provides: /root/bin/lscores
Provides: /root/bin/library.sh


%description
Xenapi Admin Tools provides many commandline tools to make administering an xenapi cloud much easier. Tools list vms, storage repositories,
hosts, networks, virtual disks, templates and cpu cores. 
%prep
%setup -c -q

%install
cp -a ./ $RPM_BUILD_ROOT/

%clean
rm -rf $RPM_BUILD_ROOT

%post

%files
%defattr(-,root,root)
/root/bin/lsvms
/root/bin/dfsr
/root/bin/lssr
/root/bin/lshosts
/root/bin/lsnetworks
/root/bin/lsvdis
/root/bin/lstemplates
/root/bin/mktemplate
/root/bin/rmtemplate
/root/bin/lscores
/root/bin/library.sh
