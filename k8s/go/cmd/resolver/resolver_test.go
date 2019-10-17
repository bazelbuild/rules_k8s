package main

import (
	"bytes"
	"fmt"
	"testing"

	"github.com/google/go-cmp/cmp"
)

// TestYAMLWalk ensures the YAML walker in the resolver visits all strings in
// an arbitrary YAML teplate with nested maps & lists.
func TestYAMLWalk(t *testing.T) {
	y := []byte(`val1: val2
val3: val4
val5:
  val6: val7
val8:
  val9: val10
  val11:
    val12:
      val13:
      val14: val15
  val16:
    val17:
    - val18: val19
      val20: val21
      val22: val23
      val24:
      - val25: val26
`)
	got := make(map[string]bool)
	sr := func(r *resolver, s string) (string, error) {
		got[s] = true
		return s, nil
	}
	r := &resolver{
		strResolver: sr,
	}
	if _, err := r.resolveYAML(bytes.NewBuffer(y)); err != nil {
		t.Fatalf("Failed to resolve YAML: %v", err)
	}
	want := make(map[string]bool)
	for i := 1; i <= 26; i++ {
		want[fmt.Sprintf("val%d", i)] = true
	}

	if diff := cmp.Diff(want, got); diff != "" {
		t.Errorf("YAML walker did not visit all strings (-want +got):\n%s", diff)
	}
}

// TestYAMLStream ensures the YAML walker correctly processes a stream of
// YAML documents.
func TestYAMLStream(t *testing.T) {
	testCases := []struct {
		name string
		// yamlDocs is a string with one or more YAML documents.
		yamlDocs string
		// want is the list of strings the YAML walker should visit.
		want []string
		// wantDocs is the number of docs the resolver should have operated on.
		wantDocs int
	}{
		{
			name: "TwoLists",
			yamlDocs: `
- val1
- val2
---
- val3
- val4
`,
			want:     []string{"val1", "val2", "val3", "val4"},
			wantDocs: 2,
		},
		{
			name: "TwoMaps",
			yamlDocs: `
val1: val2
---
val3: val4
`,
			want:     []string{"val1", "val2", "val3", "val4"},
			wantDocs: 2,
		},
		{
			name: "ListAndMap",
			yamlDocs: `
- val1
- val2
---
val3: val4
`,
			want:     []string{"val1", "val2", "val3", "val4"},
			wantDocs: 2,
		},
		{
			name: "MapAndList",
			yamlDocs: `
val1: val2
---
- val3
- val4
`,
			want:     []string{"val1", "val2", "val3", "val4"},
			wantDocs: 2,
		},
		{
			name: "IntBoolStrListMap",
			yamlDocs: `
1
---
True
---
val1
---
- val2
- val3
---
val4: val5
`,
			want:     []string{"val1", "val2", "val3", "val4", "val5"},
			wantDocs: 5,
		},
	}
	for _, tc := range testCases {
		t.Run(tc.name, func(t *testing.T) {
			got := make(map[string]bool)
			sr := func(r *resolver, s string) (string, error) {
				got[s] = true
				return s, nil
			}
			r := &resolver{
				strResolver: sr,
			}
			if _, err := r.resolveYAML(bytes.NewBufferString(tc.yamlDocs)); err != nil {
				t.Fatalf("Failed to resolve YAML: %v", err)
			}
			want := make(map[string]bool)
			for _, w := range tc.want {
				want[w] = true
			}

			if diff := cmp.Diff(want, got); diff != "" {
				t.Errorf("YAML walker did not visit all strings (-want +got):\n%s", diff)
			}
			if r.numDocs != tc.wantDocs {
				t.Errorf("YAML walker did not visit all YAML documents, got %d, want %d.", r.numDocs, tc.wantDocs)
			}
		})
	}
}
