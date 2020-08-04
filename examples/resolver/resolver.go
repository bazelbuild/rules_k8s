package main

/*
Example of a custom resolver

The job of the resolver is to perform just in time resolution of values known only at deploy time.
Inputs are a set of flags (see below) including a template file.
The fully resolved output must be printed to standard out.
*/

import (
	"flag"
	"fmt"
	"log"
	"strings"

	"io/ioutil"
)

// Flags that the resolver will be passed
var (
	stampInfoFile     = flag.String("stamp-info-file", "", "One or more Bazel stamp info files.")
	imgChroot         = flag.String("image_chroot", "", "The repository under which to chroot image references when publishing them.")
	templateFile      = flag.String("template", "", "The k8s YAML template file to resolve.")
	substitutionsFile = flag.String("substitutions", "", "A file with a list of substitutions that were made in the YAML template. Any stamp values that appear are stamped by the resolver.")
)

func readTemplate(templateFile string) string {
	content, err := ioutil.ReadFile(templateFile)
	if err != nil {
		log.Fatalf("unable to open template file %s: %v", templateFile, err)
	}
	return string(content)
}

func main() {
	flag.Parse()
	fmt.Print(strings.Replace(readTemplate(*templateFile), "PLACEHOLDER", "resolved", -1))
}
