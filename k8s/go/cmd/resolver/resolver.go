// Copyright 2017 The Bazel Authors. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
package main

import (
	"flag"
	"fmt"
	"io/ioutil"
	"log"
	"path"
	"reflect"
	"strings"

	"gopkg.in/yaml.v2"

	"github.com/bazelbuild/rules_docker/container/go/pkg/compat"
	"github.com/bazelbuild/rules_docker/container/go/pkg/utils"
	"github.com/google/go-containerregistry/pkg/authn"
	"github.com/google/go-containerregistry/pkg/name"
	"github.com/google/go-containerregistry/pkg/v1/remote"
)

var (
	imgChroot         = flag.String("image_chroot", "", "The repository under which to chroot image references when publishing them.")
	k8sTemplate       = flag.String("template", "", "The k8s YAML template file to resolve.")
	allowUnusedImages = flag.Bool("allow_unused_images", false, "Allow images that don't appear in the JSON. This is useful when generating multiple SKUs of a k8s_object, only some of which use a particular image.")
	stampInfoFile     utils.ArrayStringFlags
	imgSpecs          utils.ArrayStringFlags
)

// imageSpec describes the differents parts of an image generated by
// rules_docker.
type imageSpec struct {
	// name is the name of the image.
	name string
	// imgTarball is the image in the `docker save` tarball format.
	imgTarball string
	// imgConfig if the config JSON file of the image.
	imgConfig string
	// digests is a list of files with the sha256 digests of the compressed
	// layers.
	digests []string
	// diffIDs is a list of files with the sha256 digests of the uncompressed
	// layers.
	diffIDs []string
	// compressedLayers are the paths to the compressed layer tarballs.
	compressedLayers []string
	// uncompressedLayers are the paths to the uncompressed layer tarballs.
	uncomressedLayers []string
}

// layers returns a list of strings that can be passed to the image reader in
// the compatiblity package of rules_docker to read the layers of an image in
// the format "va11,val2,val3,val4" where:
// val1 is the compressed layer tarball.
// val2 is the uncompressed layer tarball.
// val3 is the digest file.
// val4 is the diffID file.
func (s *imageSpec) layers() ([]string, error) {
	result := []string{}
	if len(s.digests) != len(s.diffIDs) || len(s.diffIDs) != len(s.compressedLayers) || len(s.compressedLayers) != len(s.uncomressedLayers) {
		return nil, fmt.Errorf("digest, diffID, compressed blobs & uncompressed blobs had unequal lengths for image %s, got %d, %d, %d, %d, want all of the lengths to be equal", s.name, len(s.digests), len(s.diffIDs), len(s.compressedLayers), len(s.uncomressedLayers))
	}
	for i, digest := range s.digests {
		diffID := s.diffIDs[i]
		compressedLayer := s.compressedLayers[i]
		uncompressedLayer := s.uncomressedLayers[i]
		result = append(result, fmt.Sprintf("%s,%s,%s,%s", compressedLayer, uncompressedLayer, digest, diffID))
	}
	return result, nil
}

// parseImageSpec parses the differents parts of a single docker image specified
// as string in the format "key1=val1;key2=val2" where the expected keys are:
// 1. "name": Name of the image.
// 2. "tarball": docker save tarball of the image.
// 3. "config": JSON config file of the image.
// 4. "diff_id": Files with sha256 digest of uncompressed layers.
// 5. "digest": Files with sha256 digest of compressed layers.
// 6. "compressed_layer": Path to compressed layer tarballs.
// 7. "uncompressed_layer": Path to uncompressed layer tarballs.
func parseImageSpec(spec string) (imageSpec, error) {
	result := imageSpec{}
	splitSpec := strings.Split(spec, ";")
	for _, s := range splitSpec {
		splitFields := strings.SplitN(s, "=", 2)
		if len(splitFields) != 2 {
			return imageSpec{}, fmt.Errorf("image spec item %q split by '=' into unexpected fields, got %d, want 2", s, len(splitFields))
		}
		switch splitFields[0] {
		case "name":
			result.name = splitFields[1]
		case "tarball":
			result.imgTarball = splitFields[1]
		case "config":
			result.imgConfig = splitFields[1]
		case "diff_id":
			result.diffIDs = strings.Split(splitFields[1], ",")
		case "digest":
			result.digests = strings.Split(splitFields[1], ",")
		case "compressed_layer":
			result.compressedLayers = strings.Split(splitFields[1], ",")
		case "uncompressed_layer":
			result.uncomressedLayers = strings.Split(splitFields[1], ",")
		default:
			return imageSpec{}, fmt.Errorf("unknown image spec field %q", splitFields[0])
		}
	}
	return result, nil
}

