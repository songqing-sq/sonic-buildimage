"""Source exposure for the ifupdown2 3.0.0-1 GitHub release tarball.

ifupdown2 is pure Python: the deb ships the ifupdown2/ package tree verbatim
under /usr/share/ifupdown2, so there is nothing to compile and no setup.py run
is needed (pybuild's only job here is copying files and writing egg-info).
"""

package(default_visibility = ["//visibility:public"])

# The whole Python package tree, laid into /usr/share/ifupdown2.
filegroup(
    name = "python_tree",
    srcs = glob(
        ["ifupdown2/**/*.py"],
        allow_empty = False,
    ),
)

# ifupdown2/sbin/start-networking is a shell script, installed executable.
exports_files(["ifupdown2/sbin/start-networking"])

# setup.py DATA_FILES + debian/ifupdown2.install.
exports_files([
    "etc/default/networking",
    "etc/network/ifupdown2/addons.conf",
    "etc/network/ifupdown2/ifupdown2.conf",
])

# Units. dh installs debian/<pkg>.networking.service as networking.service;
# ifup@.service is copied by debian/rules' override_dh_install.
exports_files([
    "debian/ifup@.service",
    "debian/ifupdown2.networking.service",
])
