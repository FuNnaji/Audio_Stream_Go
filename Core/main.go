package main

import (
	"fmt"
	"log"
	"net/http"
)

func main() {
	port := 8080
	fmt.Println("Audio Stream Go >> starting...")

	http.HandleFunc("/", audioStreamHandler)
	fmt.Printf("Audio Stream Go >> serving on port %v\n", port)
	log.Fatal(http.ListenAndServe(fmt.Sprintf(":%v", port), nil))

	fmt.Println("Audio Stream Go >> exited...")
}
