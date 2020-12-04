package resolver

import (
	"flag"

	"github.com/bazelbuild/rules_docker/container/go/pkg/utils"
)

// Flags defines the flags that rules_k8s may pass to the resolver
type Flags struct {
	ImgChroot         string
	K8sTemplate       string
	SubstitutionsFile string
	AllowUnusedImages bool
	NoPush            bool
	StampInfoFile     utils.ArrayStringFlags
	ImgSpecs          utils.ArrayStringFlags
}

// Commandline flags
const (
	FlagImgChroot         = "image_chroot"
	FlagK8sTemplate       = "template"
	FlagSubstitutionsFile = "substitutions"
	FlagAllowUnusedImages = "allow_unused_images"
	FlagNoPush            = "no_push"
	FlagImgSpecs          = "image_spec"
	FlagStampInfoFile     = "stamp-info-file"
)

// RegisterFlags will register the resolvers flags with the provided FlagSet.
// It returns a struct that will contain the values once flags are parsed.
// The caller is responsible for parsing flags when ready.
func RegisterFlags(flagset *flag.FlagSet) *Flags {
	var flags Flags

	flagset.StringVar(&flags.ImgChroot, FlagImgChroot, "", "The repository under which to chroot image references when publishing them.")
	flagset.StringVar(&flags.K8sTemplate, FlagK8sTemplate, "", "The k8s YAML template file to resolve.")
	flagset.StringVar(&flags.SubstitutionsFile, FlagSubstitutionsFile, "", "A file with a list of substitutions that were made in the YAML template. Any stamp values that appear are stamped by the resolver.")
	flagset.BoolVar(&flags.AllowUnusedImages, FlagAllowUnusedImages, false, "Allow images that don't appear in the JSON. This is useful when generating multiple SKUs of a k8s_object, only some of which use a particular image.")
	flagset.BoolVar(&flags.NoPush, FlagNoPush, false, "Don't push images after resolving digests.")
	flagset.Var(&flags.ImgSpecs, FlagImgSpecs, "Associative lists of the constitutent elements of a docker image.")
	flagset.Var(&flags.StampInfoFile, FlagStampInfoFile, "One or more Bazel stamp info files.")

	return &flags
}
