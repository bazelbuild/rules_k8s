package main

import (
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
	if _, err := r.resolveYAML(y); err != nil {
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
