package main

import (
	"encoding/json"
	"fmt"
	"net/http"
)

func audioDocumentHandler(w http.ResponseWriter, r *http.Request) {
	request, err := decodeAudioStreamRequest(r)
	if err != nil {
		fmt.Println(err)
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}
	var document audioStreamDocument
	documentErr := fetchAudioDocument(request.DocumentID, &document)
	if documentErr != nil {
		fmt.Println(documentErr)
		http.Error(w, documentErr.Error(), http.StatusInternalServerError)
		return
	}
	fmt.Println("Audio Document: " + document.details())
	encoder := json.NewEncoder(w)
	encoder.Encode(&document)
}

func audioStreamHandler(w http.ResponseWriter, r *http.Request) {
	request, err := decodeAudioStreamRequest(r)
	if err != nil {
		fmt.Println(err)
		http.Error(w, "Bad request", http.StatusBadRequest)
		return
	}
	file, audioErr := createAudioBuffer(request.DocumentID)
	if audioErr != nil {
		fmt.Println(audioErr)
		http.Error(w, audioErr.Error(), http.StatusInternalServerError)
		return
	}
	fmt.Println("Audio Document: " + file.Document.details() + " and File length: " + fmt.Sprintf("%d", file.AudioBufferSize))
	encoder := json.NewEncoder(w)
	encoder.Encode(&file)
}
