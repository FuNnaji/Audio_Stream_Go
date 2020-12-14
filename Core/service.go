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
	docErr := fetchAudioDocument(request.DocumentID, &document)
	if docErr != nil {
		fmt.Println(docErr)
		http.Error(w, docErr.Error(), http.StatusInternalServerError)
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
	//Put this part below into audio stream
	audioByte, audioErr := audioByte(request.DocumentID)
	if audioErr != nil {
		fmt.Println("Audio byte fetch error: ", audioErr)
		return
	}
	fmt.Println("File length: " + fmt.Sprintf("%v", len(audioByte)))
	encoder := json.NewEncoder(w)
	encoder.Encode(&audioByte)
}
