// Command app is the entry point.
package main

import "fmt"

// version is injected at build time with -ldflags -X main.version.
var version = "dev"

func main() {
	fmt.Printf("%s (%s)\n", greet("world"), version)
}

func greet(name string) string {
	return "hello, " + name
}
