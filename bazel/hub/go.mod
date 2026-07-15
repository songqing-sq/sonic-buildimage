// Synthetic go.mod for the root shared go_deps hub.
//
// gazelle's go_deps only honors `replace` directives from the ROOT module's
// from_file (submodule replaces are ignored during shared-hub resolution). The
// sonic-mgmt-common / sonic-mgmt-framework / sonic-gnmi group needs these pins:
//   * glog  -> the ancient v0.0.0-20160126 that the mgmt-common glog patch
//     (module_override) applies against; sonic-gnmi's go.mod requires glog
//     v1.2.4, which would otherwise win via MVS and break the patch.
//   * gnmi  -> v0.0.0-20200617, the version mgmt-common builds against and the
//     one sonic-gnmi's own replace also pins.
//   * grpc  -> v1.64.1 (sonic-gnmi's own replace target). MVS otherwise resolves
//     grpc v1.71, whose authz package imports the split go-control-plane/envoy
//     module that none of the modules' go.mods provide (they pin
//     go-control-plane v0.12.0, where envoy is a subpackage). grpc 1.64.1's
//     authz works against v0.12.0.
//   * fsnotify -> v1.4.9. MVS resolves v1.7.0 (restructured: backend_inotify.go,
//     no inotify.go), but sonic-gnmi requires v1.4.9 and patches its
//     CloseWrite/MovedTo support onto v1.4.9's fsnotify.go + inotify.go.
// protobuf is intentionally NOT replaced here so the hub keeps the higher
// version MVS already resolved across the module group.
module sonic-buildimage/hub

go 1.24.4

require (
	github.com/fsnotify/fsnotify v1.4.9
	github.com/golang/glog v0.0.0-20160126235308-23def4e6c14b
	github.com/openconfig/gnmi v0.0.0-20200617225440-d2b4e6a45802
	google.golang.org/grpc v1.64.1
)

replace (
	github.com/fsnotify/fsnotify => github.com/fsnotify/fsnotify v1.4.9
	github.com/golang/glog => github.com/golang/glog v0.0.0-20160126235308-23def4e6c14b
	github.com/openconfig/gnmi => github.com/openconfig/gnmi v0.0.0-20200617225440-d2b4e6a45802
	google.golang.org/grpc => google.golang.org/grpc v1.64.1
)
