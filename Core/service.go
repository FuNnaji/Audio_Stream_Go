package main

import (
	"encoding/json"
	"fmt"
	"net/http"
)

func audioStreamHandler(w http.ResponseWriter, r *http.Request) {
	request, err := decodeAudioStreamRequest(r)
	if err != nil {
		fmt.Println(err)
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}
	file, audioErr := audioStream(request.DocumentID)
	if audioErr != nil {
		fmt.Println(audioErr)
		http.Error(w, audioErr.Error(), http.StatusInternalServerError)
		return
	}
	fmt.Println("Audio Document: " + file.Document.details() + " and File length: " + fmt.Sprintf("%d", file.AudioBufferSize))
	encoder := json.NewEncoder(w)
	encoder.Encode(&file)
}
