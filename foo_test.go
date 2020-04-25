package main

import "testing"

func TestFoo(t *testing.T) {
	testFoo := foo()
	if testFoo < 0 || testFoo > 20 {
		t.Error("The value should more than 0 and less than 20!")
	}
}