// publishSingle publishes a docker image with the given spec to the remote
// registry indicated in the image name. The image name is stamped with the
// given stamper.
// The stamped image name is returned referenced by its sha256 digest.
func publishSingle(spec imageSpec, stamper *compat.Stamper) (string, error) {
	layers, err := spec.layers()
	if err != nil {
		return "", fmt.Errorf("unable to convert the layer parts in image spec for %s into a single comma separated argument: %v", spec.name, err)
	}

	imgParts, err := compat.ImagePartsFromArgs(spec.imgConfig, "", spec.imgTarball, layers)
	if err != nil {
		return "", fmt.Errorf("unable to determine parts of the image from the specified arguments: %v", err)
	}
	img, err := compat.ReadImage(imgParts)
	if err != nil {
		return "", fmt.Errorf("error reading image: %v", err)
	}
	stampedName := stamper.Stamp(spec.name)

	var ref name.Reference
	if *imgChroot != "" {
		n := path.Join(*imgChroot, stampedName)
		t, err := name.NewTag(n, name.WeakValidation)
		if err != nil {
			return "", fmt.Errorf("unable to create a docker tag from stamped name %q: %v", n, err)
		}
		ref = t
	} else {
		t, err := name.NewTag(stampedName, name.WeakValidation)
		if err != nil {
			return "", fmt.Errorf("unable to create a docker tag from stamped name %q: %v", stampedName, err)
		}
		ref = t
	}
	auth, err := authn.DefaultKeychain.Resolve(ref.Context())
	if err != nil {
		return "", fmt.Errorf("unable to get authenticator for image %v", ref.Name())
	}

	if err := remote.Write(ref, img, remote.WithAuth(auth)); err != nil {
		return "", fmt.Errorf("unable to push image %v: %v", ref.Name(), err)
	}

	d, err := img.Digest()
	if err != nil {
		return "", fmt.Errorf("unable to get digest of image %v", ref.Name())
	}

	return fmt.Sprintf("%s/%s@%v", ref.Context().RegistryStr(), ref.Context().RepositoryStr(), d), nil
}

// publish publishes the image with the given spec. It returns:
// 1. A map from the unstamped & tagged image name to the stamped image name
//    referenced by its sha256 digest.
// 2. A set of unstamped & tagged image names that were pushed to the registry.
func publish(spec []imageSpec, stamper *compat.Stamper) (map[string]string, map[string]bool, error) {
	overrides := make(map[string]string)
	unseen := make(map[string]bool)
	for _, s := range spec {
		digestRef, err := publishSingle(s, stamper)
		if err != nil {
			return nil, nil, fmt.Errorf("unable to publish image %s", s.name)
		}
		overrides[s.name] = digestRef
		unseen[s.name] = true
	}
	return overrides, unseen, nil
}

type resolver struct {
	resolvedImages map[string]string
	unseen         map[string]bool
}

func (r *resolver) resolveItem(i interface{}) (interface{}, error) {
	if s, ok := i.(string); ok {
		log.Printf("Resolve item: %q", s)
		return s, nil
	}
	if l, ok := i.([]interface{}); ok {
		return r.resolveList(l)
	}
	if m, ok := i.(map[interface{}]interface{}); ok {
		return r.resolveMap(m)
	}
	log.Printf("Fallthrough resolving %v of type %v.", i, reflect.TypeOf(i))
	return i, nil
}

func (r *resolver) resolveList(l []interface{}) ([]interface{}, error) {
	result := []interface{}{}
	for _, i := range l {
		o, err := r.resolveItem(i)
		if err != nil {
			return nil, err
		}
		result = append(result, o)
	}
	return result, nil
}

func (r *resolver) resolveMap(m map[interface{}]interface{}) (map[interface{}]interface{}, error) {
	result := make(map[interface{}]interface{})
	for k, v := range m {
		rk, err := r.resolveItem(k)
		if err != nil {
			return nil, err
		}
		rv, err := r.resolveItem(v)
		if err != nil {
			return nil, err
		}
		result[rk] = rv
	}
	return result, nil
}

func (r *resolver) walkYAML(b []byte) error {
	var l []interface{}
	lErr := yaml.Unmarshal(b, &l)
	if lErr == nil {
		r.resolveItem(l)
		return nil
	}
	var m map[interface{}]interface{}
	mErr := yaml.Unmarshal(b, &m)
	if mErr == nil {
		r.resolveMap(m)
		return nil
	}

	return fmt.Errorf("unable to parse given blob as a YAML list or map: %v %v", lErr, mErr)
}

func resolveTemplate(templateFile string, resolvedImages map[string]string, unseen map[string]bool) error {
	t, err := ioutil.ReadFile(templateFile)
	if err != nil {
		return fmt.Errorf("unable to open template file %q: %v", templateFile, err)
	}

	r := resolver{
		resolvedImages: resolvedImages,
		unseen:         unseen,
	}
	if r.walkYAML(t); err != nil {
		return fmt.Errorf("unable to resolve YAML template %q: %v", templateFile, err)
	}
	return nil
}

func main() {
	flag.Var(&imgSpecs, "image_spec", "Associative lists of the constitutent elements of a docker image.")
	flag.Var(&stampInfoFile, "stamp-info-file", "One or more Bazel stamp info files.")
	flag.Parse()

	log.Println("Template", *k8sTemplate)

	stamper, err := compat.NewStamper(stampInfoFile)
	if err != nil {
		log.Fatalf("Failed to initialize the stamper: %v", err)
	}

	specs := []imageSpec{}
	for _, s := range imgSpecs {
		spec, err := parseImageSpec(s)
		if err != nil {
			log.Fatalf("Unable to parse image spec %q: %v", s, err)
		}
		specs = append(specs, spec)
	}
	resolvedImages, unseen, err := publish(specs, stamper)
	if err != nil {
		log.Fatalf("Unable to publish images: %v", err)
	}
	if err := resolveTemplate(*k8sTemplate, resolvedImages, unseen); err != nil {
		log.Fatalf("Unable to resolve template file %q: %v", *k8sTemplate, err)
	}
	if len(unseen) > 0 && !*allowUnusedImages {
		log.Printf("The following images given as --image_spec were not found in the template:")
		for i := range unseen {
			log.Printf("%s", i)
		}
		log.Fatalf("--allow_unused_images can be specified to ignore this error.")
	}
}
